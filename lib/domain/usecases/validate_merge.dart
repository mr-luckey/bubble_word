import '../entities/ball.dart';
import '../entities/enums.dart';
import '../entities/level.dart';
import '../entities/word.dart';

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

    final match = _findMatchingWord(source, target, level);
    if (match == null) return null;

    final word = match.word;
    final combined = match.combined;
    final progress = _countMergedFragments(combined, word);
    final isComplete = combined == word.text;

    return MergeResult(
      success: true,
      isCorrect: true,
      sourceBall: source,
      targetBall: target,
      resultBall: target.copyWith(
        chars: combined,
        wordId: word.id,
        category: level.category,
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

  _WordMatch? _findMatchingWord(Ball source, Ball target, Level level) {
    final preferred = <String>[];

    for (final ball in [target, source]) {
      if (ball.type == BallType.wordInProgress) {
        preferred.add(ball.wordId);
      }
    }
    for (final ball in [target, source]) {
      if (ball.type == BallType.fragment && !preferred.contains(ball.wordId)) {
        preferred.add(ball.wordId);
      }
    }

    for (final wordId in preferred) {
      final word = _wordById(level, wordId);
      if (word == null) continue;
      final combined = _bestCombination(target.chars, source.chars, word.text);
      if (combined != null) return _WordMatch(word, combined);
    }

    for (final word in level.words) {
      if (preferred.contains(word.id)) continue;
      final combined = _bestCombination(target.chars, source.chars, word.text);
      if (combined != null) return _WordMatch(word, combined);
    }

    return null;
  }

  Word? _wordById(Level level, String id) {
    for (final word in level.words) {
      if (word.id == id) return word;
    }
    return null;
  }

  String? _bestCombination(String a, String b, String fullWord) {
    for (final c in ['$a$b', '$b$a']) {
      if (c == fullWord || fullWord.startsWith(c)) return c;
    }
    return null;
  }

  int _countMergedFragments(String combined, Word word) {
    var count = 0;
    for (final f in word.fragments) {
      if (combined.contains(f)) count++;
    }
    return count.clamp(1, word.fragments.length).toInt();
  }
}

class _WordMatch {
  const _WordMatch(this.word, this.combined);
  final Word word;
  final String combined;
}
