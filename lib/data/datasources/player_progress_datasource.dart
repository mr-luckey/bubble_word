import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/economy_state.dart';

class PlayerProgressDataSource {
  PlayerProgressDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _coinsKey = 'coins';
  static const _livesKey = 'lives';
  static const _lifeRefillKey = 'life_refill_seconds';
  static const _goldenHeartsKey = 'golden_hearts';
  static const _dailyStreakKey = 'daily_streak';
  static const _levelsCompletedAdKey = 'levels_completed_ad';
  static const _noAdsKey = 'no_ads';
  static const _currentLevelKey = 'current_level';
  static const _levelStarsKey = 'level_stars';
  static const _boostersKey = 'boosters';
  static const _soundKey = 'sound';
  static const _musicKey = 'music';
  static const _hapticsKey = 'haptics';
  static const _lastDailyKey = 'last_daily_date';

  EconomyState loadEconomy() {
    final starsRaw = _prefs.getString(_levelStarsKey);
    final starsMap = <int, int>{};
    if (starsRaw != null) {
      final decoded = jsonDecode(starsRaw) as Map<String, dynamic>;
      decoded.forEach((k, v) => starsMap[int.parse(k)] = v as int);
    }

    final boostersRaw = _prefs.getString(_boostersKey);
    var boosters = const BoosterInventory();
    if (boostersRaw != null) {
      final b = jsonDecode(boostersRaw) as Map<String, dynamic>;
      boosters = BoosterInventory(
        hint: b['hint'] as int? ?? 3,
        magnet: b['magnet'] as int? ?? 1,
        addBall: b['addBall'] as int? ?? 1,
        magicWand: b['magicWand'] as int? ?? 1,
        extraMoves: b['extraMoves'] as int? ?? 0,
      );
    }

    return EconomyState(
      coins: _prefs.getInt(_coinsKey) ?? 100,
      lives: _prefs.getInt(_livesKey) ?? 5,
      lifeRefillSeconds: _prefs.getInt(_lifeRefillKey) ?? 0,
      goldenHearts: _prefs.getInt(_goldenHeartsKey) ?? 3,
      dailyStreak: _prefs.getInt(_dailyStreakKey) ?? 0,
      levelsCompletedSinceAd: _prefs.getInt(_levelsCompletedAdKey) ?? 0,
      noAdsPurchased: _prefs.getBool(_noAdsKey) ?? false,
      currentLevel: _prefs.getInt(_currentLevelKey) ?? 1,
      levelStars: starsMap,
      boosters: boosters,
    );
  }

  Future<void> saveEconomy(EconomyState state) async {
    await _prefs.setInt(_coinsKey, state.coins);
    await _prefs.setInt(_livesKey, state.lives);
    await _prefs.setInt(_lifeRefillKey, state.lifeRefillSeconds);
    await _prefs.setInt(_goldenHeartsKey, state.goldenHearts);
    await _prefs.setInt(_dailyStreakKey, state.dailyStreak);
    await _prefs.setInt(_levelsCompletedAdKey, state.levelsCompletedSinceAd);
    await _prefs.setBool(_noAdsKey, state.noAdsPurchased);
    await _prefs.setInt(_currentLevelKey, state.currentLevel);
    final starsJson = state.levelStars.map((k, v) => MapEntry('$k', v));
    await _prefs.setString(_levelStarsKey, jsonEncode(starsJson));
    await _prefs.setString(
      _boostersKey,
      jsonEncode({
        'hint': state.boosters.hint,
        'magnet': state.boosters.magnet,
        'addBall': state.boosters.addBall,
        'magicWand': state.boosters.magicWand,
        'extraMoves': state.boosters.extraMoves,
      }),
    );
  }

  bool get soundEnabled => _prefs.getBool(_soundKey) ?? true;
  bool get musicEnabled => _prefs.getBool(_musicKey) ?? true;
  bool get hapticsEnabled => _prefs.getBool(_hapticsKey) ?? true;

  Future<void> setSound(bool v) => _prefs.setBool(_soundKey, v);
  Future<void> setMusic(bool v) => _prefs.setBool(_musicKey, v);
  Future<void> setHaptics(bool v) => _prefs.setBool(_hapticsKey, v);

  String? get lastDailyDate => _prefs.getString(_lastDailyKey);
  Future<void> setLastDailyDate(String date) =>
      _prefs.setString(_lastDailyKey, date);
}
