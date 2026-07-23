/// AdMob unit IDs — waterfall lists (tried 1-by-1 until one loads).
///
/// Add as many production unit IDs as you want, in priority order.
/// Empty strings are ignored. Keep Google test IDs only while developing.
abstract final class AdConstants {
  // ── Rewarded (hint / extra lives, etc.) ─────────────────────────────
  static const List<String> rewardedUnitIds = [
    'ca-app-pub-3940256099942544/5224354917', // Google test — replace
    // 'ca-app-pub-XXXX~YYYY/REWARDED_2',
    // 'ca-app-pub-XXXX~YYYY/REWARDED_3',
    // 'ca-app-pub-XXXX~YYYY/REWARDED_4',
    // 'ca-app-pub-XXXX~YYYY/REWARDED_5',
  ];

  // ── Interstitial (every N levels / hint gate) ───────────────────────
  static const List<String> interstitialUnitIds = [
    'ca-app-pub-3940256099942544/1033173712', // Google test — replace
    // 'ca-app-pub-XXXX~YYYY/INTERSTITIAL_2',
    // 'ca-app-pub-XXXX~YYYY/INTERSTITIAL_3',
    // 'ca-app-pub-XXXX~YYYY/INTERSTITIAL_4',
    // 'ca-app-pub-XXXX~YYYY/INTERSTITIAL_5',
  ];

  // ── Banner (home / map) ─────────────────────────────────────────────
  static const List<String> bannerUnitIds = [
    'ca-app-pub-3940256099942544/6300978111', // Google test — replace
    // 'ca-app-pub-XXXX~YYYY/BANNER_2',
    // 'ca-app-pub-XXXX~YYYY/BANNER_3',
  ];

  /// Non-empty IDs only (safe for load loops).
  static List<String> get rewardedIds =>
      rewardedUnitIds.where((id) => id.trim().isNotEmpty).toList();

  static List<String> get interstitialIds =>
      interstitialUnitIds.where((id) => id.trim().isNotEmpty).toList();

  static List<String> get bannerIds =>
      bannerUnitIds.where((id) => id.trim().isNotEmpty).toList();
}
