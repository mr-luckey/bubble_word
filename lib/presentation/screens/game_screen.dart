import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/audio_service.dart';
import '../../core/utils/board_layout.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/bubble_ball_widget.dart';
import '../../core/widgets/glow_platform.dart';
import '../../core/widgets/hint_connector_painter.dart';
import '../../core/widgets/game_header_bar.dart';
import '../../core/widgets/nebula_background.dart';
import '../../core/widgets/target_words_panel.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/level.dart';
import '../bloc/ad/ad_bloc.dart';
import '../bloc/booster/booster_bloc.dart';
import '../bloc/economy/economy_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/level/level_bloc.dart';
import '../bloc/settings/settings_bloc.dart';
import 'level_complete_overlay.dart';
import 'level_fail_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelId});

  final int levelId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late LevelBloc _levelBloc;
  late GameBloc _gameBloc;
  late BoosterBloc _boosterBloc;
  final GlobalKey _playfieldKey = GlobalKey();
  double _boardWidth = 360;
  double _boardHeight = 480;
  bool _levelStarted = false;
  int _layoutBallCount = 0;
  bool _dropComplete = false;
  Offset _dragTouchOffset = Offset.zero;
  AnimationController? _dropController;
  _PendingAdAction? _pendingAd;

  @override
  void initState() {
    super.initState();
    _levelBloc = getIt<LevelBloc>()..add(LoadLevel(widget.levelId));
    _gameBloc = getIt<GameBloc>();
    _boosterBloc = BoosterBloc(getIt<EconomyBloc>(), _gameBloc);
    getIt<EconomyBloc>().add(const ResetLevelBoosterFlags());
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelId != widget.levelId) {
      _levelStarted = false;
      _layoutBallCount = 0;
      _dropComplete = false;
    }
  }

  void _startLevelIfReady(Level level) {
    if (_levelStarted) return;
    if (_boardWidth <= 0 || _boardHeight <= 0) return;
    _levelStarted = true;
    _dropComplete = false;
    _gameBloc.add(StartLevel(level, boardWidth: _boardWidth, boardHeight: _boardHeight));
    _startDropAnimation();
  }

  void _startDropAnimation() {
    _dropController?.dispose();
    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _dropController!.forward().whenComplete(() {
      if (mounted) setState(() => _dropComplete = true);
    });
  }

  double _ballDisplayY(Ball ball, double minY, double maxY) {
    if (_dropComplete || ball.isDragging || _dropController == null) {
      return ball.y;
    }
    final range = maxY - minY;
    // Bottom row (maxY) lands first; top row lands last.
    final stagger = range > 0 ? ((maxY - ball.y) / range) * 0.55 : 0.0;
    final progress = _dropController!.value;
    final t = Curves.easeInCubic.transform(
      ((progress - stagger) / (1.0 - stagger)).clamp(0.0, 1.0),
    );
    final startY = -80.0;
    return ui.lerpDouble(startY, ball.y, t) ?? ball.y;
  }

  void _onPlayfieldSized(double width, double height, Level level) {
    final sizeChanged =
        (width - _boardWidth).abs() > 2 || (height - _boardHeight).abs() > 2;
    _boardWidth = width;
    _boardHeight = height;

    if (!_levelStarted) {
      _startLevelIfReady(level);
      return;
    }

    if (sizeChanged) {
      _gameBloc.add(RelayoutBoard(boardWidth: width, boardHeight: height));
      _dropComplete = false;
      _startDropAnimation();
    }
  }

  void _handleMergeFeedback(BuildContext context, GamePlaying state) {
    final feedback = state.gameState.mergeFeedback;
    if (feedback == MergeFeedback.none) return;

    final audio = getIt<AudioService>();
    final settings = context.read<SettingsBloc>().state;
    audio.soundEnabled = settings.sound;
    audio.hapticsEnabled = settings.haptics;

    if (feedback == MergeFeedback.correct) {
      audio.playMerge();
      if (settings.haptics) HapticFeedback.lightImpact();
    } else {
      audio.playWrong();
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _gameBloc.add(const ClearMergeFeedback());
    });
  }

  void _showSnackBar(String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleHint(BuildContext context) {
    final economy = context.read<EconomyBloc>().state.economy;
    final inv = economy.boosters;

    if (!inv.freeHintUsedThisLevel) {
      _boosterBloc.add(const UseHint());
      return;
    }

    if (inv.hint > 0) {
      if (!economy.noAdsPurchased) {
        _pendingAd = _PendingAdAction.hintInterstitial;
        context.read<AdBloc>().add(const ShowInterstitialAd());
      } else {
        _boosterBloc.add(const UseHint());
      }
      return;
    }

    if (!economy.noAdsPurchased) {
      _pendingAd = _PendingAdAction.hintRewarded;
      context.read<AdBloc>().add(const ShowRewardedAd());
    } else {
      _showSnackBar('No hints left');
    }
  }

  void _onAdComplete(BuildContext context, AdComplete state) {
    final pending = _pendingAd;
    if (pending == null) return;
    _pendingAd = null;

    switch (pending) {
      case _PendingAdAction.hintInterstitial:
        _boosterBloc.add(const UseHint());
      case _PendingAdAction.hintRewarded:
        if (state.rewarded) {
          final inv = context.read<EconomyBloc>().state.economy.boosters;
          context.read<EconomyBloc>().add(
                UpdateBoosters(inv.copyWith(hint: inv.hint + 1)),
              );
          _boosterBloc.add(const UseHint());
        } else {
          _showSnackBar('Watch the full ad to get a hint');
        }
      case _PendingAdAction.continueMoves:
        if (state.rewarded) {
          _gameBloc.add(const AddExtraMoves());
        } else {
          _showSnackBar('Watch the full ad for +5 moves');
        }
    }
  }

  @override
  void dispose() {
    _dropController?.dispose();
    _levelBloc.close();
    _gameBloc.close();
    _boosterBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _levelBloc),
        BlocProvider.value(value: _gameBloc),
        BlocProvider.value(value: _boosterBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<LevelBloc, LevelState>(
            listener: (context, state) {
              if (state is LevelLoaded) {
                _levelStarted = false;
                _dropComplete = false;
              }
            },
          ),
          BlocListener<BoosterBloc, BoosterBlocState>(
            listener: (context, state) {
              if (state.message != null) {
                _showSnackBar(state.message!);
              }
            },
          ),
          BlocListener<GameBloc, GameBlocState>(
            listenWhen: (prev, curr) =>
                curr is GamePlaying &&
                prev is GamePlaying &&
                prev.gameState.mergeFeedback != curr.gameState.mergeFeedback,
            listener: (context, state) {
              if (state is GamePlaying) _handleMergeFeedback(context, state);
            },
          ),
          BlocListener<AdBloc, AdBlocState>(
            listener: (context, state) {
              if (state is AdComplete) {
                _onAdComplete(context, state);
              } else if (state is AdError) {
                _pendingAd = null;
                _showSnackBar('Ad unavailable. Try again.');
              }
            },
          ),
          BlocListener<GameBloc, GameBlocState>(
            listener: (context, state) {
              if (state is GameWon) {
                getIt<AudioService>().playWin();
                final economy = context.read<EconomyBloc>();
                economy.add(EarnCoins(state.coinsEarned));
                economy.add(RecordLevelStars(
                  levelId: state.gameState.level.id,
                  stars: state.stars,
                ));
                economy.add(const IncrementLevelsCompleted());
                final econ = economy.state.economy;
                if (!econ.noAdsPurchased && econ.levelsCompletedSinceAd >= 3) {
                  context.read<AdBloc>().add(const ShowInterstitialAd());
                  economy.add(const ResetLevelsCompletedAd());
                }
              }
            },
          ),
        ],
        child: NebulaBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
            child: BlocBuilder<LevelBloc, LevelState>(
              builder: (context, levelState) {
                if (levelState is LevelLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (levelState is LevelError) {
                  return Center(child: Text(levelState.message));
                }
                return BlocBuilder<GameBloc, GameBlocState>(
                  builder: (context, gameState) {
                    if (levelState is! LevelLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (gameState is GameWon) {
                      return Column(
                        children: [
                          Expanded(
                            child: LevelCompleteOverlay(
                              gameState: gameState,
                              onNext: () {
                                final economy = getIt<EconomyBloc>();
                                if (economy.state.economy.lives <= 0) {
                                  context.go('/home');
                                  return;
                                }
                                economy.add(const SpendLife());
                                economy.add(const ResetLevelBoosterFlags());
                                final next = widget.levelId + 1;
                                if (next <= 1000) {
                                  context.go('/game/$next');
                                } else {
                                  context.go('/home');
                                }
                              },
                              onHome: () => context.go('/home'),
                            ),
                          ),
                          const BannerAdWidget(),
                        ],
                      );
                    }
                    if (gameState is GameFailed) {
                      return Column(
                        children: [
                          Expanded(
                            child: LevelFailOverlay(
                              gameState: gameState,
                              onRetry: () {
                                _levelStarted = false;
                                _dropComplete = false;
                                _gameBloc.add(StartLevel(
                                  gameState.gameState.level,
                                  boardWidth: _boardWidth,
                                  boardHeight: _boardHeight,
                                ));
                                _startDropAnimation();
                              },
                              onWatchAd: () {
                                _pendingAd = _PendingAdAction.continueMoves;
                                context.read<AdBloc>().add(const ShowRewardedAd());
                              },
                              onSpendCoins: () {
                                context.read<EconomyBloc>().add(const SpendCoins(100));
                                _gameBloc.add(const AddExtraMoves());
                              },
                              onHome: () => context.go('/home'),
                            ),
                          ),
                          const BannerAdWidget(),
                        ],
                      );
                    }
                    if (gameState is GamePlaying) {
                      return _buildGameplay(context, gameState, levelState);
                    }
                    return _buildGameplayShell(context, levelState);
                  },
                );
              },
            ),
          ),
        ),
      ),
    ),
    );
  }

  double _ballRadius(Ball ball) {
    return BoardLayout.radiusFor(
      ball,
      screenWidth: _boardWidth,
      boardWidth: _boardWidth,
      layoutBallCount: _layoutBallCount,
      boardHeight: _boardHeight,
    );
  }

  double _ballSize(Ball ball) {
    return AppDimensions.visualBallSize(_ballRadius(ball));
  }

  List<Widget> _buildBoardBallWidgets(
    List<Ball> onBoard,
    String? snapBallId,
  ) {
    final maxY = onBoard.fold(0.0, (m, b) => math.max(m, b.y));
    final minY = onBoard.fold(double.infinity, (m, b) => math.min(m, b.y));
    final widgets = <Widget>[];
    for (var i = 0; i < onBoard.length; i++) {
      final ball = onBoard[i];
      final displayY = _ballDisplayY(ball, minY, maxY);
      final size = _ballSize(ball);
      widgets.add(
        Positioned(
          left: ball.x - size / 2,
          top: displayY - size / 2,
            child: BubbleBallWidget(
              ball: ball,
              radius: _ballRadius(ball),
              enableIdleFloat: _dropComplete,
              mergeSnapping: snapBallId == ball.id,
            onPanStart: (d) {
              final box =
                  _playfieldKey.currentContext?.findRenderObject() as RenderBox?;
              if (box != null) {
                final local = box.globalToLocal(d.globalPosition);
                _dragTouchOffset = Offset(
                  local.dx - ball.x,
                  local.dy - displayY,
                );
              }
              _gameBloc.add(DragBallStart(ball.id));
            },
            onPanUpdate: (d) {
              final box =
                  _playfieldKey.currentContext?.findRenderObject() as RenderBox?;
              if (box != null) {
                final local = box.globalToLocal(d.globalPosition);
                _gameBloc.add(DragBallUpdate(
                  x: local.dx - _dragTouchOffset.dx,
                  y: local.dy - _dragTouchOffset.dy,
                ));
              }
            },
            onPanEnd: (_) {
              _dragTouchOffset = Offset.zero;
              _gameBloc.add(const DragBallEnd());
            },
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildGameplayShell(BuildContext context, LevelLoaded levelState) {
    return Column(
      children: [
        BlocBuilder<EconomyBloc, EconomyBlocState>(
          builder: (context, econState) => GameHeaderBar(
            levelId: levelState.level.id,
            wordsComplete: 0,
            wordsTotal: levelState.level.wordCount,
            onBack: () => context.go('/home'),
            hintCount: econState.economy.boosters.hint,
            onHint: () => _handleHint(context),
          ),
        ),
        TargetWordsPanel(
          level: levelState.level,
          completedWordIds: const [],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _onPlayfieldSized(
                    constraints.maxWidth,
                    constraints.maxHeight,
                    levelState.level,
                  );
                }
              });
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }

  Widget _buildGameplay(BuildContext context, GamePlaying gameState, LevelLoaded levelState) {
    final gs = gameState.gameState;
    if (_layoutBallCount == 0) {
      _layoutBallCount = gs.boardBalls.where((b) => b.isOnBoard).length;
    }
    final wrongFlash = gs.mergeFeedback == MergeFeedback.wrong;

    return Column(
      children: [
        BlocBuilder<EconomyBloc, EconomyBlocState>(
          builder: (context, econState) => GameHeaderBar(
            levelId: gs.level.id,
            wordsComplete: gs.completedWordIds.length,
            wordsTotal: gs.level.wordCount,
            onBack: () => context.go('/home'),
            hintCount: econState.economy.boosters.hint,
            onHint: () => _handleHint(context),
          ),
        ),
        TargetWordsPanel(
          level: gs.level,
          completedWordIds: gs.completedWordIds,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _onPlayfieldSized(
                    constraints.maxWidth,
                    constraints.maxHeight,
                    levelState.level,
                  );
                }
              });

              Ball? hintA;
                  Ball? hintB;
                  if (gs.hintBallIds.length >= 2) {
                    hintA = gs.boardBalls
                        .where((b) => b.id == gs.hintBallIds[0])
                        .firstOrNull;
                    hintB = gs.boardBalls
                        .where((b) => b.id == gs.hintBallIds[1])
                        .firstOrNull;
                  }

                  final onBoard = gs.boardBalls.where((b) => b.isOnBoard).toList()
                    ..sort((a, b) {
                      if (a.isDragging) return 1;
                      if (b.isDragging) return -1;
                      return 0;
                    });

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: wrongFlash
                        ? AppColors.accentRed.withValues(alpha: 0.08)
                        : Colors.transparent,
                    child: Stack(
                      key: _playfieldKey,
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 36,
                          child: GlowPlatform(),
                        ),
                        if (hintA != null && hintB != null)
                          CustomPaint(
                            size: Size(_boardWidth, _boardHeight),
                            painter: HintConnectorPainter(
                              ballA: hintA,
                              ballB: hintB,
                            ),
                          ),
                        ..._buildBoardBallWidgets(onBoard, gs.snapBallId),
                      ],
                    ),
                  );
                },
              ),
            ),
        const BannerAdWidget(),
      ],
    );
  }
}

enum _PendingAdAction {
  hintInterstitial,
  hintRewarded,
  continueMoves,
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
