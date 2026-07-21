part of 'game_bloc.dart';

sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class StartLevel extends GameEvent {
  const StartLevel(this.level, {this.boardWidth = 360, this.boardHeight = 480});
  final Level level;
  final double boardWidth;
  final double boardHeight;

  @override
  List<Object?> get props => [level, boardWidth, boardHeight];
}

class RelayoutBoard extends GameEvent {
  const RelayoutBoard({required this.boardWidth, required this.boardHeight});
  final double boardWidth;
  final double boardHeight;

  @override
  List<Object?> get props => [boardWidth, boardHeight];
}

class TickPhysics extends GameEvent {
  const TickPhysics({
    required this.deltaTime,
    required this.boardWidth,
    required this.boardHeight,
  });

  final double deltaTime;
  final double boardWidth;
  final double boardHeight;

  @override
  List<Object?> get props => [deltaTime, boardWidth, boardHeight];
}

class DragBallStart extends GameEvent {
  const DragBallStart(this.ballId);
  final String ballId;

  @override
  List<Object?> get props => [ballId];
}

class DragBallUpdate extends GameEvent {
  const DragBallUpdate({required this.x, required this.y});
  final double x;
  final double y;

  @override
  List<Object?> get props => [x, y];
}

class DragBallEnd extends GameEvent {
  const DragBallEnd();
}

class MergeBallsAttempt extends GameEvent {
  const MergeBallsAttempt({required this.sourceId, required this.targetId});
  final String sourceId;
  final String targetId;

  @override
  List<Object?> get props => [sourceId, targetId];
}

class SpawnNextBall extends GameEvent {
  const SpawnNextBall();
}

class ApplyHint extends GameEvent {
  const ApplyHint();
}

class ApplyMagnet extends GameEvent {
  const ApplyMagnet(this.wordId);
  final String wordId;

  @override
  List<Object?> get props => [wordId];
}

class ApplyAddBall extends GameEvent {
  const ApplyAddBall();
}

class ApplyMagicWand extends GameEvent {
  const ApplyMagicWand();
}

class AddExtraMoves extends GameEvent {
  const AddExtraMoves();
}

class ClearMergeFeedback extends GameEvent {
  const ClearMergeFeedback();
}

class ResetGame extends GameEvent {
  const ResetGame();
}
