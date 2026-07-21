enum BallType {
  fragment,
  wordInProgress,
  completeWord,
  superBall,
  junk,
  decoy,
  hintGhost,
}

enum GamePhase {
  buildingWords,
  mergingWords,
  won,
  failed,
}

enum MergeFeedback {
  none,
  correct,
  wrong,
}

enum Difficulty {
  easy,
  medium,
  hard,
  expert,
  master;

  static Difficulty fromString(String value) {
    return Difficulty.values.firstWhere(
      (d) => d.name == value.toLowerCase(),
      orElse: () => Difficulty.easy,
    );
  }

  double get moveMultiplier {
    switch (this) {
      case Difficulty.easy:
        return 2.5;
      case Difficulty.medium:
        return 2.0;
      case Difficulty.hard:
        return 1.7;
      case Difficulty.expert:
        return 1.5;
      case Difficulty.master:
        return 1.3;
    }
  }
}

enum FailReason {
  timeOut,
  boardOverload,
}

enum BoosterType {
  hint,
  magnet,
  addBall,
  magicWand,
  extraMoves,
}
