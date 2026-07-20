import '../entities/ball.dart';
import '../entities/enums.dart';
import '../entities/game_state.dart';
import '../entities/level.dart';
import '../../core/utils/board_layout.dart';
import '../../core/utils/decoy_ball_generator.dart';
import 'package:uuid/uuid.dart';

class InitializeGameState {
  const InitializeGameState(this._uuid);

  final Uuid _uuid;

  GameState call(Level level, {double boardWidth = 360, double boardHeight = 480}) {
    final fragments = <Ball>[];
    for (final word in level.words) {
      for (final fragment in word.fragments) {
        fragments.add(
          Ball(
            id: _uuid.v4(),
            chars: fragment,
            type: BallType.fragment,
            wordId: word.id,
            category: level.category,
            mergeTotal: word.fragments.length,
            isOnBoard: true,
          ),
        );
      }
    }
    final decoys = DecoyBallGenerator.generate(level, _uuid);
    fragments.addAll(decoys);
    fragments.shuffle();

    final boardBalls = BoardLayout.layoutFragments(
      balls: fragments,
      width: boardWidth,
      height: boardHeight,
    );

    return GameState(
      level: level,
      phase: GamePhase.buildingWords,
      boardBalls: boardBalls,
      trayBalls: [],
      queue: const [],
      movesLeft: level.moveBudget,
      movesTotal: level.moveBudget,
      completedWordIds: [],
      lastWrongMergeBallId: null,
    );
  }
}

class SpawnBallFromQueue {
  Ball? call(GameState state, {required double boardWidth}) {
    if (state.queue.isEmpty) return null;
    final ball = state.queue.first;
    return ball.copyWith(
      isOnBoard: true,
      x: boardWidth / 2,
      y: 80,
    );
  }
}

class SplitJunkBall {
  List<Ball>? call(Ball junkBall, GameState state) {
    if (junkBall.type != BallType.junk) return null;
    if (junkBall.mergedFrom.length < 2) return null;

    final mid = junkBall.chars.length ~/ 2;
    if (mid == 0) return null;

    return [
      Ball(
        id: '${junkBall.id}_a',
        chars: junkBall.chars.substring(0, mid),
        type: BallType.fragment,
        wordId: junkBall.wordId,
        category: junkBall.category,
        x: junkBall.x - 30,
        y: junkBall.y,
        isOnBoard: true,
      ),
      Ball(
        id: '${junkBall.id}_b',
        chars: junkBall.chars.substring(mid),
        type: BallType.fragment,
        wordId: junkBall.wordId,
        category: junkBall.category,
        x: junkBall.x + 30,
        y: junkBall.y,
        isOnBoard: true,
      ),
    ];
  }
}
