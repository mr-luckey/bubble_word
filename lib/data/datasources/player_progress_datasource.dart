import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/economy_state.dart';

/// Persists player progress in Hive (economy + level progress).
class PlayerProgressDataSource {
  PlayerProgressDataSource(this._prefs);

  static const _boxName = 'player_progress';
  static const _migratedKey = 'migrated_from_prefs';

  final SharedPreferences _prefs;
  Box? _box;

  Future<void> open() async {
    _box = await Hive.openBox(_boxName);
    await _migrateFromSharedPreferencesIfNeeded();
  }

  Future<void> _migrateFromSharedPreferencesIfNeeded() async {
    final box = _box!;
    if (box.get(_migratedKey) == true) return;
    if (_prefs.getKeys().isEmpty) {
      await box.put(_migratedKey, true);
      return;
    }

    final starsRaw = _prefs.getString('level_stars');
    final starsMap = <String, int>{};
    if (starsRaw != null) {
      final decoded = jsonDecode(starsRaw) as Map<String, dynamic>;
      decoded.forEach((k, v) => starsMap[k] = v as int);
    }

    await box.putAll({
      _migratedKey: true,
      'coins': _prefs.getInt('coins') ?? 100,
      'lives': _prefs.getInt('lives') ?? 5,
      'life_refill_seconds': _prefs.getInt('life_refill_seconds') ?? 0,
      'golden_hearts': _prefs.getInt('golden_hearts') ?? 3,
      'daily_streak': _prefs.getInt('daily_streak') ?? 0,
      'levels_completed_ad': _prefs.getInt('levels_completed_ad') ?? 0,
      'no_ads': _prefs.getBool('no_ads') ?? false,
      'current_level': _prefs.getInt('current_level') ?? 1,
      'level_stars': starsMap,
      'boosters': _prefs.getString('boosters'),
    });
  }

  EconomyState loadEconomy() {
    final box = _box;
    if (box == null || !box.isOpen) {
      return const EconomyState();
    }

    final starsRaw = box.get('level_stars');
    final starsMap = <int, int>{};
    if (starsRaw is Map) {
      starsRaw.forEach((k, v) {
        starsMap[int.parse(k.toString())] = v as int;
      });
    }

    final boostersRaw = box.get('boosters');
    var boosters = const BoosterInventory();
    if (boostersRaw is String && boostersRaw.isNotEmpty) {
      final b = jsonDecode(boostersRaw) as Map<String, dynamic>;
      boosters = BoosterInventory(
        hint: b['hint'] as int? ?? 3,
        magnet: b['magnet'] as int? ?? 1,
        addBall: b['addBall'] as int? ?? 1,
        magicWand: b['magicWand'] as int? ?? 1,
        extraMoves: b['extraMoves'] as int? ?? 0,
      );
    } else if (boostersRaw is Map) {
      boosters = BoosterInventory(
        hint: boostersRaw['hint'] as int? ?? 3,
        magnet: boostersRaw['magnet'] as int? ?? 1,
        addBall: boostersRaw['addBall'] as int? ?? 1,
        magicWand: boostersRaw['magicWand'] as int? ?? 1,
        extraMoves: boostersRaw['extraMoves'] as int? ?? 0,
      );
    }

    return EconomyState(
      coins: box.get('coins', defaultValue: 100) as int,
      lives: box.get('lives', defaultValue: 5) as int,
      lifeRefillSeconds: box.get('life_refill_seconds', defaultValue: 0) as int,
      goldenHearts: box.get('golden_hearts', defaultValue: 3) as int,
      dailyStreak: box.get('daily_streak', defaultValue: 0) as int,
      levelsCompletedSinceAd:
          box.get('levels_completed_ad', defaultValue: 0) as int,
      noAdsPurchased: box.get('no_ads', defaultValue: false) as bool,
      currentLevel: box.get('current_level', defaultValue: 1) as int,
      levelStars: starsMap,
      boosters: boosters,
    );
  }

  Future<void> saveEconomy(EconomyState state) async {
    final box = _box;
    if (box == null || !box.isOpen) return;

    final starsMap = state.levelStars.map((k, v) => MapEntry('$k', v));
    await box.putAll({
      'coins': state.coins,
      'lives': state.lives,
      'life_refill_seconds': state.lifeRefillSeconds,
      'golden_hearts': state.goldenHearts,
      'daily_streak': state.dailyStreak,
      'levels_completed_ad': state.levelsCompletedSinceAd,
      'no_ads': state.noAdsPurchased,
      'current_level': state.currentLevel,
      'level_stars': starsMap,
      'boosters': {
        'hint': state.boosters.hint,
        'magnet': state.boosters.magnet,
        'addBall': state.boosters.addBall,
        'magicWand': state.boosters.magicWand,
        'extraMoves': state.boosters.extraMoves,
      },
    });
  }

  bool get soundEnabled => _prefs.getBool('sound') ?? true;
  bool get musicEnabled => _prefs.getBool('music') ?? true;
  bool get hapticsEnabled => _prefs.getBool('haptics') ?? true;

  Future<void> setSound(bool v) => _prefs.setBool('sound', v);
  Future<void> setMusic(bool v) => _prefs.setBool('music', v);
  Future<void> setHaptics(bool v) => _prefs.setBool('haptics', v);

  String? get lastDailyDate => _prefs.getString('last_daily_date');
  Future<void> setLastDailyDate(String date) =>
      _prefs.setString('last_daily_date', date);
}
