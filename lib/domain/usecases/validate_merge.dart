import '../entities/ball.dart';
import '../entities/enums.dart';
import '../entities/level.dart';

class MergeResult {
  const MergeResult({
    required this.success,
    required this.isCorrect,
    required this.sourceBall,
    required this.targetBall,
    required this.resultBall,
    required this.removedBallIds,
    required this.completedWordId,
    required this.movesToDeduct,
  });

  final bool success;
  final bool isCorrect;
  final Ball sourceBall;
  final Ball targetBall;
  final Ball resultBall;
  final List<String> removedBallIds;
  final String? completedWordId;
  final int movesToDeduct;
}

class ValidateMerge {
  MergeResult? call({
    required Ball source,
    required Ball target,
    required Level level,
    required GamePhase phase,
  }) {
    if (source.id == target.id) return null;

    if (phase == GamePhase.mergingWords) {
      if (source.type != BallType.completeWord ||
          target.type != BallType.completeWord) {
        return null;
      }
      final mergedChars = '${target.chars} ${source.chars}'.trim();
      return MergeResult(
        success: true,
        isCorrect: true,
        sourceBall: source,
        targetBall: target,
        resultBall: target.copyWith(
          chars: mergedChars,
          type: BallType.completeWord,
          mergedFrom: [...target.mergedFrom, source.id],
        ),
        removedBallIds: [source.id],
        completedWordId: null,
        movesToDeduct: 1,
      );
    }

    if (source.type == BallType.decoy ||
        target.type == BallType.decoy ||
        source.type == BallType.completeWord ||
        target.type == BallType.completeWord ||
        source.type == BallType.junk ||
        target.type == BallType.junk ||
        source.type == BallType.superBall ||
        target.type == BallType.superBall) {
      return null;
    }

    if (source.wordId != target.wordId) {
      return null;
    }

    final word = level.words.firstWhere(
      (w) => w.id == source.wordId,
      orElse: () => level.words.first,
    );

    final combined = _bestCombination(target.chars, source.chars, word.text);
    if (combined == null) {
      return null;
    }

    final progress = _countMergedFragments(combined, word);
    final isComplete = combined == word.text;

    return MergeResult(
      success: true,
      isCorrect: true,
      sourceBall: source,
      targetBall: target,
      resultBall: target.copyWith(
        chars: combined,
        type: isComplete ? BallType.completeWord : BallType.wordInProgress,
        mergeProgress: progress,
        mergeTotal: word.fragments.length,
        mergedFrom: [...target.mergedFrom, source.id],
        isOnBoard: !isComplete,
        isInTray: isComplete,
      ),
      removedBallIds: [source.id],
      completedWordId: isComplete ? word.id : null,
      movesToDeduct: 1,
    );
  }

  String? _bestCombination(String a, String b, String fullWord) {
    for (final c in ['$a$b', '$b$a']) {
      if (c == fullWord || fullWord.startsWith(c)) return c;
    }
    return null;
  }

  int _countMergedFragments(String combined, word) {
    var count = 0;
    for (final f in word.fragments) {
      if (combined.contains(f)) count++;
    }
    return count.clamp(1, word.fragments.length).toInt();
  }
}
