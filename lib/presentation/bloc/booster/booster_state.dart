part of 'booster_bloc.dart';

class BoosterBlocState extends Equatable {
  const BoosterBlocState({this.activeBooster, this.message});

  final BoosterType? activeBooster;
  final String? message;

  @override
  List<Object?> get props => [activeBooster, message];
}
