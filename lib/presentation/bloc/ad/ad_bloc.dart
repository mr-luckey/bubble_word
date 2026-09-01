import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/ads_config.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/services/analytics_service.dart';

part 'ad_event.dart';
part 'ad_state.dart';

/// Fullscreen ads facade over [AdsService].
/// One named placement per request — never a unit-ID waterfall.
class AdBloc extends Bloc<AdEvent, AdBlocState> {
  AdBloc({
    required AdsService ads,
    required AnalyticsService analytics,
  })  : _ads = ads,
        _analytics = analytics,
        super(const AdInitial()) {
    on<InitializeAds>(_onInit);
    on<ShowRewardedAd>(_onRewarded);
    on<ShowInterstitialAd>(_onInterstitial);
    on<PreloadAdPlacement>(_onPreload);
  }

  final AdsService _ads;
  final AnalyticsService _analytics;

  Future<void> _onInit(InitializeAds event, Emitter<AdBlocState> emit) async {
    try {
      await _ads.start();
    } catch (_) {
      // Ads unavailable — game continues without them.
    }
    emit(const AdReady());
  }

  Future<void> _onPreload(
    PreloadAdPlacement event,
    Emitter<AdBlocState> emit,
  ) async {
    try {
      switch (event.format) {
        case AdFormat.interstitial:
          await _ads.preloadInterstitial(placement: event.placement);
        case AdFormat.rewarded:
          await _ads.preloadRewarded(placement: event.placement);
      }
    } catch (_) {
      // Preload is best-effort.
    }
  }

  Future<void> _onRewarded(
    ShowRewardedAd event,
    Emitter<AdBlocState> emit,
  ) async {
    if (_ads.isFullScreenShowing) return;
    emit(const AdShowing());
    try {
      final outcome = await _ads.showRewarded(placement: event.placement);
      switch (outcome) {
        case RewardedAdOutcome.earned:
          _analytics.logRewardedAdCompleted(
            placement: event.placement,
            source: 'user',
          );
          emit(const AdComplete(rewarded: true));
        case RewardedAdOutcome.skipped:
          emit(const AdComplete(rewarded: false));
        case RewardedAdOutcome.unavailable:
          emit(const AdError('Ad unavailable'));
      }
    } catch (_) {
      emit(const AdError('Ad unavailable'));
    }
    emit(const AdReady());
  }

  Future<void> _onInterstitial(
    ShowInterstitialAd event,
    Emitter<AdBlocState> emit,
  ) async {
    if (_ads.isFullScreenShowing) return;
    emit(const AdShowing());
    try {
      await _ads.showInterstitial(placement: event.placement);
    } catch (_) {
      // No-fill and frequency skips are legitimate. Gameplay continues.
    }
    emit(const AdComplete(rewarded: false));
    emit(const AdReady());
  }
}
