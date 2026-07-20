import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/level_model.dart';

class LocalLevelDataSource {
  LevelsFileModel? _cache;

  Future<LevelsFileModel> loadLevels() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/levels.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = LevelsFileModel.fromJson(json);
    return _cache!;
  }

  Future<LevelModel> getLevel(int id) async {
    final file = await loadLevels();
    return file.levels.firstWhere((l) => l.level == id);
  }

  Future<int> getTotalLevels() async {
    final file = await loadLevels();
    return file.totalLevels;
  }
}
