import '../../domain/entities/level.dart';
import '../../domain/repositories/level_repository.dart';
import '../../domain/usecases/calculate_move_budget.dart';
import '../datasources/local_level_datasource.dart';

class LevelRepositoryImpl implements LevelRepository {
  LevelRepositoryImpl(this._dataSource, this._moveBudget);

  final LocalLevelDataSource _dataSource;
  final CalculateMoveBudget _moveBudget;

  @override
  Future<Level> getLevel(int id) async {
    final model = await _dataSource.getLevel(id);
    final levelEntity = model.toEntity(
      moveBudget: _moveBudget.call(
        model.toEntity(moveBudget: 0),
      ),
    );
    return levelEntity;
  }

  @override
  Future<Level?> getNextLevel(int id) async {
    final total = await getTotalLevels();
    if (id >= total) return null;
    return getLevel(id + 1);
  }

  @override
  Future<int> getTotalLevels() => _dataSource.getTotalLevels();
}
