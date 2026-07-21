class CalculateStarRating {
  int call({required int timeLeftSeconds, required int timeTotalSeconds}) {
    if (timeTotalSeconds <= 0) return 1;
    final remaining = timeLeftSeconds / timeTotalSeconds;
    if (remaining >= 0.3) return 3;
    if (remaining >= 0.1) return 2;
    return 1;
  }
}
