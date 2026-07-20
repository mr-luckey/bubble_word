import 'package:equatable/equatable.dart';
import 'enums.dart';

class Ball extends Equatable {
  const Ball({
    required this.id,
    required this.chars,
    required this.type,
    required this.wordId,
    required this.category,
    this.mergedFrom = const [],
    this.isCorrect = true,
    this.x = 0,
    this.y = 0,
    this.vx = 0,
    this.vy = 0,
    this.isDragging = false,
    this.isHighlighted = false,
    this.mergeProgress = 0,
    this.mergeTotal = 0,
    this.isOnBoard = true,
    this.isInTray = false,
  });

  final String id;
  final String chars;
  final BallType type;
  final String wordId;
  final String category;
  final List<String> mergedFrom;
  final bool isCorrect;
  final double x;
  final double y;
  final double vx;
  final double vy;
  final bool isDragging;
  final bool isHighlighted;
  final int mergeProgress;
  final int mergeTotal;
  final bool isOnBoard;
  final bool isInTray;

  /// Visual merge radius in logical pixels (matches [AppDimensions] ball sizes).
  double get radiusFactor {
    if (type == BallType.superBall) return 90;
    if (type == BallType.completeWord || type == BallType.wordInProgress) {
      return 46;
    }
    if (type == BallType.decoy || chars.length >= 3) return 34;
    return 28;
  }

  Ball copyWith({
    String? id,
    String? chars,
    BallType? type,
    String? wordId,
    String? category,
    List<String>? mergedFrom,
    bool? isCorrect,
    double? x,
    double? y,
    double? vx,
    double? vy,
    bool? isDragging,
    bool? isHighlighted,
    int? mergeProgress,
    int? mergeTotal,
    bool? isOnBoard,
    bool? isInTray,
  }) {
    return Ball(
      id: id ?? this.id,
      chars: chars ?? this.chars,
      type: type ?? this.type,
      wordId: wordId ?? this.wordId,
      category: category ?? this.category,
      mergedFrom: mergedFrom ?? this.mergedFrom,
      isCorrect: isCorrect ?? this.isCorrect,
      x: x ?? this.x,
      y: y ?? this.y,
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      isDragging: isDragging ?? this.isDragging,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      mergeProgress: mergeProgress ?? this.mergeProgress,
      mergeTotal: mergeTotal ?? this.mergeTotal,
      isOnBoard: isOnBoard ?? this.isOnBoard,
      isInTray: isInTray ?? this.isInTray,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chars,
        type,
        wordId,
        category,
        mergedFrom,
        isCorrect,
        x,
        y,
        vx,
        vy,
        isDragging,
        isHighlighted,
        mergeProgress,
        mergeTotal,
        isOnBoard,
        isInTray,
      ];
}
