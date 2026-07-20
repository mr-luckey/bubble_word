import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/level.dart';
import '../../../domain/usecases/get_level.dart';

part 'level_event.dart';
part 'level_state.dart';

class LevelBloc extends Bloc<LevelEvent, LevelState> {
  LevelBloc(this._getLevel, this._getNextLevel) : super(const LevelInitial()) {
    on<LoadLevel>(_onLoadLevel);
    on<LoadNextLevel>(_onLoadNextLevel);
    on<RestartLevel>(_onRestartLevel);
  }

  final GetLevel _getLevel;
  final GetNextLevel _getNextLevel;

  Future<void> _onLoadLevel(LoadLevel event, Emitter<LevelState> emit) async {
    emit(const LevelLoading());
    try {
      final level = await _getLevel(event.levelId);
      emit(LevelLoaded(level));
    } catch (e) {
      emit(LevelError(e.toString()));
    }
  }

  Future<void> _onLoadNextLevel(
    LoadNextLevel event,
    Emitter<LevelState> emit,
  ) async {
    emit(const LevelLoading());
    try {
      final level = await _getNextLevel(event.currentLevelId);
      if (level == null) {
        emit(const LevelError('No more levels'));
        return;
      }
      emit(LevelLoaded(level));
    } catch (e) {
      emit(LevelError(e.toString()));
    }
  }

  Future<void> _onRestartLevel(
    RestartLevel event,
    Emitter<LevelState> emit,
  ) async {
    add(LoadLevel(event.levelId));
  }
}
