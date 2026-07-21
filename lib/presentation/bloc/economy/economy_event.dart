part of 'economy_bloc.dart';

sealed class EconomyEvent extends Equatable {
  const EconomyEvent();

  @override
  List<Object?> get props => [];
}

class LoadEconomy extends EconomyEvent {
  const LoadEconomy();
}

class EarnCoins extends EconomyEvent {
  const EarnCoins(this.amount);
  final int amount;

  @override
  List<Object?> get props => [amount];
}

class SpendCoins extends EconomyEvent {
  const SpendCoins(this.amount);
  final int amount;

  @override
  List<Object?> get props => [amount];
}

class AddLife extends EconomyEvent {
  const AddLife({this.count = 1});
  final int count;

  @override
  List<Object?> get props => [count];
}

class SpendLife extends EconomyEvent {
  const SpendLife();
}

class SetCurrentLevel extends EconomyEvent {
  const SetCurrentLevel(this.level);
  final int level;

  @override
  List<Object?> get props => [level];
}

class RecordLevelStars extends EconomyEvent {
  const RecordLevelStars({required this.levelId, required this.stars});
  final int levelId;
  final int stars;

  @override
  List<Object?> get props => [levelId, stars];
}

class CompleteLevel extends EconomyEvent {
  const CompleteLevel({
    required this.levelId,
    required this.stars,
    required this.coinsEarned,
  });

  final int levelId;
  final int stars;
  final int coinsEarned;

  @override
  List<Object?> get props => [levelId, stars, coinsEarned];
}

class IncrementLevelsCompleted extends EconomyEvent {
  const IncrementLevelsCompleted();
}

class ResetLevelsCompletedAd extends EconomyEvent {
  const ResetLevelsCompletedAd();
}

class PurchaseNoAds extends EconomyEvent {
  const PurchaseNoAds();
}

class TickLifeRefill extends EconomyEvent {
  const TickLifeRefill();
}

class UpdateBoosters extends EconomyEvent {
  const UpdateBoosters(this.boosters);
  final BoosterInventory boosters;

  @override
  List<Object?> get props => [boosters];
}

class ResetLevelBoosterFlags extends EconomyEvent {
  const ResetLevelBoosterFlags();
}
