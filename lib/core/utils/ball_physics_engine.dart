import '../../domain/entities/game_state.dart';

/// Physics disabled — balls use static grid layout (reference app style).
class BallPhysicsEngine {
  GameState tick(
    GameState state,
    double dt,
    double boardWidth,
    double boardHeight,
  ) {
    return state;
  }
}
