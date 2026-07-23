import 'dart:math' as math;

import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';
import '../constants/app_dimensions.dart';

/// Balls pack tightly at the **bottom** of the playfield — no floating gap.
abstract final class BoardLayout {
  static const double _margin = 2;

  static int? _cachedCount;
  static double? _cachedWidth;
  static double? _cachedHeight;
  static double? _cachedRadius;

  /// Largest radius that fits [ballCount] balls across width, stacked from bottom.
  static double uniformBoardRadius({
    required int ballCount,
    required double width,
    required double height,
  }) {
    if (ballCount <= 0 || width <= 0 || height <= 0) {
      return AppDimensions.ballRadiusSmall * AppDimensions.scaleForWidth(width);
    }

    if (_cachedCount == ballCount &&
        _cachedWidth == width &&
        _cachedHeight == height &&
        _cachedRadius != null) {
      return _cachedRadius!;
    }

    final usableW = width - 2 * _margin;
    final usableH = height - 2 * _margin;
    var lo = 12.0;
    var hi = usableW / 2;

    for (var i = 0; i < 36; i++) {
      final mid = (lo + hi) / 2;
      if (_fits(ballCount, mid, usableW, usableH) != null) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    _cachedCount = ballCount;
    _cachedWidth = width;
    _cachedHeight = height;
    _cachedRadius = lo;
    return lo;
  }

  static List<int>? _fits(int count, double r, double w, double h) {
    if (r <= 0) return null;
    final diameter = 2 * r;
    final cols = math.max(1, (w / diameter).floor());
    final rowCounts = <int>[];
    var placed = 0;

    while (placed < count) {
      rowCounts.add(math.min(cols, count - placed));
      placed += rowCounts.last;
    }

    if (rowCounts.length * diameter > h + 0.5) return null;
    if (cols * diameter > w + 0.5) return null;
    return rowCounts;
  }

  /// Uniform on-board radius — locked to [layoutBallCount] so balls never
  /// grow when words are completed and removed from the board.
  static double radiusFor(
    Ball ball, {
    double screenWidth = 360,
    required int layoutBallCount,
    double boardHeight = 480,
    double boardWidth = 360,
  }) {
    if (ball.type == BallType.superBall) {
      return AppDimensions.ballRadiusSuper *
          AppDimensions.scaleForWidth(screenWidth);
    }
    if (layoutBallCount <= 0) {
      return AppDimensions.ballRadiusSmall *
          AppDimensions.scaleForWidth(screenWidth);
    }
    return uniformBoardRadius(
      ballCount: layoutBallCount,
      width: boardWidth,
      height: boardHeight,
    );
  }

  static List<Ball> layoutFragments({
    required List<Ball> balls,
    required double width,
    required double height,
    int? layoutBallCount,
  }) {
    if (balls.isEmpty || width <= 0 || height <= 0) return balls;

    final count = layoutBallCount ?? balls.length;
    final r = uniformBoardRadius(
      ballCount: count,
      width: width,
      height: height,
    );
    final rowCounts = _fits(balls.length, r, width - 2 * _margin, height - 2 * _margin);
    if (rowCounts == null) return balls;

    final diameter = 2 * r;
    final cols = math.max(1, ((width - 2 * _margin) / diameter).floor());
    final gridW = cols * diameter;
    final gridLeft = _margin + (width - 2 * _margin - gridW) / 2 + r;
    final bottomY = height - _margin - r;

    final placed = <Ball>[];
    var index = 0;

    for (var rowFromBottom = 0; rowFromBottom < rowCounts.length; rowFromBottom++) {
      final ballsInRow = rowCounts[rowFromBottom];
      final y = bottomY - rowFromBottom * diameter;
      final rowW = ballsInRow * diameter;
      final rowLeft = gridLeft + (gridW - rowW) / 2;

      for (var col = 0; col < ballsInRow && index < balls.length; col++) {
        placed.add(
          balls[index].copyWith(
            x: rowLeft + col * diameter,
            y: y,
            vx: 0,
            vy: 0,
            isOnBoard: true,
          ),
        );
        index++;
      }
    }

    return placed;
  }

  static List<Ball> layoutWordBalls({
    required List<Ball> balls,
    required double width,
    required double height,
  }) {
    return layoutFragments(balls: balls, width: width, height: height);
  }

  static Ball layoutSingleSuperBall({
    required Ball ball,
    required double width,
    required double height,
  }) {
    return ball.copyWith(x: width / 2, y: height * 0.42, vx: 0, vy: 0);
  }

  static List<Ball> resolveOverlaps(
    List<Ball> balls, {
    required double width,
    required double height,
    int? ballCount,
  }) {
    return balls;
  }
}
