import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/constants/ad_constants.dart';

part 'ad_event.dart';
part 'ad_state.dart';

/// Fullscreen ads with multi-ID waterfall:
/// try unit IDs 1-by-1 until one loads; stop further loads once an ad is
/// ready or on-screen so the user never gets two fullscreen ads at once.
class AdBloc extends Bloc<AdEvent, AdBlocState> {
  AdBloc() : super(const AdInitial()) {
    on<InitializeAds>(_onInit);
    on<ShowRewardedAd>(_onRewarded);
    on<ShowInterstitialAd>(_onInterstitial);
    on<AdCompleted>(_onCompleted);
    on<AdFailed>(_onFailed);
  }

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _rewardEarned = false;

  /// True while a fullscreen ad is on screen (or loading specifically to show).
  bool _fullscreenBusy = false;

  /// Bumped to cancel in-flight waterfall callbacks.
  int _rewardedLoadGen = 0;
  int _interstitialLoadGen = 0;

  Future<void> _onInit(InitializeAds event, Emitter<AdBlocState> emit) async {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // Ads unavailable — game continues without them.
    }
    emit(const AdReady());
    _preloadRewarded();
    _preloadInterstitial();
  }

  void _safeAdd(AdEvent event) {
    if (!isClosed) add(event);
  }

  // ── Waterfall preload (stops at first success) ──────────────────────

  void _preloadRewarded() {
    if (isClosed || _fullscreenBusy || _rewardedAd != null) return;
    final ids = AdConstants.rewardedIds;
    if (ids.isEmpty) return;
    final gen = ++_rewardedLoadGen;
    _loadRewardedAt(0, ids, gen, forShow: false, onDone: (ad) {
      if (ad == null || _fullscreenBusy) {
        ad?.dispose();
        return;
      }
      _rewardedAd = ad;
    });
  }

  void _preloadInterstitial() {
    if (isClosed || _fullscreenBusy || _interstitialAd != null) return;
    final ids = AdConstants.interstitialIds;
    if (ids.isEmpty) return;
    final gen = ++_interstitialLoadGen;
    _loadInterstitialAt(0, ids, gen, forShow: false, onDone: (ad) {
      if (ad == null || _fullscreenBusy) {
        ad?.dispose();
        return;
      }
      _interstitialAd = ad;
    });
  }

  void _loadRewardedAt(
    int index,
    List<String> ids,
    int gen, {
    required bool forShow,
    required void Function(RewardedAd? ad) onDone,
  }) {
    if (isClosed || gen != _rewardedLoadGen) return;
    if (_fullscreenBusy && !forShow) {
      onDone(null);
      return;
    }
    if (index >= ids.length) {
      onDone(null);
      return;
    }

    RewardedAd.load(
      adUnitId: ids[index],
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (isClosed || gen != _rewardedLoadGen) {
            ad.dispose();
            return;
          }
          if (_fullscreenBusy && !forShow) {
            ad.dispose();
            onDone(null);
            return;
          }
          // First success — stop (do not request next index).
          onDone(ad);
        },
        onAdFailedToLoad: (_) {
          if (isClosed || gen != _rewardedLoadGen) return;
          _loadRewardedAt(
            index + 1,
            ids,
            gen,
            forShow: forShow,
            onDone: onDone,
          );
        },
      ),
    );
  }

  void _loadInterstitialAt(
    int index,
    List<String> ids,
    int gen, {
    required bool forShow,
    required void Function(InterstitialAd? ad) onDone,
  }) {
    if (isClosed || gen != _interstitialLoadGen) return;
    if (_fullscreenBusy && !forShow) {
      onDone(null);
      return;
    }
    if (index >= ids.length) {
      onDone(null);
      return;
    }

    InterstitialAd.load(
      adUnitId: ids[index],
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (isClosed || gen != _interstitialLoadGen) {
            ad.dispose();
            return;
          }
          if (_fullscreenBusy && !forShow) {
            ad.dispose();
            onDone(null);
            return;
          }
          onDone(ad);
        },
        onAdFailedToLoad: (_) {
          if (isClosed || gen != _interstitialLoadGen) return;
          _loadInterstitialAt(
            index + 1,
            ids,
            gen,
            forShow: forShow,
            onDone: onDone,
          );
        },
      ),
    );
  }

  // ── Show rewarded ───────────────────────────────────────────────────

  Future<void> _onRewarded(
    ShowRewardedAd event,
    Emitter<AdBlocState> emit,
  ) async {
    if (_fullscreenBusy) return;
    emit(const AdShowing());
    _fullscreenBusy = true;

    // Cancel competing preloads so a second ad cannot become ready mid-show.
    _rewardedLoadGen++;
    _interstitialLoadGen++;

    final ready = _rewardedAd;
    _rewardedAd = null;
    if (ready != null) {
      _presentRewarded(ready);
      return;
    }

    final ids = AdConstants.rewardedIds;
    final gen = _rewardedLoadGen;
    if (ids.isEmpty) {
      _fullscreenBusy = false;
      add(const AdCompleted(rewarded: true));
      return;
    }

    _loadRewardedAt(0, ids, gen, forShow: true, onDone: (ad) {
      if (ad == null) {
        _fullscreenBusy = false;
        _safeAdd(const AdCompleted(rewarded: true));
        _preloadRewarded();
        _preloadInterstitial();
        return;
      }
      _presentRewarded(ad);
    });
  }

  void _presentRewarded(RewardedAd ad) {
    _rewardEarned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _fullscreenBusy = false;
        if (!_rewardEarned) {
          _safeAdd(const AdCompleted(rewarded: false));
        }
        _preloadRewarded();
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        a.dispose();
        _fullscreenBusy = false;
        _safeAdd(AdFailed(error.message));
        _preloadRewarded();
        _preloadInterstitial();
      },
    );

    ad.show(
      onUserEarnedReward: (_, _) {
        _rewardEarned = true;
        _safeAdd(const AdCompleted(rewarded: true));
      },
    );
  }

  // ── Show interstitial ───────────────────────────────────────────────

  Future<void> _onInterstitial(
    ShowInterstitialAd event,
    Emitter<AdBlocState> emit,
  ) async {
    if (_fullscreenBusy) return;
    emit(const AdShowing());
    _fullscreenBusy = true;

    _rewardedLoadGen++;
    _interstitialLoadGen++;

    final ready = _interstitialAd;
    _interstitialAd = null;
    if (ready != null) {
      _presentInterstitial(ready);
      return;
    }

    final ids = AdConstants.interstitialIds;
    final gen = _interstitialLoadGen;
    if (ids.isEmpty) {
      _fullscreenBusy = false;
      add(const AdCompleted(rewarded: false));
      return;
    }

    _loadInterstitialAt(0, ids, gen, forShow: true, onDone: (ad) {
      if (ad == null) {
        _fullscreenBusy = false;
        _safeAdd(const AdCompleted(rewarded: false));
        _preloadRewarded();
        _preloadInterstitial();
        return;
      }
      _presentInterstitial(ad);
    });
  }

  void _presentInterstitial(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _fullscreenBusy = false;
        _safeAdd(const AdCompleted(rewarded: false));
        _preloadRewarded();
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        a.dispose();
        _fullscreenBusy = false;
        _safeAdd(AdFailed(error.message));
        _preloadRewarded();
        _preloadInterstitial();
      },
    );

    ad.show();
  }

  void _onCompleted(AdCompleted event, Emitter<AdBlocState> emit) {
    emit(AdComplete(rewarded: event.rewarded));
    emit(const AdReady());
  }

  void _onFailed(AdFailed event, Emitter<AdBlocState> emit) {
    emit(AdError(event.message));
    emit(const AdReady());
  }

  @override
  Future<void> close() {
    _rewardedLoadGen++;
    _interstitialLoadGen++;
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd = null;
    _interstitialAd = null;
    return super.close();
  }
}
