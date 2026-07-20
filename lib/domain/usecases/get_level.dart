import '../entities/level.dart';
import '../repositories/level_repository.dart';

class GetLevel {
  const GetLevel(this._repository);

  final LevelRepository _repository;

  Future<Level> call(int id) => _repository.getLevel(id);
}

class GetNextLevel {
  const GetNextLevel(this._repository);

  final LevelRepository _repository;

  Future<Level?> call(int id) => _repository.getNextLevel(id);
}

class GetTotalLevels {
  const GetTotalLevels(this._repository);

  final LevelRepository _repository;

  Future<int> call() => _repository.getTotalLevels();
}
