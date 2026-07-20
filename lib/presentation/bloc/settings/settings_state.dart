part of 'settings_bloc.dart';

class SettingsBlocState extends Equatable {
  const SettingsBlocState({
    required this.sound,
    required this.music,
    required this.haptics,
  });

  final bool sound;
  final bool music;
  final bool haptics;

  SettingsBlocState copyWith({bool? sound, bool? music, bool? haptics}) {
    return SettingsBlocState(
      sound: sound ?? this.sound,
      music: music ?? this.music,
      haptics: haptics ?? this.haptics,
    );
  }

  @override
  List<Object?> get props => [sound, music, haptics];
}
