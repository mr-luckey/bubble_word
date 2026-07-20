class CalculateStarRating {
  int call({required int movesLeft, required int movesTotal}) {
    if (movesTotal <= 0) return 1;
    final remaining = movesLeft / movesTotal;
    if (remaining >= 0.3) return 3;
    if (remaining >= 0.1) return 2;
    return 1;
  }

  int coinRewardForStars(int stars) {
    switch (stars) {
      case 3:
        return 50;
      case 2:
        return 25;
      default:
        return 10;
    }
  }
}
