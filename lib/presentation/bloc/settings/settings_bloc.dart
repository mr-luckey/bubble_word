import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/player_progress_datasource.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsBlocState> {
  SettingsBloc(this._dataSource)
      : super(SettingsBlocState(
          sound: _dataSource.soundEnabled,
          music: _dataSource.musicEnabled,
          haptics: _dataSource.hapticsEnabled,
        )) {
    on<ToggleSound>(_onSound);
    on<ToggleMusic>(_onMusic);
    on<ToggleHaptics>(_onHaptics);
  }

  final PlayerProgressDataSource _dataSource;

  Future<void> _onSound(ToggleSound event, Emitter<SettingsBlocState> emit) async {
    await _dataSource.setSound(event.enabled);
    emit(state.copyWith(sound: event.enabled));
  }

  Future<void> _onMusic(ToggleMusic event, Emitter<SettingsBlocState> emit) async {
    await _dataSource.setMusic(event.enabled);
    emit(state.copyWith(music: event.enabled));
  }

  Future<void> _onHaptics(ToggleHaptics event, Emitter<SettingsBlocState> emit) async {
    await _dataSource.setHaptics(event.enabled);
    emit(state.copyWith(haptics: event.enabled));
  }
}
