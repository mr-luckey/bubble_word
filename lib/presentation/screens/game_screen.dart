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
import '../../core/widgets/bubble_ball_widget.dart';
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

class _GameScreenState extends State<GameScreen> {
  late LevelBloc _levelBloc;
  late GameBloc _gameBloc;
  late BoosterBloc _boosterBloc;
  final GlobalKey _playfieldKey = GlobalKey();
  double _boardWidth = 360;
  double _boardHeight = 480;
  bool _levelStarted = false;
  Offset _dragTouchOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _levelBloc = getIt<LevelBloc>()..add(LoadLevel(widget.levelId));
    _gameBloc = getIt<GameBloc>();
    _boosterBloc = BoosterBloc(getIt<EconomyBloc>(), _gameBloc);
    getIt<EconomyBloc>().add(const ResetLevelBoosterFlags());
  }

  void _startLevelIfReady(Level level) {
    if (_levelStarted) return;
    if (_boardWidth <= 0 || _boardHeight <= 0) return;
    _levelStarted = true;
    _gameBloc.add(StartLevel(level, boardWidth: _boardWidth, boardHeight: _boardHeight));
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

  @override
  void dispose() {
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
                _startLevelIfReady(state.level);
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
                    if (gameState is GameWon) {
                      return LevelCompleteOverlay(
                        gameState: gameState,
                        onNext: () {
                          final next = widget.levelId + 1;
                          getIt<EconomyBloc>().add(const ResetLevelBoosterFlags());
                          if (next <= 1000) {
                            context.go('/game/$next');
                          } else {
                            context.go('/home');
                          }
                        },
                        onHome: () => context.go('/home'),
                      );
                    }
                    if (gameState is GameFailed) {
                      return LevelFailOverlay(
                        gameState: gameState,
                        onRetry: () {
                          _levelStarted = false;
                          _gameBloc.add(StartLevel(
                            gameState.gameState.level,
                            boardWidth: _boardWidth,
                            boardHeight: _boardHeight,
                          ));
                        },
                        onWatchAd: () {
                          context.read<AdBloc>().add(const ShowRewardedAd());
                          _gameBloc.add(const AddExtraMoves());
                        },
                        onSpendCoins: () {
                          context.read<EconomyBloc>().add(const SpendCoins(100));
                          _gameBloc.add(const AddExtraMoves());
                        },
                        onHome: () {
                          context.read<EconomyBloc>().add(const SpendLife());
                          context.go('/home');
                        },
                      );
                    }
                    if (gameState is GamePlaying) {
                      return _buildGameplay(context, gameState, levelState as LevelLoaded);
                    }
                    return const Center(child: CircularProgressIndicator());
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

  double _ballRadius(Ball ball, int ballCount) {
    return BoardLayout.radiusFor(
      ball,
      screenWidth: _boardWidth,
      ballCount: ballCount,
      boardHeight: _boardHeight,
    );
  }

  double _ballSize(Ball ball, int ballCount) {
    return AppDimensions.visualBallSize(_ballRadius(ball, ballCount));
  }

  Widget _buildGameplay(BuildContext context, GamePlaying gameState, LevelLoaded levelState) {
    final gs = gameState.gameState;
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
            onHint: () => context.read<BoosterBloc>().add(const UseHint()),
          ),
        ),
        TargetWordsPanel(
          level: gs.level,
          completedWordIds: gs.completedWordIds,
        ),
        Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _boardWidth = constraints.maxWidth;
                  _boardHeight = constraints.maxHeight;
                  if (!_levelStarted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _startLevelIfReady(levelState.level);
                    });
                  }

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

                  final onBoard = gs.boardBalls.where((b) => b.isOnBoard).toList();
                  final onBoardCount = onBoard.length;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: wrongFlash
                        ? AppColors.accentRed.withValues(alpha: 0.08)
                        : Colors.transparent,
                    child: Stack(
                      key: _playfieldKey,
                      clipBehavior: Clip.none,
                      children: [
                        if (hintA != null && hintB != null)
                          CustomPaint(
                            size: Size(_boardWidth, _boardHeight),
                            painter: HintConnectorPainter(
                              ballA: hintA,
                              ballB: hintB,
                            ),
                          ),
                        for (final ball in [
                          ...onBoard,
                        ]..sort((a, b) {
                            if (a.isDragging) return 1;
                            if (b.isDragging) return -1;
                            return 0;
                          }))
                          Positioned(
                            left: ball.x - _ballSize(ball, onBoardCount) / 2,
                            top: ball.y - _ballSize(ball, onBoardCount) / 2,
                            child: BubbleBallWidget(
                              ball: ball,
                              radius: _ballRadius(ball, onBoardCount),
                              mergeSnapping: gs.snapBallId == ball.id,
                              onPanStart: (d) {
                                final box = _playfieldKey.currentContext
                                    ?.findRenderObject() as RenderBox?;
                                if (box != null) {
                                  final local =
                                      box.globalToLocal(d.globalPosition);
                                  _dragTouchOffset = Offset(
                                    local.dx - ball.x,
                                    local.dy - ball.y,
                                  );
                                }
                                _gameBloc.add(DragBallStart(ball.id));
                              },
                              onPanUpdate: (d) {
                                final box = _playfieldKey.currentContext
                                    ?.findRenderObject() as RenderBox?;
                                if (box != null) {
                                  final local =
                                      box.globalToLocal(d.globalPosition);
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
                      ],
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
