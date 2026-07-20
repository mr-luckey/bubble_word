part of 'level_bloc.dart';

sealed class LevelState extends Equatable {
  const LevelState();

  @override
  List<Object?> get props => [];
}

class LevelInitial extends LevelState {
  const LevelInitial();
}

class LevelLoading extends LevelState {
  const LevelLoading();
}

class LevelLoaded extends LevelState {
  const LevelLoaded(this.level);
  final Level level;

  @override
  List<Object?> get props => [level];
}

class LevelError extends LevelState {
  const LevelError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
