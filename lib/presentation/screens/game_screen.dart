import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/ads_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/game_constants.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/services/analytics_service.dart';
import '../../core/utils/audio_service.dart';
import '../../core/utils/board_layout.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/bubble_ball_widget.dart';
import '../../core/widgets/guide_hand_overlay.dart';
import '../../core/widgets/hint_connector_painter.dart';
import '../../core/widgets/game_header_bar.dart';
import '../../core/widgets/merge_blast_effect.dart';
import '../../core/widgets/game_park_background.dart';
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
  const GameScreen({
    super.key,
    required this.levelId,
    this.isDailyChallenge = false,
  });

  final int levelId;
  final bool isDailyChallenge;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late LevelBloc _levelBloc;
  late GameBloc _gameBloc;
  late BoosterBloc _boosterBloc;
  late AnimationController _dropController;
  final GlobalKey _playfieldKey = GlobalKey();
  double _boardWidth = 360;
  double _boardHeight = 480;
  bool _levelStarted = false;
  int _layoutBallCount = 0;
  Offset _dragTouchOffset = Offset.zero;
  int? _activePointer;
  String? _pointerDragBallId;
  _PendingAdAction? _pendingAd;
  Timer? _levelTimer;
  bool _lifeSpentForFail = false;
  bool _dropAnimationStarted = false;
  final List<_MergeBlastInstance> _mergeBlasts = [];
  int _nextBlastId = 0;

  @override
  void initState() {
    super.initState();
    _levelBloc = getIt<LevelBloc>()..add(LoadLevel(widget.levelId));
    _gameBloc = getIt<GameBloc>();
    _boosterBloc = BoosterBloc(getIt<EconomyBloc>(), _gameBloc);
    getIt<EconomyBloc>().add(const ResetLevelBoosterFlags());
    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelId != widget.levelId) {
      _levelStarted = false;
      _layoutBallCount = 0;
      _lifeSpentForFail = false;
      _dropAnimationStarted = false;
      _dropController.reset();
      _mergeBlasts.clear();
      _stopLevelTimer();
    }
  }

  void _startLevelIfReady(Level level) {
    if (_levelStarted) return;
    if (_boardWidth <= 0 || _boardHeight <= 0) return;
    _levelStarted = true;
    _dropAnimationStarted = false;
    _dropController.reset();
    _gameBloc.add(
      StartLevel(level, boardWidth: _boardWidth, boardHeight: _boardHeight),
    );
    getIt<AnalyticsService>().logLevelStarted(
      levelNumber: level.id,
      difficulty: level.difficulty.name,
      source: widget.isDailyChallenge ? 'daily' : 'campaign',
    );
    _preloadGameAds();
  }

  void _preloadGameAds() {
    if (getIt<EconomyBloc>().state.economy.noAdsPurchased) return;
    final ads = getIt<AdBloc>();
    ads.add(
      const PreloadAdPlacement(
        format: AdFormat.rewarded,
        placement: AdsPlacements.rewardedHint,
      ),
    );
    ads.add(
      const PreloadAdPlacement(
        format: AdFormat.interstitial,
        placement: AdsPlacements.interstitialAfterLevel,
      ),
    );
  }

  void _maybeStartDropAnimation() {
    final playing = _gameBloc.state;
    if (playing is! GamePlaying) return;
    if (playing.gameState.dropComplete) return;
    if (_dropAnimationStarted) return;
    _startDropAnimation();
  }

  void _startDropAnimation() {
    if (_dropAnimationStarted && _dropController.isAnimating) return;
    _dropAnimationStarted = true;
    _stopLevelTimer();
    _dropController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      // Flag lives in GameBloc — no setState.
      _gameBloc.add(const CompleteDropAnimation());
    });
  }

  void _startLevelTimer() {
    _levelTimer?.cancel();
    _levelTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _gameBloc.add(const TickLevelTimer());
    });
  }

  void _stopLevelTimer() {
    _levelTimer?.cancel();
    _levelTimer = null;
  }

  double _ballDisplayY(
    Ball ball,
    double minY,
    double maxY, {
    required bool dropComplete,
  }) {
    if (dropComplete || ball.isDragging) return ball.y;
    final range = maxY - minY;
    // Bottom row (maxY) lands first; top row lands last.
    final stagger = range > 0 ? ((maxY - ball.y) / range) * 0.55 : 0.0;
    final progress = _dropController.value;
    final t = Curves.easeInCubic.transform(
      ((progress - stagger) / (1.0 - stagger)).clamp(0.0, 1.0),
    );
    const startY = -80.0;
    return ui.lerpDouble(startY, ball.y, t) ?? ball.y;
  }

  void _onPlayfieldSized(double width, double height, Level level) {
    final sizeChanged =
        (width - _boardWidth).abs() > 2 || (height - _boardHeight).abs() > 2;
    _boardWidth = width;
    _boardHeight = height;

    if (!_levelStarted) {
      _startLevelIfReady(level);
    } else if (sizeChanged) {
      _gameBloc.add(RelayoutBoard(boardWidth: width, boardHeight: height));
    }

    _maybeStartDropAnimation();
  }

  void _syncAudio(SettingsBlocState settings) {
    getIt<AudioService>().syncSettings(
      sound: settings.sound,
      music: settings.music,
      haptics: settings.haptics,
    );
  }

  Color _balloonColorFor(Ball ball) {
    if (ball.type == BallType.completeWord ||
        ball.type == BallType.wordInProgress) {
      return AppColors.marbleForWordChip(ball.chars).first;
    }
    return AppColors.marbleForBall(ball.id).first;
  }

  void _spawnMergeBlast(GamePlaying state, {required bool celebratory}) {
    final gs = state.gameState;
    final x = gs.mergeBlastX;
    final y = gs.mergeBlastY;
    if (x == null || y == null) return;

    Color color = AppColors.bubbleGlow;
    double blastRadius = 28;
    final snapId = gs.snapBallId;
    Ball? refBall;
    if (snapId != null) {
      refBall = gs.boardBalls.where((b) => b.id == snapId).firstOrNull ??
          gs.trayBalls.where((b) => b.id == snapId).firstOrNull;
    }
    refBall ??= gs.boardBalls.where((b) => b.isOnBoard).firstOrNull;
    if (refBall != null) {
      color = _balloonColorFor(refBall);
      blastRadius = _ballRadius(refBall);
    }

    final id = _nextBlastId++;
    setState(() {
      _mergeBlasts.add(
        _MergeBlastInstance(
          id: id,
          center: Offset(x, y),
          color: color,
          radius: blastRadius,
          celebratory: celebratory,
        ),
      );
    });
  }

  void _removeMergeBlast(int id) {
    if (!mounted) return;
    setState(() => _mergeBlasts.removeWhere((b) => b.id == id));
  }

  void _handleMergeFeedback(BuildContext context, GamePlaying state) {
    final feedback = state.gameState.mergeFeedback;
    if (feedback == MergeFeedback.none) return;

    final audio = getIt<AudioService>();
    final settings = context.read<SettingsBloc>().state;
    _syncAudio(settings);

    switch (feedback) {
      case MergeFeedback.correct:
        _spawnMergeBlast(state, celebratory: false);
        audio.playMergeBlast(celebratory: false);
      case MergeFeedback.wordComplete:
        _spawnMergeBlast(state, celebratory: true);
        audio.playMergeBlast(celebratory: true);
      case MergeFeedback.wrong:
        audio.playWrong();
      case MergeFeedback.none:
        break;
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _gameBloc.add(const ClearMergeFeedback());
    });
  }

  void _handleGameEndFeedback(BuildContext context, GameBlocState state) {
    final audio = getIt<AudioService>();
    _syncAudio(context.read<SettingsBloc>().state);

    if (state is GameWon) {
      audio.playWin();
    } else if (state is GameFailed) {
      if (state.reason == FailReason.timeOut) {
        audio.playTimeout();
      } else {
        audio.playFail();
      }
    }
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
      getIt<AnalyticsService>().logHintUsed(
        levelNumber: widget.levelId,
        source: 'free',
      );
      _boosterBloc.add(const UseHint());
      return;
    }

    if (inv.hint > 0) {
      if (!economy.noAdsPurchased) {
        _pendingAd = _PendingAdAction.hintInterstitial;
        context.read<AdBloc>().add(
              const ShowInterstitialAd(
                placement: AdsPlacements.interstitialHintGate,
              ),
            );
      } else {
        getIt<AnalyticsService>().logHintUsed(
          levelNumber: widget.levelId,
          source: 'inventory',
        );
        _boosterBloc.add(const UseHint());
      }
      return;
    }

    if (!economy.noAdsPurchased) {
      _pendingAd = _PendingAdAction.hintRewarded;
      context.read<AdBloc>().add(
            const ShowRewardedAd(placement: AdsPlacements.rewardedHint),
          );
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
        getIt<AnalyticsService>().logHintUsed(
          levelNumber: widget.levelId,
          source: 'inventory',
        );
        _boosterBloc.add(const UseHint());
      case _PendingAdAction.hintRewarded:
        if (state.rewarded) {
          getIt<AnalyticsService>().logRewardClaimed(
            rewardType: 'hint',
            source: 'rewarded_ad',
          );
          getIt<AnalyticsService>().logHintUsed(
            levelNumber: widget.levelId,
            source: 'rewarded_ad',
          );
          final inv = context.read<EconomyBloc>().state.economy.boosters;
          context.read<EconomyBloc>().add(
                UpdateBoosters(inv.copyWith(hint: inv.hint + 1)),
              );
          _boosterBloc.add(const UseHint());
        } else {
          _showSnackBar('Watch the full ad to get a hint');
        }
    }
  }

  @override
  void dispose() {
    final playing = _gameBloc.state;
    if (playing is GamePlaying) {
      getIt<AnalyticsService>().logLevelAbandoned(
        levelNumber: playing.gameState.level.id,
        difficulty: playing.gameState.level.difficulty.name,
        source: widget.isDailyChallenge ? 'daily' : 'campaign',
      );
    }
    _stopLevelTimer();
    _dropController.dispose();
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
                _dropAnimationStarted = false;
                _dropController.reset();
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
            listenWhen: (prev, curr) =>
                curr is GameWon ||
                curr is GameFailed ||
                (curr is GamePlaying &&
                    prev is GamePlaying &&
                    prev.gameState.mergeFeedback !=
                        curr.gameState.mergeFeedback) ||
                (curr is GamePlaying &&
                    prev is GamePlaying &&
                    prev.gameState.dropComplete != curr.gameState.dropComplete),
            listener: (context, state) {
              if (state is GamePlaying) {
                if (state.gameState.dropComplete) {
                  _startLevelTimer();
                } else {
                  _stopLevelTimer();
                }
                _handleMergeFeedback(context, state);
                return;
              }

              if (state is GameWon) {
                _stopLevelTimer();
                _handleGameEndFeedback(context, state);
                getIt<AnalyticsService>().logLevelCompleted(
                  levelNumber: state.gameState.level.id,
                  difficulty: state.gameState.level.difficulty.name,
                  timeSeconds: state.gameState.timeTotalSeconds -
                      state.gameState.timeLeftSeconds,
                  source: widget.isDailyChallenge ? 'daily' : 'campaign',
                );
                if (!widget.isDailyChallenge) {
                  final economy = context.read<EconomyBloc>();
                  final levelsBefore =
                      economy.state.economy.levelsCompletedSinceAd;
                  economy.add(CompleteLevel(
                    levelId: state.gameState.level.id,
                    stars: state.stars,
                  ));
                  if (!economy.state.economy.noAdsPurchased &&
                      levelsBefore + 1 >= 3) {
                    context.read<AdBloc>().add(
                          const ShowInterstitialAd(
                            placement: AdsPlacements.interstitialAfterLevel,
                          ),
                        );
                    economy.add(const ResetLevelsCompletedAd());
                  }
                }
              } else if (state is GameFailed) {
                _stopLevelTimer();
                _handleGameEndFeedback(context, state);
                getIt<AnalyticsService>().logLevelFailed(
                  levelNumber: state.gameState.level.id,
                  difficulty: state.gameState.level.difficulty.name,
                  timeSeconds: state.gameState.timeTotalSeconds -
                      state.gameState.timeLeftSeconds,
                  source: widget.isDailyChallenge ? 'daily' : 'campaign',
                );
                if (!_lifeSpentForFail) {
                  _lifeSpentForFail = true;
                  final economy = context.read<EconomyBloc>();
                  if (widget.isDailyChallenge) {
                    economy.add(const SpendGoldenHeart());
                  } else {
                    economy.add(const SpendLife());
                  }
                }
              }
            },
          ),
        ],
        child: GameParkBackground(
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
                  // Phase changes only — timer/drag must NOT rebuild whole screen.
                  buildWhen: (prev, curr) =>
                      prev.runtimeType != curr.runtimeType,
                  builder: (context, gameState) {
                    if (levelState is! LevelLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (gameState is GameWon) {
                      return Column(
                        children: [
                          Expanded(
                            child:                             LevelCompleteOverlay(
                              gameState: gameState,
                              onNext: widget.isDailyChallenge
                                  ? () => context.go('/daily')
                                  : () {
                                      final economy = getIt<EconomyBloc>();
                                      if (economy.state.economy.lives <= 0) {
                                        context.go('/home');
                                        return;
                                      }
                                      economy.add(const ResetLevelBoosterFlags());
                                      _lifeSpentForFail = false;
                                      final next = widget.levelId + 1;
                                      if (next <= 1000) {
                                        context.go('/game/$next');
                                      } else {
                                        context.go('/home');
                                      }
                                    },
                              onHome: widget.isDailyChallenge
                                  ? () => context.go('/daily')
                                  : () => context.go('/home'),
                            ),
                          ),
                          const BannerAdWidget(placement: AdsPlacements.result),
                        ],
                      );
                    }
                    if (gameState is GameFailed) {
                      return Column(
                        children: [
                          Expanded(
                            child:                             LevelFailOverlay(
                              gameState: gameState,
                              isDailyChallenge: widget.isDailyChallenge,
                              onRetry: () {
                                final economy =
                                    context.read<EconomyBloc>().state.economy;
                                final canRetry = widget.isDailyChallenge
                                    ? economy.goldenHearts > 0
                                    : economy.lives > 0;
                                if (!canRetry) return;
                                _lifeSpentForFail = false;
                                _levelStarted = true;
                                _dropAnimationStarted = false;
                                _dropController.reset();
                                getIt<AnalyticsService>().logLevelStarted(
                                  levelNumber: gameState.gameState.level.id,
                                  difficulty:
                                      gameState.gameState.level.difficulty.name,
                                  source: widget.isDailyChallenge
                                      ? 'daily'
                                      : 'campaign',
                                );
                                _preloadGameAds();
                                _gameBloc.add(StartLevel(
                                  gameState.gameState.level,
                                  boardWidth: _boardWidth,
                                  boardHeight: _boardHeight,
                                ));
                                _startDropAnimation();
                              },
                              onHome: widget.isDailyChallenge
                                  ? () => context.go('/daily')
                                  : () => context.go('/home'),
                            ),
                          ),
                          const BannerAdWidget(placement: AdsPlacements.result),
                        ],
                      );
                    }
                    if (gameState is GamePlaying) {
                      return _buildGameplay(context, levelState);
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

  Ball? _hitTestBall(Offset local, List<Ball> onBoard, {required bool dropComplete}) {
    final maxY = onBoard.fold(0.0, (m, b) => math.max(m, b.y));
    final minY = onBoard.fold(double.infinity, (m, b) => math.min(m, b.y));
    // Top-most ball first (same order as Stack paint: dragging last).
    for (var i = onBoard.length - 1; i >= 0; i--) {
      final ball = onBoard[i];
      final displayY = _ballDisplayY(
        ball,
        minY,
        maxY,
        dropComplete: dropComplete,
      );
      final radius = _ballRadius(ball);
      final dx = local.dx - ball.x;
      final dy = local.dy - displayY;
      if (dx * dx + dy * dy <= radius * radius) {
        return ball;
      }
    }
    return null;
  }

  void _onPlayfieldPointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;
    final playing = _gameBloc.state;
    if (playing is! GamePlaying) return;
    if (!playing.gameState.dropComplete && _dropController.isAnimating) {
      // Allow drag during/after drop; positions use live displayY.
    }

    final box =
        _playfieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(event.position);
    final gs = playing.gameState;
    final onBoard = gs.boardBalls.where((b) => b.isOnBoard).toList()
      ..sort((a, b) {
        if (a.isDragging) return 1;
        if (b.isDragging) return -1;
        return 0;
      });
    final ball = _hitTestBall(
      local,
      onBoard,
      dropComplete: gs.dropComplete,
    );
    if (ball == null) return;

    final maxY = onBoard.fold(0.0, (m, b) => math.max(m, b.y));
    final minY = onBoard.fold(double.infinity, (m, b) => math.min(m, b.y));
    final displayY = _ballDisplayY(
      ball,
      minY,
      maxY,
      dropComplete: gs.dropComplete,
    );

    _activePointer = event.pointer;
    _pointerDragBallId = ball.id;
    _dragTouchOffset = Offset(local.dx - ball.x, local.dy - displayY);
    _gameBloc.add(DragBallStart(ball.id));
    // Stick to finger immediately (no second touch needed).
    _gameBloc.add(
      DragBallUpdate(
        x: local.dx - _dragTouchOffset.dx,
        y: local.dy - _dragTouchOffset.dy,
      ),
    );
  }

  void _onPlayfieldPointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer || _pointerDragBallId == null) return;
    final box =
        _playfieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(event.position);
    _gameBloc.add(
      DragBallUpdate(
        x: local.dx - _dragTouchOffset.dx,
        y: local.dy - _dragTouchOffset.dy,
      ),
    );
  }

  void _onPlayfieldPointerUp(PointerEvent event) {
    if (_activePointer != event.pointer) return;
    _activePointer = null;
    _pointerDragBallId = null;
    _dragTouchOffset = Offset.zero;
    _gameBloc.add(const DragBallEnd());
  }

  List<Widget> _buildBoardBallWidgets(
    List<Ball> onBoard,
    String? snapBallId, {
    required bool dropComplete,
  }) {
    final maxY = onBoard.fold(0.0, (m, b) => math.max(m, b.y));
    final minY = onBoard.fold(double.infinity, (m, b) => math.min(m, b.y));
    final widgets = <Widget>[];
    for (var i = 0; i < onBoard.length; i++) {
      final ball = onBoard[i];
      final displayY = _ballDisplayY(
        ball,
        minY,
        maxY,
        dropComplete: dropComplete,
      );
      final size = _ballSize(ball);
      widgets.add(
        Positioned(
          left: ball.x - size / 2,
          top: displayY - size / 2,
          child: BubbleBallWidget(
            key: ValueKey<String>(ball.id),
            ball: ball,
            radius: _ballRadius(ball),
            enableIdleFloat: dropComplete,
            mergeSnapping: snapBallId == ball.id,
            // Drag handled by playfield Listener so rebuilds don't cancel gesture.
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
            timeLeftSeconds:
                levelState.level.wordCount * GameConstants.secondsPerWord,
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
        const BannerAdWidget(placement: AdsPlacements.game),
      ],
    );
  }

  Widget _buildGameplay(BuildContext context, LevelLoaded levelState) {
    return Column(
      children: [
        // Timer ticks only rebuild the header — not every ball.
        BlocBuilder<GameBloc, GameBlocState>(
          buildWhen: (prev, curr) {
            if (prev is! GamePlaying || curr is! GamePlaying) return true;
            final a = prev.gameState;
            final b = curr.gameState;
            return a.timeLeftSeconds != b.timeLeftSeconds ||
                a.level.id != b.level.id;
          },
          builder: (context, gameState) {
            final gs = (gameState as GamePlaying).gameState;
            return BlocBuilder<EconomyBloc, EconomyBlocState>(
              builder: (context, econState) => GameHeaderBar(
                levelId: gs.level.id,
                timeLeftSeconds: gs.timeLeftSeconds,
                onBack: () => context.go('/home'),
                hintCount: econState.economy.boosters.hint,
                onHint: () => _handleHint(context),
              ),
            );
          },
        ),
        BlocBuilder<GameBloc, GameBlocState>(
          buildWhen: (prev, curr) {
            if (prev is! GamePlaying || curr is! GamePlaying) return true;
            return prev.gameState.completedWordIds !=
                curr.gameState.completedWordIds;
          },
          builder: (context, gameState) {
            final gs = (gameState as GamePlaying).gameState;
            return TargetWordsPanel(
              level: gs.level,
              completedWordIds: gs.completedWordIds,
            );
          },
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

              return BlocBuilder<GameBloc, GameBlocState>(
                buildWhen: (prev, curr) {
                  if (prev is! GamePlaying || curr is! GamePlaying) {
                    return true;
                  }
                  final a = prev.gameState;
                  final b = curr.gameState;
                  // Ignore timer-only emits.
                  return !identical(a.boardBalls, b.boardBalls) ||
                      a.hintBallIds != b.hintBallIds ||
                      a.mergeFeedback != b.mergeFeedback ||
                      a.snapBallId != b.snapBallId ||
                      a.draggingBallId != b.draggingBallId ||
                      a.dropComplete != b.dropComplete;
                },
                builder: (context, gameState) {
                  final gs = (gameState as GamePlaying).gameState;
                  if (_layoutBallCount == 0) {
                    _layoutBallCount =
                        gs.boardBalls.where((b) => b.isOnBoard).length;
                  }
                  final wrongFlash =
                      gs.mergeFeedback == MergeFeedback.wrong;

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

                  final onBoard =
                      gs.boardBalls.where((b) => b.isOnBoard).toList()
                        ..sort((a, b) {
                          if (a.isDragging) return 1;
                          if (b.isDragging) return -1;
                          return 0;
                        });

                  Stack buildPlayfield() {
                    Ball? guideFrom;
                    Ball? guideTo;
                    if (widget.levelId == 1 &&
                        gs.dropComplete &&
                        gs.hintBallIds.length >= 2) {
                      guideFrom = gs.boardBalls
                          .where((b) => b.id == gs.hintBallIds[0])
                          .firstOrNull;
                      guideTo = gs.boardBalls
                          .where((b) => b.id == gs.hintBallIds[1])
                          .firstOrNull;
                    }

                    return Stack(
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
                        ..._buildBoardBallWidgets(
                          onBoard,
                          gs.snapBallId,
                          dropComplete: gs.dropComplete,
                        ),
                        ..._mergeBlasts.map(
                          (blast) => MergeBlastEffect(
                            key: ValueKey('blast_${blast.id}'),
                            center: blast.center,
                            color: blast.color,
                            radius: blast.radius,
                            celebratory: blast.celebratory,
                            onComplete: () => _removeMergeBlast(blast.id),
                          ),
                        ),
                        if (guideFrom != null &&
                            guideTo != null &&
                            !gs.boardBalls.any((b) => b.isDragging))
                          GuideHandOverlay(
                            key: ValueKey(
                              '${guideFrom.id}_${guideTo.id}',
                            ),
                            from: Offset(guideFrom.x, guideFrom.y),
                            to: Offset(guideTo.x, guideTo.y),
                          ),
                      ],
                    );
                  }

                  // Drop frames: AnimationController only (no setState).
                  final stack = gs.dropComplete
                      ? buildPlayfield()
                      : AnimatedBuilder(
                          animation: _dropController,
                          builder: (context, _) => buildPlayfield(),
                        );

                  // Pointer drag on stable parent — no "tap then drag" gesture loss.
                  final playfield = Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _onPlayfieldPointerDown,
                    onPointerMove: _onPlayfieldPointerMove,
                    onPointerUp: _onPlayfieldPointerUp,
                    onPointerCancel: _onPlayfieldPointerUp,
                    child: stack,
                  );

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: wrongFlash
                        ? AppColors.accentRed.withValues(alpha: 0.08)
                        : Colors.transparent,
                    child: playfield,
                  );
                },
              );
            },
          ),
        ),
        const BannerAdWidget(placement: AdsPlacements.game),
      ],
    );
  }
}

enum _PendingAdAction {
  hintInterstitial,
  hintRewarded,
}

class _MergeBlastInstance {
  const _MergeBlastInstance({
    required this.id,
    required this.center,
    required this.color,
    required this.radius,
    required this.celebratory,
  });

  final int id;
  final Offset center;
  final Color color;
  final double radius;
  final bool celebratory;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
