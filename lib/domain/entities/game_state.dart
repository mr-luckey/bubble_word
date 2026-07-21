import 'package:equatable/equatable.dart';
import 'ball.dart';
import 'enums.dart';
import 'level.dart';

class GameState extends Equatable {
  const GameState({
    required this.level,
    required this.phase,
    required this.boardBalls,
    required this.trayBalls,
    required this.queue,
    required this.timeLeftSeconds,
    required this.timeTotalSeconds,
    required this.completedWordIds,
    required this.lastWrongMergeBallId,
    this.draggingBallId,
    this.hintBallIds = const [],
    this.showMergePrompt = false,
    this.mergeFeedback = MergeFeedback.none,
    this.snapBallId,
  });

  final Level level;
  final GamePhase phase;
  final List<Ball> boardBalls;
  final List<Ball> trayBalls;
  final List<Ball> queue;
  final int timeLeftSeconds;
  final int timeTotalSeconds;
  final List<String> completedWordIds;
  final String? lastWrongMergeBallId;
  final String? draggingBallId;
  final List<String> hintBallIds;
  final bool showMergePrompt;
  final MergeFeedback mergeFeedback;
  final String? snapBallId;

  bool get allWordsComplete =>
      completedWordIds.length >= level.wordCount;

  int get queueRemaining => queue.length;

  GameState copyWith({
    Level? level,
    GamePhase? phase,
    List<Ball>? boardBalls,
    List<Ball>? trayBalls,
    List<Ball>? queue,
    int? timeLeftSeconds,
    int? timeTotalSeconds,
    List<String>? completedWordIds,
    String? lastWrongMergeBallId,
    String? draggingBallId,
    List<String>? hintBallIds,
    bool? showMergePrompt,
    MergeFeedback? mergeFeedback,
    String? snapBallId,
    bool clearLastWrong = false,
    bool clearDragging = false,
    bool clearSnap = false,
  }) {
    return GameState(
      level: level ?? this.level,
      phase: phase ?? this.phase,
      boardBalls: boardBalls ?? this.boardBalls,
      trayBalls: trayBalls ?? this.trayBalls,
      queue: queue ?? this.queue,
      timeLeftSeconds: timeLeftSeconds ?? this.timeLeftSeconds,
      timeTotalSeconds: timeTotalSeconds ?? this.timeTotalSeconds,
      completedWordIds: completedWordIds ?? this.completedWordIds,
      lastWrongMergeBallId: clearLastWrong
          ? null
          : (lastWrongMergeBallId ?? this.lastWrongMergeBallId),
      draggingBallId:
          clearDragging ? null : (draggingBallId ?? this.draggingBallId),
      hintBallIds: hintBallIds ?? this.hintBallIds,
      showMergePrompt: showMergePrompt ?? this.showMergePrompt,
      mergeFeedback: mergeFeedback ?? this.mergeFeedback,
      snapBallId: clearSnap ? null : (snapBallId ?? this.snapBallId),
    );
  }

  @override
  List<Object?> get props => [
        level,
        phase,
        boardBalls,
        trayBalls,
        queue,
        timeLeftSeconds,
        timeTotalSeconds,
        completedWordIds,
        lastWrongMergeBallId,
        draggingBallId,
        hintBallIds,
        showMergePrompt,
        mergeFeedback,
        snapBallId,
      ];
}
