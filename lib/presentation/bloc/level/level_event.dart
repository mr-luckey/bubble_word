part of 'level_bloc.dart';

sealed class LevelEvent extends Equatable {
  const LevelEvent();

  @override
  List<Object?> get props => [];
}

class LoadLevel extends LevelEvent {
  const LoadLevel(this.levelId);
  final int levelId;

  @override
  List<Object?> get props => [levelId];
}

class LoadNextLevel extends LevelEvent {
  const LoadNextLevel(this.currentLevelId);
  final int currentLevelId;

  @override
  List<Object?> get props => [currentLevelId];
}

class RestartLevel extends LevelEvent {
  const RestartLevel(this.levelId);
  final int levelId;

  @override
  List<Object?> get props => [levelId];
}
