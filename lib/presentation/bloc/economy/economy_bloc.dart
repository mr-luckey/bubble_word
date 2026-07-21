import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/player_progress_datasource.dart';
import '../../../domain/entities/economy_state.dart';

part 'economy_event.dart';
part 'economy_state.dart';

class EconomyBloc extends Bloc<EconomyEvent, EconomyBlocState> {
  EconomyBloc(this._dataSource) : super(EconomyBlocState(EconomyState())) {
    on<LoadEconomy>(_onLoad);
    on<EarnCoins>(_onEarnCoins);
    on<SpendCoins>(_onSpendCoins);
    on<AddLife>(_onAddLife);
    on<SpendLife>(_onSpendLife);
    on<SetCurrentLevel>(_onSetLevel);
    on<RecordLevelStars>(_onRecordStars);
    on<IncrementLevelsCompleted>(_onIncrementLevels);
    on<ResetLevelsCompletedAd>(_onResetAdCounter);
    on<PurchaseNoAds>(_onPurchaseNoAds);
    on<TickLifeRefill>(_onTickRefill);
    on<UpdateBoosters>(_onUpdateBoosters);
    on<ResetLevelBoosterFlags>(_onResetBoosterFlags);
    add(const LoadEconomy());
    _refillTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TickLifeRefill());
    });
  }

  final PlayerProgressDataSource _dataSource;
  Timer? _refillTimer;

  Future<void> _onLoad(LoadEconomy event, Emitter<EconomyBlocState> emit) async {
    emit(EconomyBlocState(_dataSource.loadEconomy()));
  }

  Future<void> _persist(Emitter<EconomyBlocState> emit, EconomyState s) async {
    await _dataSource.saveEconomy(s);
    emit(EconomyBlocState(s));
  }

  Future<void> _onEarnCoins(EarnCoins event, Emitter<EconomyBlocState> emit) async {
    final s = state.economy.copyWith(coins: state.economy.coins + event.amount);
    await _persist(emit, s);
  }

  Future<void> _onSpendCoins(SpendCoins event, Emitter<EconomyBlocState> emit) async {
    if (state.economy.coins < event.amount) return;
    final s = state.economy.copyWith(coins: state.economy.coins - event.amount);
    await _persist(emit, s);
  }

  Future<void> _onAddLife(AddLife event, Emitter<EconomyBlocState> emit) async {
    final lives = (state.economy.lives + event.count).clamp(0, state.economy.maxLives);
    final s = state.economy.copyWith(lives: lives);
    await _persist(emit, s);
  }

  Future<void> _onSpendLife(SpendLife event, Emitter<EconomyBlocState> emit) async {
    if (state.economy.lives <= 0) return;
    final s = state.economy.copyWith(
      lives: state.economy.lives - 1,
      lifeRefillSeconds: state.economy.lives - 1 < state.economy.maxLives ? 1800 : 0,
    );
    await _persist(emit, s);
  }

  Future<void> _onSetLevel(SetCurrentLevel event, Emitter<EconomyBlocState> emit) async {
    final s = state.economy.copyWith(currentLevel: event.level);
    await _persist(emit, s);
  }

  Future<void> _onRecordStars(RecordLevelStars event, Emitter<EconomyBlocState> emit) async {
    final stars = Map<int, int>.from(state.economy.levelStars);
    final existing = stars[event.levelId] ?? 0;
    if (event.stars > existing) {
      stars[event.levelId] = event.stars;
    }
    final nextLevel = event.levelId + 1;
    final cappedNext = nextLevel > 1001 ? 1001 : nextLevel;
    final s = state.economy.copyWith(
      levelStars: stars,
      currentLevel: cappedNext > state.economy.currentLevel
          ? cappedNext
          : state.economy.currentLevel,
    );
    await _persist(emit, s);
  }

  Future<void> _onIncrementLevels(IncrementLevelsCompleted event, Emitter<EconomyBlocState> emit) async {
    final s = state.economy.copyWith(
      levelsCompletedSinceAd: state.economy.levelsCompletedSinceAd + 1,
    );
    await _persist(emit, s);
  }

  Future<void> _onResetAdCounter(ResetLevelsCompletedAd event, Emitter<EconomyBlocState> emit) async {
    final s = state.economy.copyWith(levelsCompletedSinceAd: 0);
    await _persist(emit, s);
  }

  Future<void> _onPurchaseNoAds(PurchaseNoAds event, Emitter<EconomyBlocState> emit) async {
    final s = state.economy.copyWith(noAdsPurchased: true);
    await _persist(emit, s);
  }

  Future<void> _onTickRefill(TickLifeRefill event, Emitter<EconomyBlocState> emit) async {
    if (state.economy.lives >= state.economy.maxLives) return;
    var secs = state.economy.lifeRefillSeconds;
    if (secs <= 0) {
      final s = state.economy.copyWith(lives: state.economy.lives + 1, lifeRefillSeconds: 1800);
      await _persist(emit, s);
      return;
    }
    secs--;
    final s = state.economy.copyWith(lifeRefillSeconds: secs);
    await _persist(emit, s);
  }

  Future<void> _onUpdateBoosters(UpdateBoosters event, Emitter<EconomyBlocState> emit) async {
    final s = state.economy.copyWith(boosters: event.boosters);
    await _persist(emit, s);
  }

  Future<void> _onResetBoosterFlags(ResetLevelBoosterFlags event, Emitter<EconomyBlocState> emit) async {
    final s = state.economy.copyWith(boosters: state.economy.boosters.resetLevelFlags());
    await _persist(emit, s);
  }

  @override
  Future<void> close() {
    _refillTimer?.cancel();
    return super.close();
  }
}
