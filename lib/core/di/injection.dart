import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/local_level_datasource.dart';
import '../../data/datasources/player_progress_datasource.dart';
import '../../data/repositories/level_repository_impl.dart';
import '../../domain/repositories/level_repository.dart';
import '../../domain/usecases/calculate_move_budget.dart';
import '../../domain/usecases/calculate_star_rating.dart';
import '../../domain/usecases/check_board_overload.dart';
import '../../domain/usecases/game_engine.dart';
import '../../domain/usecases/get_level.dart';
import '../../domain/usecases/validate_merge.dart';
import '../utils/audio_service.dart';
import '../utils/rate_app_service.dart';
import '../utils/update_service.dart';
import '../utils/ball_physics_engine.dart';
import '../../presentation/bloc/ad/ad_bloc.dart';
import '../../presentation/bloc/economy/economy_bloc.dart';
import '../../presentation/bloc/game/game_bloc.dart';
import '../../presentation/bloc/level/level_bloc.dart';
import '../../presentation/bloc/settings/settings_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  await Hive.initFlutter();

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton(LocalLevelDataSource.new);
  final progressDataSource = PlayerProgressDataSource(prefs);
  await progressDataSource.open();
  getIt.registerSingleton<PlayerProgressDataSource>(progressDataSource);

  getIt.registerLazySingleton(CalculateMoveBudget.new);
  getIt.registerLazySingleton<LevelRepository>(
    () => LevelRepositoryImpl(getIt(), getIt()),
  );

  getIt.registerLazySingleton(() => GetLevel(getIt()));
  getIt.registerLazySingleton(() => GetNextLevel(getIt()));
  getIt.registerLazySingleton(() => GetTotalLevels(getIt()));

  getIt.registerLazySingleton(ValidateMerge.new);
  getIt.registerLazySingleton(() => CheckBoardOverload(getIt()));
  getIt.registerLazySingleton(CalculateStarRating.new);
  getIt.registerLazySingleton(() => InitializeGameState(const Uuid()));
  getIt.registerLazySingleton(SpawnBallFromQueue.new);
  getIt.registerLazySingleton(SplitJunkBall.new);
  getIt.registerLazySingleton(BallPhysicsEngine.new);

  getIt.registerLazySingleton(AudioService.new);
  getIt.registerLazySingleton(UpdateService.new);
  getIt.registerLazySingleton(RateAppService.new);
  await getIt<AudioService>().init();

  getIt.registerFactory(() => LevelBloc(getIt(), getIt()));
  getIt.registerFactory(
    () => GameBloc(
      initializeGameState: getIt(),
      validateMerge: getIt(),
      checkBoardOverload: getIt(),
      calculateStarRating: getIt(),
      spawnBallFromQueue: getIt(),
      splitJunkBall: getIt(),
      physicsEngine: getIt(),
    ),
  );
  getIt.registerLazySingleton(() => EconomyBloc(getIt()));
  getIt.registerLazySingleton(AdBloc.new);
  getIt.registerLazySingleton(() => SettingsBloc(getIt()));
}
