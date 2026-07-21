import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_word/domain/entities/enums.dart';
import 'package:bubble_word/domain/entities/level.dart';
import 'package:bubble_word/domain/entities/word.dart';
import 'package:bubble_word/domain/usecases/calculate_move_budget.dart';
import 'package:bubble_word/domain/usecases/calculate_star_rating.dart';
import 'package:bubble_word/domain/usecases/validate_merge.dart';
import 'package:bubble_word/domain/entities/ball.dart';
import 'package:bubble_word/core/utils/decoy_ball_generator.dart';
import 'package:bubble_word/data/models/level_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('CalculateMoveBudget', () {
    test('Level 1 easy budget is 20 moves', () {
      const level = Level(
        id: 1,
        hint: 'Find 3 colors',
        category: 'Colors',
        difficulty: Difficulty.easy,
        wordCount: 3,
        moveBudget: 0,
        words: [
          Word(id: 'RED', text: 'RED', fragments: ['RE', 'D']),
          Word(id: 'BLUE', text: 'BLUE', fragments: ['BL', 'UE']),
          Word(id: 'GREEN', text: 'GREEN', fragments: ['GR', 'EE', 'N']),
        ],
      );
      final budget = CalculateMoveBudget().call(level);
      expect(budget, 20);
    });
  });

  group('CalculateStarRating', () {
    test('returns 3 stars when 30%+ time remains', () {
      final rating =
          CalculateStarRating().call(timeLeftSeconds: 60, timeTotalSeconds: 90);
      expect(rating, 3);
    });

    test('returns 2 stars when 10-30% time remains', () {
      final rating =
          CalculateStarRating().call(timeLeftSeconds: 15, timeTotalSeconds: 90);
      expect(rating, 2);
    });

    test('returns 1 star when less than 10% remains', () {
      final rating =
          CalculateStarRating().call(timeLeftSeconds: 5, timeTotalSeconds: 90);
      expect(rating, 1);
    });
  });

  group('ValidateMerge', () {
    late Level level;

    setUp(() {
      level = const Level(
        id: 1,
        hint: 'Find 3 colors',
        category: 'Colors',
        difficulty: Difficulty.easy,
        wordCount: 3,
        moveBudget: 20,
        words: [
          Word(id: 'RED', text: 'RED', fragments: ['RE', 'D']),
          Word(id: 'BLUE', text: 'BLUE', fragments: ['BL', 'UE']),
        ],
      );
    });

    test('correct merge forms RED', () {
      final validate = ValidateMerge();
      final result = validate(
        source: const Ball(
          id: 's',
          chars: 'D',
          type: BallType.fragment,
          wordId: 'RED',
          category: 'Colors',
        ),
        target: const Ball(
          id: 't',
          chars: 'RE',
          type: BallType.fragment,
          wordId: 'RED',
          category: 'Colors',
        ),
        level: level,
        phase: GamePhase.buildingWords,
      );
      expect(result?.isCorrect, true);
      expect(result?.resultBall.chars, 'RED');
      expect(result?.completedWordId, 'RED');
    });

    test('wrong merge is rejected (returns null)', () {
      final validate = ValidateMerge();
      final result = validate(
        source: const Ball(
          id: 's',
          chars: 'BL',
          type: BallType.fragment,
          wordId: 'BLUE',
          category: 'Colors',
        ),
        target: const Ball(
          id: 't',
          chars: 'RE',
          type: BallType.fragment,
          wordId: 'RED',
          category: 'Colors',
        ),
        level: level,
        phase: GamePhase.buildingWords,
      );
      expect(result, isNull);
    });

    test('decoy balls cannot merge', () {
      final validate = ValidateMerge();
      final result = validate(
        source: const Ball(
          id: 's',
          chars: 'XY',
          type: BallType.decoy,
          wordId: 'decoy',
          category: 'Colors',
        ),
        target: const Ball(
          id: 't',
          chars: 'RE',
          type: BallType.fragment,
          wordId: 'RED',
          category: 'Colors',
        ),
        level: level,
        phase: GamePhase.buildingWords,
      );
      expect(result, isNull);
    });

    test('merges by letters across different word balls (APPLE/GRAPE)', () {
      const fruitsLevel = Level(
        id: 2,
        hint: 'Find 3 fruits',
        category: 'Fruits',
        difficulty: Difficulty.easy,
        wordCount: 3,
        moveBudget: 20,
        words: [
          Word(id: 'APPLE', text: 'APPLE', fragments: ['AP', 'PL', 'E']),
          Word(id: 'MANGO', text: 'MANGO', fragments: ['MA', 'NG', 'O']),
          Word(id: 'GRAPE', text: 'GRAPE', fragments: ['GR', 'AP', 'E']),
        ],
      );
      final validate = ValidateMerge();

      final grapeStart = validate(
        source: const Ball(
          id: 'ap_apple',
          chars: 'AP',
          type: BallType.fragment,
          wordId: 'APPLE',
          category: 'Fruits',
        ),
        target: const Ball(
          id: 'gr',
          chars: 'GR',
          type: BallType.fragment,
          wordId: 'GRAPE',
          category: 'Fruits',
        ),
        level: fruitsLevel,
        phase: GamePhase.buildingWords,
      );
      expect(grapeStart?.isCorrect, true);
      expect(grapeStart?.resultBall.chars, 'GRAP');
      expect(grapeStart?.resultBall.wordId, 'GRAPE');

      final appleMerge = validate(
        source: const Ball(
          id: 'pl',
          chars: 'PL',
          type: BallType.fragment,
          wordId: 'APPLE',
          category: 'Fruits',
        ),
        target: const Ball(
          id: 'ap_grape',
          chars: 'AP',
          type: BallType.fragment,
          wordId: 'GRAPE',
          category: 'Fruits',
        ),
        level: fruitsLevel,
        phase: GamePhase.buildingWords,
      );
      expect(appleMerge?.isCorrect, true);
      expect(appleMerge?.resultBall.chars, 'APPL');
      expect(appleMerge?.resultBall.wordId, 'APPLE');
    });
  });

  group('DecoyBallGenerator', () {
    test('adds decoys for level 1 without conflicting fragments', () {
      const level = Level(
        id: 1,
        hint: 'Find 3 colors',
        category: 'Colors',
        difficulty: Difficulty.easy,
        wordCount: 3,
        moveBudget: 20,
        words: [
          Word(id: 'RED', text: 'RED', fragments: ['RE', 'D']),
          Word(id: 'BLUE', text: 'BLUE', fragments: ['BL', 'UE']),
          Word(id: 'GREEN', text: 'GREEN', fragments: ['GR', 'EE', 'N']),
        ],
      );
      final decoys = DecoyBallGenerator.generate(level, const Uuid());
      expect(decoys.length, greaterThanOrEqualTo(16));
      expect(decoys.length, DecoyBallGenerator.countForLevel(level));
      for (final d in decoys) {
        expect(d.type, BallType.decoy);
        expect(d.chars.length, greaterThanOrEqualTo(2));
      }
    });
  });

  group('LevelModel', () {
    test('parses level json', () {
      final model = LevelModel.fromJson({
        'level': 1,
        'hint': 'Find 3 colors',
        'category': 'Colors',
        'difficulty': 'easy',
        'word_count': 3,
        'words': [
          {
            'word': 'RED',
            'balls': ['RE', 'D'],
            'ball_count': 2,
          },
        ],
      });
      expect(model.level, 1);
      expect(model.words.first.word, 'RED');
      expect(model.words.first.balls, ['RE', 'D']);
    });
  });
}
