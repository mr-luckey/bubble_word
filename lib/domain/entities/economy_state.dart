import 'package:equatable/equatable.dart';

import '../../core/constants/game_constants.dart';

class BoosterInventory extends Equatable {
  const BoosterInventory({
    this.hint = 3,
    this.magnet = 1,
    this.addBall = 1,
    this.magicWand = 1,
    this.extraMoves = 0,
    this.freeHintUsedThisLevel = false,
    this.freeAddBallUsedThisLevel = false,
    this.freeExtraMovesUsedThisLevel = false,
  });

  final int hint;
  final int magnet;
  final int addBall;
  final int magicWand;
  final int extraMoves;
  final bool freeHintUsedThisLevel;
  final bool freeAddBallUsedThisLevel;
  final bool freeExtraMovesUsedThisLevel;

  BoosterInventory copyWith({
    int? hint,
    int? magnet,
    int? addBall,
    int? magicWand,
    int? extraMoves,
    bool? freeHintUsedThisLevel,
    bool? freeAddBallUsedThisLevel,
    bool? freeExtraMovesUsedThisLevel,
  }) {
    return BoosterInventory(
      hint: hint ?? this.hint,
      magnet: magnet ?? this.magnet,
      addBall: addBall ?? this.addBall,
      magicWand: magicWand ?? this.magicWand,
      extraMoves: extraMoves ?? this.extraMoves,
      freeHintUsedThisLevel:
          freeHintUsedThisLevel ?? this.freeHintUsedThisLevel,
      freeAddBallUsedThisLevel:
          freeAddBallUsedThisLevel ?? this.freeAddBallUsedThisLevel,
      freeExtraMovesUsedThisLevel:
          freeExtraMovesUsedThisLevel ?? this.freeExtraMovesUsedThisLevel,
    );
  }

  BoosterInventory resetLevelFlags() => copyWith(
        freeHintUsedThisLevel: false,
        freeAddBallUsedThisLevel: false,
        freeExtraMovesUsedThisLevel: false,
      );

  @override
  List<Object?> get props => [
        hint,
        magnet,
        addBall,
        magicWand,
        extraMoves,
        freeHintUsedThisLevel,
        freeAddBallUsedThisLevel,
        freeExtraMovesUsedThisLevel,
      ];
}

class EconomyState extends Equatable {
  const EconomyState({
    this.lives = GameConstants.maxHearts,
    this.maxLives = GameConstants.maxHearts,
    this.lifeRefillSeconds = 0,
    this.goldenHearts = GameConstants.maxGoldenHearts,
    this.maxGoldenHearts = GameConstants.maxGoldenHearts,
    this.goldenHeartRefillSeconds = 0,
    this.dailyStreak = 0,
    this.levelsCompletedSinceAd = 0,
    this.noAdsPurchased = false,
    this.currentLevel = 1,
    this.levelStars = const {},
    this.boosters = const BoosterInventory(),
  });

  final int lives;
  final int maxLives;
  final int lifeRefillSeconds;
  final int goldenHearts;
  final int maxGoldenHearts;
  final int goldenHeartRefillSeconds;
  final int dailyStreak;
  final int levelsCompletedSinceAd;
  final bool noAdsPurchased;
  final int currentLevel;
  final Map<int, int> levelStars;
  final BoosterInventory boosters;

  EconomyState copyWith({
    int? lives,
    int? maxLives,
    int? lifeRefillSeconds,
    int? goldenHearts,
    int? maxGoldenHearts,
    int? goldenHeartRefillSeconds,
    int? dailyStreak,
    int? levelsCompletedSinceAd,
    bool? noAdsPurchased,
    int? currentLevel,
    Map<int, int>? levelStars,
    BoosterInventory? boosters,
  }) {
    return EconomyState(
      lives: lives ?? this.lives,
      maxLives: maxLives ?? this.maxLives,
      lifeRefillSeconds: lifeRefillSeconds ?? this.lifeRefillSeconds,
      goldenHearts: goldenHearts ?? this.goldenHearts,
      maxGoldenHearts: maxGoldenHearts ?? this.maxGoldenHearts,
      goldenHeartRefillSeconds:
          goldenHeartRefillSeconds ?? this.goldenHeartRefillSeconds,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      levelsCompletedSinceAd:
          levelsCompletedSinceAd ?? this.levelsCompletedSinceAd,
      noAdsPurchased: noAdsPurchased ?? this.noAdsPurchased,
      currentLevel: currentLevel ?? this.currentLevel,
      levelStars: levelStars ?? this.levelStars,
      boosters: boosters ?? this.boosters,
    );
  }

  @override
  List<Object?> get props => [
        lives,
        maxLives,
        lifeRefillSeconds,
        goldenHearts,
        maxGoldenHearts,
        goldenHeartRefillSeconds,
        dailyStreak,
        levelsCompletedSinceAd,
        noAdsPurchased,
        currentLevel,
        levelStars,
        boosters,
      ];
}
