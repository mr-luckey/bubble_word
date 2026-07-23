import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/game_constants.dart';
import '../../../data/datasources/player_progress_datasource.dart';
import '../../../domain/entities/economy_state.dart';

part 'economy_event.dart';
part 'economy_state.dart';

class EconomyBloc extends Bloc<EconomyEvent, EconomyBlocState> {
  EconomyBloc(this._dataSource)
      : super(EconomyBlocState(_dataSource.loadEconomy())) {
    on<LoadEconomy>(_onLoad);
    on<AddLife>(_onAddLife);
    on<SpendLife>(_onSpendLife);
    on<SpendGoldenHeart>(_onSpendGoldenHeart);
    on<SetCurrentLevel>(_onSetLevel);
    on<RecordLevelStars>(_onRecordStars);
    on<CompleteLevel>(_onCompleteLevel);
    on<IncrementLevelsCompleted>(_onIncrementLevels);
    on<ResetLevelsCompletedAd>(_onResetAdCounter);
    on<PurchaseNoAds>(_onPurchaseNoAds);
    on<TickLifeRefill>(_onTickRefill);
    on<UpdateBoosters>(_onUpdateBoosters);
    on<ResetLevelBoosterFlags>(_onResetBoosterFlags);
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

  Future<void> _onAddLife(AddLife event, Emitter<EconomyBlocState> emit) async {
    final lives =
        (state.economy.lives + event.count).clamp(0, state.economy.maxLives);
    final s = state.economy.copyWith(
      lives: lives,
      lifeRefillSeconds: lives >= state.economy.maxLives ? 0 : state.economy.lifeRefillSeconds,
    );
    await _persist(emit, s);
  }

  Future<void> _onSpendLife(SpendLife event, Emitter<EconomyBlocState> emit) async {
    if (state.economy.lives <= 0) return;
    final newLives = state.economy.lives - 1;
    final s = state.economy.copyWith(
      lives: newLives,
      lifeRefillSeconds: newLives < state.economy.maxLives
          ? GameConstants.heartRefillSeconds
          : 0,
    );
    await _persist(emit, s);
  }

  Future<void> _onSpendGoldenHeart(
    SpendGoldenHeart event,
    Emitter<EconomyBlocState> emit,
  ) async {
    if (state.economy.goldenHearts <= 0) return;
    final newGolden = state.economy.goldenHearts - 1;
    final s = state.economy.copyWith(
      goldenHearts: newGolden,
      goldenHeartRefillSeconds: newGolden < state.economy.maxGoldenHearts
          ? GameConstants.heartRefillSeconds
          : 0,
    );
    await _persist(emit, s);
  }

  Future<void> _onSetLevel(SetCurrentLevel event, Emitter<EconomyBlocState> emit) async {
    final s = state.economy.copyWith(currentLevel: event.level);
    await _persist(emit, s);
  }

  Future<void> _onRecordStars(
    RecordLevelStars event,
    Emitter<EconomyBlocState> emit,
  ) async {
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

  Future<void> _onCompleteLevel(
    CompleteLevel event,
    Emitter<EconomyBlocState> emit,
  ) async {
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
      levelsCompletedSinceAd: state.economy.levelsCompletedSinceAd + 1,
    );
    await _persist(emit, s);
  }

  Future<void> _onIncrementLevels(
    IncrementLevelsCompleted event,
    Emitter<EconomyBlocState> emit,
  ) async {
    final s = state.economy.copyWith(
      levelsCompletedSinceAd: state.economy.levelsCompletedSinceAd + 1,
    );
    await _persist(emit, s);
  }

  Future<void> _onResetAdCounter(
    ResetLevelsCompletedAd event,
    Emitter<EconomyBlocState> emit,
  ) async {
    final s = state.economy.copyWith(levelsCompletedSinceAd: 0);
    await _persist(emit, s);
  }

  Future<void> _onPurchaseNoAds(
    PurchaseNoAds event,
    Emitter<EconomyBlocState> emit,
  ) async {
    final s = state.economy.copyWith(noAdsPurchased: true);
    await _persist(emit, s);
  }

  Future<void> _onTickRefill(
    TickLifeRefill event,
    Emitter<EconomyBlocState> emit,
  ) async {
    var economy = state.economy;
    var changed = false;

    if (economy.lives >= economy.maxLives) {
      if (economy.lifeRefillSeconds != 0) {
        economy = economy.copyWith(lifeRefillSeconds: 0);
        changed = true;
      }
    } else {
      var secs = economy.lifeRefillSeconds;
      if (secs <= 0) {
        final newLives = economy.lives + 1;
        economy = economy.copyWith(
          lives: newLives,
          lifeRefillSeconds: newLives < economy.maxLives
              ? GameConstants.heartRefillSeconds
              : 0,
        );
        changed = true;
      } else {
        economy = economy.copyWith(lifeRefillSeconds: secs - 1);
        changed = true;
      }
    }

    if (economy.goldenHearts >= economy.maxGoldenHearts) {
      if (economy.goldenHeartRefillSeconds != 0) {
        economy = economy.copyWith(goldenHeartRefillSeconds: 0);
        changed = true;
      }
    } else {
      var secs = economy.goldenHeartRefillSeconds;
      if (secs <= 0) {
        final newGolden = economy.goldenHearts + 1;
        economy = economy.copyWith(
          goldenHearts: newGolden,
          goldenHeartRefillSeconds: newGolden < economy.maxGoldenHearts
              ? GameConstants.heartRefillSeconds
              : 0,
        );
        changed = true;
      } else {
        economy = economy.copyWith(goldenHeartRefillSeconds: secs - 1);
        changed = true;
      }
    }

    if (changed) {
      final livesOrHeartsChanged =
          economy.lives != state.economy.lives ||
          economy.goldenHearts != state.economy.goldenHearts;
      // Countdown ticks: update UI without Hive I/O every second.
      if (livesOrHeartsChanged) {
        await _persist(emit, economy);
      } else {
        emit(EconomyBlocState(economy));
      }
    }
  }

  Future<void> _onUpdateBoosters(
    UpdateBoosters event,
    Emitter<EconomyBlocState> emit,
  ) async {
    final s = state.economy.copyWith(boosters: event.boosters);
    await _persist(emit, s);
  }

  Future<void> _onResetBoosterFlags(
    ResetLevelBoosterFlags event,
    Emitter<EconomyBlocState> emit,
  ) async {
    final s =
        state.economy.copyWith(boosters: state.economy.boosters.resetLevelFlags());
    await _persist(emit, s);
  }

  @override
  Future<void> close() {
    _refillTimer?.cancel();
    return super.close();
  }
}
