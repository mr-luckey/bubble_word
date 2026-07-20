import 'package:equatable/equatable.dart';

class Word extends Equatable {
  const Word({
    required this.id,
    required this.text,
    required this.fragments,
    this.isComplete = false,
  });

  final String id;
  final String text;
  final List<String> fragments;
  final bool isComplete;

  Word copyWith({
    String? id,
    String? text,
    List<String>? fragments,
    bool? isComplete,
  }) {
    return Word(
      id: id ?? this.id,
      text: text ?? this.text,
      fragments: fragments ?? this.fragments,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  List<Object?> get props => [id, text, fragments, isComplete];
}
