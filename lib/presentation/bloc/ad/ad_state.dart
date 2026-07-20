part of 'ad_bloc.dart';

sealed class AdBlocState extends Equatable {
  const AdBlocState();

  @override
  List<Object?> get props => [];
}

class AdInitial extends AdBlocState {
  const AdInitial();
}

class AdReady extends AdBlocState {
  const AdReady();
}

class AdShowing extends AdBlocState {
  const AdShowing();
}

class AdComplete extends AdBlocState {
  const AdComplete({required this.rewarded});
  final bool rewarded;

  @override
  List<Object?> get props => [rewarded];
}

class AdError extends AdBlocState {
  const AdError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
