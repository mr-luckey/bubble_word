import '../entities/ball.dart';
import '../entities/enums.dart';
import '../entities/game_state.dart';
import '../entities/level.dart';
import 'validate_merge.dart';

class CheckBoardOverload {
  CheckBoardOverload(this._validateMerge);

  final ValidateMerge _validateMerge;

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
        if (_canMerge(balls[i], balls[j], state.level, state.phase)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _canMerge(Ball a, Ball b, Level level, GamePhase phase) {
    return _validateMerge(source: a, target: b, level: level, phase: phase) !=
            null ||
        _validateMerge(source: b, target: a, level: level, phase: phase) !=
            null;
  }
}
