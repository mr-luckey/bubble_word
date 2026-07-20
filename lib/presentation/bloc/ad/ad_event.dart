part of 'ad_bloc.dart';

sealed class AdEvent extends Equatable {
  const AdEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAds extends AdEvent {
  const InitializeAds();
}

class ShowRewardedAd extends AdEvent {
  const ShowRewardedAd();
}

class ShowInterstitialAd extends AdEvent {
  const ShowInterstitialAd();
}

class AdCompleted extends AdEvent {
  const AdCompleted({required this.rewarded});
  final bool rewarded;

  @override
  List<Object?> get props => [rewarded];
}

class AdFailed extends AdEvent {
  const AdFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
