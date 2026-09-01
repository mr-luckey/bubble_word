part of 'ad_bloc.dart';

enum AdFormat { interstitial, rewarded }

sealed class AdEvent extends Equatable {
  const AdEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAds extends AdEvent {
  const InitializeAds();
}

class PreloadAdPlacement extends AdEvent {
  const PreloadAdPlacement({
    required this.format,
    required this.placement,
  });

  final AdFormat format;
  final String placement;

  @override
  List<Object?> get props => [format, placement];
}

class ShowRewardedAd extends AdEvent {
  const ShowRewardedAd({
    this.placement = AdsPlacements.rewardedHint,
  });

  final String placement;

  @override
  List<Object?> get props => [placement];
}

class ShowInterstitialAd extends AdEvent {
  const ShowInterstitialAd({
    this.placement = AdsPlacements.interstitialAfterLevel,
  });

  final String placement;

  @override
  List<Object?> get props => [placement];
}
