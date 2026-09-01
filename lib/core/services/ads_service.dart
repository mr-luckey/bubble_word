import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';
import 'network_guard.dart';

enum RewardedAdOutcome { earned, skipped, unavailable }

/// Central AdMob manager. Placement-based IDs. No waterfall. Offline = idle.
class AdsService {
  AdsService({
    AdsConfig config = const AdsConfig(),
    NetworkGuard? network,
  })  : _config = config,
        _network = network ?? NetworkGuard();

  final AdsConfig _config;
  final NetworkGuard _network;

  bool _sdkInitialized = false;
  bool _initializing = false;
  bool _fullScreenShowing = false;
  DateTime? _lastFullScreenAt;

  InterstitialAd? _interstitial;
  String? _interstitialPlacement;
  RewardedAd? _rewarded;
  String? _rewardedPlacement;

  int _interstitialAttempts = 0;
  int _rewardedAttempts = 0;
  Timer? _interstitialRetry;
  Timer? _rewardedRetry;
  bool _started = false;

  final _resumeListeners = <VoidCallback>{};

  bool get isReady => _sdkInitialized;
  bool get isOnline => _network.isOnline;
  bool get isFullScreenShowing => _fullScreenShowing;
  bool get hasRewardedAd => _rewarded != null;

  @visibleForTesting
  DateTime? get lastFullScreenAt => _lastFullScreenAt;

  @visibleForTesting
  set lastFullScreenAt(DateTime? value) => _lastFullScreenAt = value;

  bool frequencyAllowsInterstitial([DateTime? now]) {
    final last = _lastFullScreenAt;
    if (last == null) return true;
    return (now ?? DateTime.now()).difference(last) >=
        _config.minimumInterstitialInterval;
  }

  void addResumeListener(VoidCallback callback) {
    _resumeListeners.add(callback);
  }

  void removeResumeListener(VoidCallback callback) {
    _resumeListeners.remove(callback);
  }

  Future<void> start() async {
    if (_started) {
      if (_network.isOnline) await _ensureSdk();
      return;
    }
    _started = true;
    await _network.start(onOnline: _onNetworkRestored);
    if (_network.isOnline) {
      await _ensureSdk();
    }
  }

  Future<void> dispose() async {
    _interstitialRetry?.cancel();
    _rewardedRetry?.cancel();
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
    _resumeListeners.clear();
    await _network.dispose();
  }

  /// Load a banner for one visible placement. Caller owns dispose.
  Future<BannerAd?> loadBanner({
    required String placement,
    required AdSize size,
  }) async {
    final unitId = _config.bannerUnitId(placement);
    if (unitId == null) return null;
    if (!await _canUseAds()) return null;
    try {
      final completer = Completer<BannerAd?>();
      final ad = BannerAd(
        adUnitId: unitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!completer.isCompleted) completer.complete(ad as BannerAd);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner no-fill/fail [$placement]: $error');
            ad.dispose();
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
      await ad.load();
      return completer.future.timeout(
        _config.requestTimeout,
        onTimeout: () {
          ad.dispose();
          return null;
        },
      );
    } catch (error, stack) {
      debugPrint('loadBanner failed: $error\n$stack');
      return null;
    }
  }

  Future<void> preloadInterstitial({
    String placement = AdsPlacements.interstitialAfterLevel,
  }) async {
    if (_interstitial != null && _interstitialPlacement == placement) return;
    final unitId = _config.interstitialUnitId(placement);
    if (unitId == null) return;
    if (!await _canUseAds()) return;
    if (_interstitialAttempts > _config.maxRetries) return;

    try {
      _interstitialRetry?.cancel();
      _interstitial?.dispose();
      _interstitial = null;
      final completer = Completer<InterstitialAd?>();
      await InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: completer.complete,
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial no-fill/fail [$placement]: $error');
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
      final ad = await completer.future.timeout(
        _config.requestTimeout,
        onTimeout: () => null,
      );
      if (ad == null) {
        _interstitialAttempts++;
        _scheduleInterstitialRetry(placement);
        return;
      }
      _interstitialAttempts = 0;
      _interstitialPlacement = placement;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) => _fullScreenShowing = true,
        onAdDismissedFullScreenContent: (ad) {
          _fullScreenShowing = false;
          _lastFullScreenAt = DateTime.now();
          ad.dispose();
          _interstitial = null;
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial show failed: $error');
          _fullScreenShowing = false;
          ad.dispose();
          _interstitial = null;
        },
      );
      _interstitial = ad;
    } catch (error, stack) {
      debugPrint('preloadInterstitial failed: $error\n$stack');
    }
  }

  /// Natural-break interstitial. Returns false if skipped (frequency, no fill).
  Future<bool> showInterstitial({
    String placement = AdsPlacements.interstitialAfterLevel,
  }) async {
    if (_fullScreenShowing) return false;
    if (!frequencyAllowsInterstitial()) return false;
    if (_interstitial == null || _interstitialPlacement != placement) {
      await preloadInterstitial(placement: placement);
    }
    final ad = _interstitial;
    if (ad == null) return false;
    try {
      await ad.show();
      return true;
    } catch (error, stack) {
      debugPrint('showInterstitial failed: $error\n$stack');
      ad.dispose();
      _interstitial = null;
      return false;
    }
  }

  Future<void> preloadRewarded({
    String placement = AdsPlacements.rewardedHint,
  }) async {
    if (_rewarded != null && _rewardedPlacement == placement) return;
    final unitId = _config.rewardedUnitId(placement);
    if (unitId == null) return;
    if (!await _canUseAds()) return;
    if (_rewardedAttempts > _config.maxRetries) return;

    try {
      _rewardedRetry?.cancel();
      _rewarded?.dispose();
      _rewarded = null;
      final completer = Completer<RewardedAd?>();
      await RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: completer.complete,
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded no-fill/fail [$placement]: $error');
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
      final ad = await completer.future.timeout(
        _config.requestTimeout,
        onTimeout: () => null,
      );
      if (ad == null) {
        _rewardedAttempts++;
        _scheduleRewardedRetry(placement);
        return;
      }
      _rewardedAttempts = 0;
      _rewardedPlacement = placement;
      _rewarded = ad;
    } catch (error, stack) {
      debugPrint('preloadRewarded failed: $error\n$stack');
    }
  }

  /// User-initiated only. Grant a reward only when [RewardedAdOutcome.earned].
  Future<RewardedAdOutcome> showRewarded({
    String placement = AdsPlacements.rewardedHint,
  }) async {
    if (_fullScreenShowing) return RewardedAdOutcome.unavailable;
    if (_rewarded == null || _rewardedPlacement != placement) {
      await preloadRewarded(placement: placement);
    }
    final ad = _rewarded;
    if (ad == null) return RewardedAdOutcome.unavailable;

    final completer = Completer<RewardedAdOutcome>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _fullScreenShowing = true,
      onAdDismissedFullScreenContent: (ad) {
        _fullScreenShowing = false;
        _lastFullScreenAt = DateTime.now();
        ad.dispose();
        _rewarded = null;
        if (!completer.isCompleted) {
          completer.complete(
            earned ? RewardedAdOutcome.earned : RewardedAdOutcome.skipped,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded show failed: $error');
        _fullScreenShowing = false;
        ad.dispose();
        _rewarded = null;
        if (!completer.isCompleted) {
          completer.complete(RewardedAdOutcome.unavailable);
        }
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
        },
      );
      return completer.future;
    } catch (error, stack) {
      debugPrint('showRewarded failed: $error\n$stack');
      ad.dispose();
      _rewarded = null;
      return RewardedAdOutcome.unavailable;
    }
  }

  void _onNetworkRestored() {
    _interstitialAttempts = 0;
    _rewardedAttempts = 0;
    unawaited(_ensureSdk());
    for (final callback in List<VoidCallback>.of(_resumeListeners)) {
      callback();
    }
  }

  Future<bool> _canUseAds() async {
    if (!_config.isEnabled) return false;
    if (!_started) await start();
    if (!_network.isOnline) return false;
    return _ensureSdk();
  }

  Future<bool> _ensureSdk() async {
    if (_sdkInitialized) return true;
    if (!_network.isOnline || !_config.isEnabled) return false;
    if (_initializing) return _sdkInitialized;
    _initializing = true;
    try {
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
    } catch (error, stack) {
      debugPrint('MobileAds.initialize failed: $error\n$stack');
      _sdkInitialized = false;
    } finally {
      _initializing = false;
    }
    return _sdkInitialized;
  }

  void _scheduleInterstitialRetry(String placement) {
    if (!_network.isOnline) return;
    if (_interstitialAttempts > _config.maxRetries) return;
    _interstitialRetry?.cancel();
    final delay = _config.retryBackoff * _interstitialAttempts;
    _interstitialRetry = Timer(delay, () {
      unawaited(preloadInterstitial(placement: placement));
    });
  }

  void _scheduleRewardedRetry(String placement) {
    if (!_network.isOnline) return;
    if (_rewardedAttempts > _config.maxRetries) return;
    _rewardedRetry?.cancel();
    final delay = _config.retryBackoff * _rewardedAttempts;
    _rewardedRetry = Timer(delay, () {
      unawaited(preloadRewarded(placement: placement));
    });
  }
}
