import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/constants/ad_constants.dart';

part 'ad_event.dart';
part 'ad_state.dart';

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

  static const rewardedTestId = AdConstants.rewardedTestId;
  static const interstitialTestId = AdConstants.interstitialTestId;

  Future<void> _onInit(InitializeAds event, Emitter<AdBlocState> emit) async {
    await MobileAds.instance.initialize();
    emit(const AdReady());
    _loadRewarded();
    _loadInterstitial();
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: rewardedTestId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialTestId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  Future<void> _onRewarded(ShowRewardedAd event, Emitter<AdBlocState> emit) async {
    emit(const AdShowing());
    final ad = _rewardedAd;
    if (ad == null) {
      add(const AdCompleted(rewarded: true));
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        add(AdFailed(e.message));
      },
    );
    await ad.show(onUserEarnedReward: (_, __) {
      add(const AdCompleted(rewarded: true));
    });
  }

  Future<void> _onInterstitial(ShowInterstitialAd event, Emitter<AdBlocState> emit) async {
    emit(const AdShowing());
    final ad = _interstitialAd;
    if (ad == null) {
      add(const AdCompleted(rewarded: false));
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
        add(const AdCompleted(rewarded: false));
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        add(AdFailed(e.message));
      },
    );
    await ad.show();
  }

  void _onCompleted(AdCompleted event, Emitter<AdBlocState> emit) {
    emit(AdComplete(rewarded: event.rewarded));
    emit(const AdReady());
  }

  void _onFailed(AdFailed event, Emitter<AdBlocState> emit) {
    emit(AdError(event.message));
    emit(const AdReady());
  }
}
