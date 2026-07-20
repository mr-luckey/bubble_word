part of 'economy_bloc.dart';

class EconomyBlocState extends Equatable {
  const EconomyBlocState(this.economy);

  final EconomyState economy;

  @override
  List<Object?> get props => [economy];
}
