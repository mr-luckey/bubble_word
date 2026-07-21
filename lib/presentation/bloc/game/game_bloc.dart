import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/ball_physics_engine.dart';
import '../../../core/utils/board_layout.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/game_constants.dart';
import '../../../domain/entities/ball.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/game_state.dart';
import '../../../domain/entities/level.dart';
import '../../../domain/usecases/calculate_star_rating.dart';
import '../../../domain/usecases/check_board_overload.dart';
import '../../../domain/usecases/game_engine.dart';
import '../../../domain/usecases/validate_merge.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameBlocState> {
  GameBloc({
    required InitializeGameState initializeGameState,
    required ValidateMerge validateMerge,
    required CheckBoardOverload checkBoardOverload,
    required CalculateStarRating calculateStarRating,
    required SpawnBallFromQueue spawnBallFromQueue,
    required SplitJunkBall splitJunkBall,
    required BallPhysicsEngine physicsEngine,
  })  : _initializeGameState = initializeGameState,
        _validateMerge = validateMerge,
        _checkBoardOverload = checkBoardOverload,
        _calculateStarRating = calculateStarRating,
        _spawnBallFromQueue = spawnBallFromQueue,
        _splitJunkBall = splitJunkBall,
        _physicsEngine = physicsEngine,
        super(const GameInitial()) {
    on<StartLevel>(_onStartLevel);
    on<RelayoutBoard>(_onRelayoutBoard);
    on<TickLevelTimer>(_onTickLevelTimer);
    on<TickPhysics>(_onTickPhysics);
    on<DragBallStart>(_onDragStart);
    on<DragBallUpdate>(_onDragUpdate);
    on<DragBallEnd>(_onDragEnd);
    on<MergeBallsAttempt>(_onMergeAttempt);
    on<SpawnNextBall>(_onSpawnNext);
    on<ApplyHint>(_onApplyHint);
    on<ApplyMagnet>(_onApplyMagnet);
    on<ApplyAddBall>(_onApplyAddBall);
    on<ApplyMagicWand>(_onApplyMagicWand);
    on<AddExtraMoves>(_onAddExtraMoves);
    on<ClearMergeFeedback>(_onClearMergeFeedback);
    on<ResetGame>(_onReset);
  }

  final InitializeGameState _initializeGameState;
  final ValidateMerge _validateMerge;
  final CheckBoardOverload _checkBoardOverload;
  final CalculateStarRating _calculateStarRating;
  final SpawnBallFromQueue _spawnBallFromQueue;
  final SplitJunkBall _splitJunkBall;
  final BallPhysicsEngine _physicsEngine;

  double _boardWidth = 360;
  double _boardHeight = 480;
  int _layoutBallCount = 0;
  String? _draggingId;
  double _dragOriginX = 0;
  double _dragOriginY = 0;
  static const double _mergeSnapPadding = 20;

  Future<void> _onStartLevel(StartLevel event, Emitter<GameBlocState> emit) async {
    _boardWidth = event.boardWidth;
    _boardHeight = event.boardHeight;
    final gameState = _initializeGameState(
      event.level,
      boardWidth: _boardWidth,
      boardHeight: _boardHeight,
    );
    _layoutBallCount =
        gameState.boardBalls.where((b) => b.isOnBoard).length;
    emit(GamePlaying(gameState));
  }

  void _onRelayoutBoard(RelayoutBoard event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    if (current.gameState.phase != GamePhase.buildingWords) return;

    _boardWidth = event.boardWidth;
    _boardHeight = event.boardHeight;

    final onBoard =
        current.gameState.boardBalls.where((b) => b.isOnBoard).toList();
    if (onBoard.isEmpty) return;

    final laid = BoardLayout.layoutFragments(
      balls: onBoard,
      width: _boardWidth,
      height: _boardHeight,
      layoutBallCount: _layoutBallCount,
    );
    final byId = {for (final b in laid) b.id: b};
    final boardBalls = current.gameState.boardBalls.map((b) {
      if (!b.isOnBoard) return b;
      final updated = byId[b.id];
      if (updated == null) return b;
      return b.copyWith(x: updated.x, y: updated.y);
    }).toList();

    emit(GamePlaying(current.gameState.copyWith(boardBalls: boardBalls)));
  }

  List<Ball> _separateBoard(List<Ball> balls) {
    return BoardLayout.resolveOverlaps(
      balls,
      width: _boardWidth,
      height: _boardHeight,
    );
  }

  void _onTickLevelTimer(TickLevelTimer event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    if (current.gameState.phase == GamePhase.won ||
        current.gameState.phase == GamePhase.failed) {
      return;
    }

    final timeLeft = current.gameState.timeLeftSeconds - 1;
    if (timeLeft <= 0) {
      emit(GameFailed(
        current.gameState.copyWith(timeLeftSeconds: 0, phase: GamePhase.failed),
        FailReason.timeOut,
        stars: 0,
      ));
      return;
    }

    emit(GamePlaying(
      current.gameState.copyWith(timeLeftSeconds: timeLeft),
    ));
  }

  void _onTickPhysics(TickPhysics event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    if (current.gameState.phase == GamePhase.won ||
        current.gameState.phase == GamePhase.failed) {
      return;
    }
    _boardWidth = event.boardWidth;
    _boardHeight = event.boardHeight;
    var updated = _physicsEngine.tick(
      current.gameState,
      event.deltaTime,
      event.boardWidth,
      event.boardHeight,
    );
    if (_checkBoardOverload(updated, maxBalls: 18)) {
      emit(GameFailed(
        updated.copyWith(phase: GamePhase.failed),
        FailReason.boardOverload,
        stars: 0,
      ));
      return;
    }
    emit(GamePlaying(updated));
  }

  void _onDragStart(DragBallStart event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    _draggingId = event.ballId;
    final ball = current.gameState.boardBalls
        .where((b) => b.id == event.ballId)
        .firstOrNull;
    if (ball != null) {
      _dragOriginX = ball.x;
      _dragOriginY = ball.y;
    }
    final balls = current.gameState.boardBalls.map((b) {
      if (b.id == event.ballId) {
        return b.copyWith(isDragging: true, vx: 0, vy: 0);
      }
      return b;
    }).toList();
    emit(GamePlaying(current.gameState.copyWith(
      boardBalls: balls,
      draggingBallId: event.ballId,
    )));
  }

  void _onDragUpdate(DragBallUpdate event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying || _draggingId == null) return;
    final balls = current.gameState.boardBalls.map((b) {
      if (b.id == _draggingId) {
        return b.copyWith(x: event.x, y: event.y);
      }
      return b;
    }).toList();
    emit(GamePlaying(current.gameState.copyWith(boardBalls: balls)));
  }

  void _onDragEnd(DragBallEnd event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying || _draggingId == null) return;
    final source = current.gameState.boardBalls
        .where((b) => b.id == _draggingId)
        .firstOrNull;
    if (source == null) {
      _draggingId = null;
      return;
    }

    Ball? target;
    var closestDist = double.infinity;
    for (final b in current.gameState.boardBalls) {
      if (b.id == source.id || !b.isOnBoard) continue;
      final dist = _distance(source, b);
      final mergeRadius = _boardBallRadius();
      final mergeRange = mergeRadius * 2 + _mergeSnapPadding;
      if (dist <= mergeRange && dist < closestDist) {
        closestDist = dist;
        target = b;
      }
    }

    if (target != null) {
      add(MergeBallsAttempt(sourceId: source.id, targetId: target.id));
    } else {
      final balls = current.gameState.boardBalls.map((b) {
        if (b.id == _draggingId) return b.copyWith(isDragging: false);
        return b;
      }).toList();
      emit(GamePlaying(current.gameState.copyWith(
        boardBalls: balls,
        clearDragging: true,
      )));
    }
    _draggingId = null;
  }

  void _onMergeAttempt(MergeBallsAttempt event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;

    final gs = current.gameState;

    final source = _findBall(gs, event.sourceId);
    final target = _findBall(gs, event.targetId);
    if (source == null || target == null) return;

    final result = _validateMerge(
      source: source,
      target: target,
      level: gs.level,
      phase: gs.phase,
    );
    if (result == null) {
      final balls = gs.boardBalls.map((b) {
        if (b.id == source.id) {
          return b.copyWith(
            x: _dragOriginX,
            y: _dragOriginY,
            isDragging: false,
          );
        }
        return b.copyWith(isDragging: false);
      }).toList();
      emit(GamePlaying(gs.copyWith(
        boardBalls: balls,
        mergeFeedback: MergeFeedback.wrong,
        clearDragging: true,
      )));
      return;
    }

    var boardBalls = gs.boardBalls
        .where((b) => !result.removedBallIds.contains(b.id))
        .map((b) {
          if (b.id == target.id) {
            return result.resultBall.copyWith(
              x: target.x,
              y: target.y,
              isDragging: false,
            );
          }
          return b.copyWith(isDragging: false);
        })
        .toList();

    var trayBalls = List<Ball>.from(gs.trayBalls);
    var completedIds = List<String>.from(gs.completedWordIds);
    var phase = gs.phase;

    if (result.isCorrect && result.completedWordId != null) {
      completedIds.add(result.completedWordId!);
      boardBalls = boardBalls.where((b) => b.id != target.id).toList();
      trayBalls.add(result.resultBall);
      if (completedIds.length >= gs.level.wordCount) {
        _emitWin(
          emit,
          gs,
          boardBalls: boardBalls,
          trayBalls: trayBalls,
          completedWordIds: completedIds,
        );
        return;
      }
      boardBalls = _separateBoard(boardBalls);
    } else if (result.isCorrect && gs.phase == GamePhase.buildingWords) {
      boardBalls = _separateBoard(boardBalls);
    }

    emit(GamePlaying(gs.copyWith(
      phase: phase,
      boardBalls: boardBalls,
      trayBalls: trayBalls,
      completedWordIds: completedIds,
      mergeFeedback: MergeFeedback.correct,
      snapBallId: result.resultBall.id,
      clearDragging: true,
      clearLastWrong: true,
    )));
  }

  void _onSpawnNext(SpawnNextBall event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    if (current.gameState.phase != GamePhase.buildingWords) return;
    if (current.gameState.queue.isEmpty) return;

    final ball = _spawnBallFromQueue(current.gameState, boardWidth: _boardWidth);
    if (ball == null) return;

    final queue = List<Ball>.from(current.gameState.queue)..removeAt(0);
    final boardBalls = [...current.gameState.boardBalls, ball];
    emit(GamePlaying(current.gameState.copyWith(
      boardBalls: boardBalls,
      queue: queue,
    )));
  }

  void _onApplyHint(ApplyHint event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    final gs = current.gameState;
    if (gs.phase != GamePhase.buildingWords) return;

    final fragments = gs.boardBalls
        .where((b) =>
            b.type != BallType.decoy &&
            (b.type == BallType.fragment ||
                b.type == BallType.wordInProgress))
        .toList();

    for (var i = 0; i < fragments.length; i++) {
      for (var j = i + 1; j < fragments.length; j++) {
        final a = fragments[i];
        final b = fragments[j];
        final mergeA = _validateMerge(
          source: a,
          target: b,
          level: gs.level,
          phase: gs.phase,
        );
        final mergeB = _validateMerge(
          source: b,
          target: a,
          level: gs.level,
          phase: gs.phase,
        );
        if ((mergeA?.isCorrect ?? false) || (mergeB?.isCorrect ?? false)) {
          final ids = [a.id, b.id];
          final balls = gs.boardBalls.map((ball) {
            return ball.copyWith(isHighlighted: ids.contains(ball.id));
          }).toList();
          emit(GamePlaying(gs.copyWith(boardBalls: balls, hintBallIds: ids)));
          return;
        }
      }
    }
  }

  void _onApplyMagnet(ApplyMagnet event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    var gs = current.gameState;
    final word = gs.level.words.firstWhere((w) => w.id == event.wordId);

    final wordBalls = gs.boardBalls.where((b) {
      if (b.type == BallType.decoy ||
          b.type == BallType.completeWord ||
          b.type == BallType.junk) {
        return false;
      }
      if (b.wordId == word.id) return true;
      if (word.fragments.contains(b.chars)) return true;
      return b.type == BallType.wordInProgress &&
          word.text.startsWith(b.chars);
    }).toList();
    if (wordBalls.length < 2) return;

    var combined = wordBalls.first;
    for (var i = 1; i < wordBalls.length; i++) {
      final result = _validateMerge(
        source: wordBalls[i],
        target: combined,
        level: gs.level,
        phase: GamePhase.buildingWords,
      );
      if (result != null && result.isCorrect) {
        combined = result.resultBall;
      }
    }

    var boardBalls = gs.boardBalls.where((b) => b.wordId != word.id).toList();
    var trayBalls = List<Ball>.from(gs.trayBalls);
    var completedIds = List<String>.from(gs.completedWordIds);

    if (combined.type == BallType.completeWord) {
      completedIds.add(word.id);
      trayBalls.add(combined);
    } else {
      boardBalls.add(combined);
    }

    if (completedIds.length >= gs.level.wordCount) {
      _emitWin(
        emit,
        gs,
        boardBalls: boardBalls,
        trayBalls: trayBalls,
        completedWordIds: completedIds,
      );
      return;
    }

    boardBalls = _separateBoard(boardBalls);

    gs = gs.copyWith(
      boardBalls: boardBalls,
      trayBalls: trayBalls,
      completedWordIds: completedIds,
    );
    emit(GamePlaying(gs));
  }

  void _onApplyAddBall(ApplyAddBall event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    if (current.gameState.queue.isNotEmpty) {
      add(const SpawnNextBall());
      return;
    }
    emit(GamePlaying(
      current.gameState.copyWith(
        timeLeftSeconds: current.gameState.timeLeftSeconds +
            GameConstants.secondsPerWord,
      ),
    ));
  }

  void _onApplyMagicWand(ApplyMagicWand event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    final gs = current.gameState;
    final junkId = gs.lastWrongMergeBallId;
    if (junkId == null) return;

    final junk = gs.boardBalls.where((b) => b.id == junkId).firstOrNull;
    if (junk == null || junk.type != BallType.junk) return;

    final split = _splitJunkBall(junk, gs);
    if (split == null || split.length < 2) return;

    final boardBalls = gs.boardBalls.where((b) => b.id != junkId).toList()
      ..addAll(split);
    emit(GamePlaying(gs.copyWith(
      boardBalls: boardBalls,
      clearLastWrong: true,
    )));
  }

  void _onClearMergeFeedback(ClearMergeFeedback event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    emit(GamePlaying(
      current.gameState.copyWith(
        mergeFeedback: MergeFeedback.none,
        clearSnap: true,
      ),
    ));
  }

  void _onAddExtraMoves(AddExtraMoves event, Emitter<GameBlocState> emit) {
    final current = state;
    if (current is! GamePlaying) return;
    emit(GamePlaying(
      current.gameState.copyWith(
        timeLeftSeconds: current.gameState.timeLeftSeconds +
            GameConstants.secondsPerWord,
      ),
    ));
  }

  void _onReset(ResetGame event, Emitter<GameBlocState> emit) {
    _layoutBallCount = 0;
    emit(const GameInitial());
  }

  double _boardBallRadius() {
    if (_layoutBallCount <= 0) {
      return AppDimensions.ballRadiusSmall;
    }
    return BoardLayout.uniformBoardRadius(
      ballCount: _layoutBallCount,
      width: _boardWidth,
      height: _boardHeight,
    );
  }

  Ball? _findBall(GameState gs, String id) {
    return gs.boardBalls.where((b) => b.id == id).firstOrNull ??
        gs.trayBalls.where((b) => b.id == id).firstOrNull;
  }

  void _emitWin(
    Emitter<GameBlocState> emit,
    GameState gs, {
    required List<Ball> boardBalls,
    required List<Ball> trayBalls,
    required List<String> completedWordIds,
  }) {
    final stars = _calculateStarRating(
      timeLeftSeconds: gs.timeLeftSeconds,
      timeTotalSeconds: gs.timeTotalSeconds,
    );
    emit(GameWon(
      gs.copyWith(
        phase: GamePhase.won,
        boardBalls: boardBalls,
        trayBalls: trayBalls,
        completedWordIds: completedWordIds,
      ),
      stars: stars,
    ));
  }

  double _distance(Ball a, Ball b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  Future<void> close() => super.close();
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
