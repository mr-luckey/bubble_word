part of 'booster_bloc.dart';

sealed class BoosterEvent extends Equatable {
  const BoosterEvent();

  @override
  List<Object?> get props => [];
}

class UseHint extends BoosterEvent {
  const UseHint();
}

class UseMagnet extends BoosterEvent {
  const UseMagnet(this.wordId);
  final String wordId;

  @override
  List<Object?> get props => [wordId];
}

class UseAddBall extends BoosterEvent {
  const UseAddBall();
}

class UseMagicWand extends BoosterEvent {
  const UseMagicWand();
}

class UseExtraMoves extends BoosterEvent {
  const UseExtraMoves();
}

class ClearBoosterMessage extends BoosterEvent {
  const ClearBoosterMessage();
}
