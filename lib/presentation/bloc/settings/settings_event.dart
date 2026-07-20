part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class ToggleSound extends SettingsEvent {
  const ToggleSound(this.enabled);
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class ToggleMusic extends SettingsEvent {
  const ToggleMusic(this.enabled);
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class ToggleHaptics extends SettingsEvent {
  const ToggleHaptics(this.enabled);
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
