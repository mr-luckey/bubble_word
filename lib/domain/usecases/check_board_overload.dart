import '../entities/ball.dart';
import '../entities/enums.dart';
import '../entities/game_state.dart';

class CheckBoardOverload {
  bool call(GameState state, {required int maxBalls}) {
    if (state.phase != GamePhase.buildingWords) return false;
    if (state.movesLeft > 0) {
      final onBoard = state.boardBalls.where((b) => b.isOnBoard).length;
      if (onBoard < maxBalls) return false;
    }
    return !_hasValidMerge(state);
  }

  bool _hasValidMerge(GameState state) {
    final balls = state.boardBalls.where((b) => b.isOnBoard).toList();
    for (var i = 0; i < balls.length; i++) {
      for (var j = i + 1; j < balls.length; j++) {
        if (_canMerge(balls[i], balls[j])) return true;
      }
    }
    return false;
  }

  bool _canMerge(Ball a, Ball b) {
    if (a.type == BallType.decoy || b.type == BallType.decoy) return false;
    if (a.type == BallType.junk || b.type == BallType.junk) return false;
    if (a.type == BallType.completeWord || b.type == BallType.completeWord) {
      return false;
    }
    if (a.wordId != b.wordId) return false;
    return true;
  }
}
