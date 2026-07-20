import '../entities/level.dart';

abstract class LevelRepository {
  Future<Level> getLevel(int id);
  Future<Level?> getNextLevel(int id);
  Future<int> getTotalLevels();
}
