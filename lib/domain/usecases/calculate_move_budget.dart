import '../entities/level.dart';

class CalculateMoveBudget {
  int call(Level level) {
    var minMoves = 0;
    for (final word in level.words) {
      minMoves += word.fragments.length - 1;
    }
    // Phase 2 super-merge moves (PDF Section 6 counts these in budget)
    minMoves += (level.wordCount - 1) * 2;
    return (minMoves * level.difficulty.moveMultiplier).ceil();
  }

  int minimumMoves(Level level) {
    var minMoves = 0;
    for (final word in level.words) {
      minMoves += word.fragments.length - 1;
    }
    minMoves += (level.wordCount - 1) * 2;
    return minMoves;
  }
}
