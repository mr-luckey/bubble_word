import '../../domain/entities/enums.dart';
import '../../domain/entities/level.dart';
import '../../domain/entities/word.dart';

class WordModel {
  const WordModel({
    required this.word,
    required this.balls,
    required this.ballCount,
  });

  final String word;
  final List<String> balls;
  final int ballCount;

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      word: json['word'] as String,
      balls: (json['balls'] as List<dynamic>).cast<String>(),
      ballCount: json['ball_count'] as int,
    );
  }

  Word toEntity() => Word(
        id: word,
        text: word,
        fragments: balls,
      );
}

class LevelModel {
  const LevelModel({
    required this.level,
    required this.hint,
    required this.category,
    required this.difficulty,
    required this.wordCount,
    required this.words,
  });

  final int level;
  final String hint;
  final String category;
  final String difficulty;
  final int wordCount;
  final List<WordModel> words;

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      level: json['level'] as int,
      hint: json['hint'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      wordCount: json['word_count'] as int,
      words: (json['words'] as List<dynamic>)
          .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Level toEntity({required int moveBudget}) => Level(
        id: level,
        hint: hint,
        category: category,
        difficulty: Difficulty.fromString(difficulty),
        words: words.map((w) => w.toEntity()).toList(),
        moveBudget: moveBudget,
        wordCount: wordCount,
      );
}

class LevelsFileModel {
  const LevelsFileModel({
    required this.game,
    required this.version,
    required this.totalLevels,
    required this.levels,
  });

  final String game;
  final String version;
  final int totalLevels;
  final List<LevelModel> levels;

  factory LevelsFileModel.fromJson(Map<String, dynamic> json) {
    return LevelsFileModel(
      game: json['game'] as String,
      version: json['version'] as String,
      totalLevels: json['total_levels'] as int,
      levels: (json['levels'] as List<dynamic>)
          .map((e) => LevelModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
