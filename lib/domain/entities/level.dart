import 'package:equatable/equatable.dart';
import 'enums.dart';
import 'word.dart';

class Level extends Equatable {
  const Level({
    required this.id,
    required this.hint,
    required this.category,
    required this.difficulty,
    required this.words,
    required this.moveBudget,
    required this.wordCount,
  });

  final int id;
  final String hint;
  final String category;
  final Difficulty difficulty;
  final List<Word> words;
  final int moveBudget;
  final int wordCount;

  @override
  List<Object?> get props =>
      [id, hint, category, difficulty, words, moveBudget, wordCount];
}
