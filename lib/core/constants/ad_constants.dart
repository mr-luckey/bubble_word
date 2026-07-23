/// AdMob unit IDs — waterfall lists (tried 1-by-1 until one loads).
///
/// Add as many production unit IDs as you want, in priority order.
/// Empty strings are ignored. Keep Google test IDs only while developing.
abstract final class AdConstants {
  // ── Rewarded (hint / extra lives, etc.) ─────────────────────────────
  static const List<String> rewardedUnitIds = [
    'ca-app-pub-5561438827097019/7298530346', // Google test — replace
    'ca-app-pub-5561438827097019/8109049133',
    'ca-app-pub-5561438827097019/2841124590',
    'ca-app-pub-5561438827097019/4481509328',
    'ca-app-pub-5561438827097019/6935568263',
  ];

  // ── Interstitial (every N levels / hint gate) ───────────────────────
  static const List<String> interstitialUnitIds = [
    'ca-app-pub-5561438827097019/5331556567', // Google test — replace
    'ca-app-pub-5561438827097019/4673081015',
    'ca-app-pub-5561438827097019/3359999344',
    'ca-app-pub-5561438827097019/4476925888',
    'ca-app-pub-5561438827097019/9190910529',
  ];

  // ── Banner (home / map) ─────────────────────────────────────────────
  static const List<String> bannerUnitIds = [
    'ca-app-pub-5561438827097019/7127139958', // Google test — replace
    'ca-app-pub-5561438827097019/5658859622',
    'ca-app-pub-5561438827097019/8612326029',
    'ca-app-pub-5561438827097019/4345777953',
    'ca-app-pub-5561438827097019/6364722626',
  ];

  /// Non-empty IDs only (safe for load loops).
  static List<String> get rewardedIds =>
      rewardedUnitIds.where((id) => id.trim().isNotEmpty).toList();

  static List<String> get interstitialIds =>
      interstitialUnitIds.where((id) => id.trim().isNotEmpty).toList();

  static List<String> get bannerIds =>
      bannerUnitIds.where((id) => id.trim().isNotEmpty).toList();
}
