import 'package:flutter/foundation.dart';

/// Official Google sample units. Use only when [AdsConfig.testMode] is true.
abstract final class GoogleTestAdUnits {
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const androidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const iosRewarded = 'ca-app-pub-3940256099942544/1712485313';
}

/// Named placements. Each maps to one index in the matching unit-ID list.
abstract final class AdsPlacements {
  static const home = 'home';
  static const game = 'game';
  static const result = 'result';
  static const splash = 'splash';
  static const daily = 'daily';

  static const interstitialAfterLevel = 'after_level_group';
  static const interstitialHintGate = 'hint_gate';

  static const rewardedHint = 'hint';
}

/// Central AdMob configuration. Never invent production IDs.
///
/// Unit lists hold up to five IDs. Placements map a screen/feature onto one
/// index. Empty strings disable that slot. There is no automatic fill waterfall.
class AdsConfig {
  const AdsConfig({
    this.isEnabled = true,
    this.testMode = kDebugMode,
    this.bannerEnabled = true,
    this.interstitialEnabled = true,
    this.rewardedEnabled = true,
    this.bannerAdUnits = const [],
    this.interstitialAdUnits = const [],
    this.rewardedAdUnits = const [],
    this.bannerPlacements = const {AdsPlacements.home: 0},
    this.interstitialPlacements = const {
      AdsPlacements.interstitialAfterLevel: 0,
    },
    this.rewardedPlacements = const {AdsPlacements.rewardedHint: 0},
    this.minimumInterstitialInterval = const Duration(minutes: 2),
    this.maxRetries = 2,
    this.retryBackoff = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 10),
  });

  final bool isEnabled;
  final bool testMode;
  final bool bannerEnabled;
  final bool interstitialEnabled;
  final bool rewardedEnabled;

  final List<String> bannerAdUnits;
  final List<String> interstitialAdUnits;
  final List<String> rewardedAdUnits;

  /// Placement name → index into the matching unit list.
  final Map<String, int> bannerPlacements;
  final Map<String, int> interstitialPlacements;
  final Map<String, int> rewardedPlacements;

  final Duration minimumInterstitialInterval;
  final int maxRetries;
  final Duration retryBackoff;
  final Duration requestTimeout;

  String? bannerUnitId(String placement) =>
      _unit(bannerAdUnits, bannerPlacements[placement], bannerEnabled);

  String? interstitialUnitId(String placement) => _unit(
        interstitialAdUnits,
        interstitialPlacements[placement],
        interstitialEnabled,
      );

  String? rewardedUnitId(String placement) =>
      _unit(rewardedAdUnits, rewardedPlacements[placement], rewardedEnabled);

  String? _unit(List<String> units, int? index, bool enabled) {
    if (!isEnabled || !enabled || index == null || index < 0) return null;
    if (testMode) return _testIdFor(units);
    if (index >= units.length) return null;
    final id = units[index].trim();
    return id.isEmpty ? null : id;
  }

  String _testIdFor(List<String> units) {
    if (identical(units, bannerAdUnits)) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? GoogleTestAdUnits.iosBanner
          : GoogleTestAdUnits.androidBanner;
    }
    if (identical(units, interstitialAdUnits)) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? GoogleTestAdUnits.iosInterstitial
          : GoogleTestAdUnits.androidInterstitial;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? GoogleTestAdUnits.iosRewarded
        : GoogleTestAdUnits.androidRewarded;
  }
}

/// Production unit IDs already present in this project. Debug/tests use
/// [GoogleTestAdUnits] via [AdsConfig.testMode] (`kDebugMode`).
const appAdsConfig = AdsConfig(
  isEnabled: true,
  testMode: kDebugMode,
  bannerEnabled: true,
  interstitialEnabled: true,
  rewardedEnabled: true,
  bannerAdUnits: [
    'ca-app-pub-6619866004331477/8901014331',
    'ca-app-pub-6619866004331477/2903793647',
    'ca-app-pub-6619866004331477/5640426177',
    'ca-app-pub-6619866004331477/9293942173',
    'ca-app-pub-6619866004331477/9277630302',
  ],
  interstitialAdUnits: [
    'ca-app-pub-6619866004331477/9388099492',
    'ca-app-pub-6619866004331477/5871903612',
    'ca-app-pub-6619866004331477/4041615496',
    'ca-app-pub-6619866004331477/8402320885',
    'ca-app-pub-6619866004331477/1022524313',
  ],
  rewardedAdUnits: [
    'ca-app-pub-6619866004331477/3927004777',
    'ca-app-pub-6619866004331477/7396360975',
    'ca-app-pub-6619866004331477/6570364465',
    'ca-app-pub-6619866004331477/6083279302',
    'ca-app-pub-6619866004331477/9619576935',
  ],
  bannerPlacements: {
    AdsPlacements.home: 0,
    AdsPlacements.game: 1,
    AdsPlacements.result: 2,
    AdsPlacements.splash: 3,
    AdsPlacements.daily: 4,
  },
  interstitialPlacements: {
    AdsPlacements.interstitialAfterLevel: 0,
    AdsPlacements.interstitialHintGate: 1,
  },
  rewardedPlacements: {
    AdsPlacements.rewardedHint: 0,
  },
  minimumInterstitialInterval: Duration(minutes: 2),
  maxRetries: 2,
  retryBackoff: Duration(seconds: 30),
);
