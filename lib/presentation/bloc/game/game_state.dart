part of 'game_bloc.dart';

sealed class GameBlocState extends Equatable {
  const GameBlocState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameBlocState {
  const GameInitial();
}

class GamePlaying extends GameBlocState {
  const GamePlaying(this.gameState);
  final GameState gameState;

  @override
  List<Object?> get props => [gameState];
}

class GameWon extends GameBlocState {
  const GameWon(this.gameState, {required this.stars, required this.coinsEarned});
  final GameState gameState;
  final int stars;
  final int coinsEarned;

  @override
  List<Object?> get props => [gameState, stars, coinsEarned];
}

class GameFailed extends GameBlocState {
  const GameFailed(
    this.gameState,
    this.reason, {
    required this.stars,
    required this.coinsEarned,
  });
  final GameState gameState;
  final FailReason reason;
  final int stars;
  final int coinsEarned;

  @override
  List<Object?> get props => [gameState, reason, stars, coinsEarned];
}
