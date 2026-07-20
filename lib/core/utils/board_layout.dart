import 'dart:math' as math;

import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';
import '../constants/app_dimensions.dart';

/// Non-overlapping bubble layout for the playfield.
abstract final class BoardLayout {
  static const double _minGap = 16;
  static const double _margin = 28;

  static double radiusFor(
    Ball ball, {
    double screenWidth = 360,
    int ballCount = 1,
    double boardHeight = 480,
  }) {
    final density =
        AppDimensions.densityScale(ballCount, screenWidth, boardHeight);
    final s = AppDimensions.scaleForWidth(screenWidth) * density;
    if (ball.type == BallType.superBall) return AppDimensions.ballRadiusSuper * s;
    if (ball.type == BallType.completeWord ||
        ball.type == BallType.wordInProgress) {
      return AppDimensions.ballRadiusWord * s;
    }
    if (ball.type == BallType.decoy || ball.chars.length >= 3) {
      return AppDimensions.ballRadiusMedium * s;
    }
    return AppDimensions.ballRadiusSmall * s;
  }

  static double _halfExtent(
    Ball ball, {
    required double screenWidth,
    required int ballCount,
    required double boardHeight,
  }) {
    return AppDimensions.visualHalfExtent(
      radiusFor(
        ball,
        screenWidth: screenWidth,
        ballCount: ballCount,
        boardHeight: boardHeight,
      ),
    );
  }

  static List<Ball> layoutFragments({
    required List<Ball> balls,
    required double width,
    required double height,
  }) {
    if (balls.isEmpty || width <= 0 || height <= 0) return balls;

    final ballCount = balls.length;
    final aspect = width / height;
    var cols = math.max(1, math.sqrt(ballCount * aspect).round());
    var rows = math.max(1, (ballCount / cols).ceil());
    while (cols * rows < ballCount) {
      cols++;
      rows = (ballCount / cols).ceil();
    }

    final usableW = width - 2 * _margin;
    final usableH = height - 2 * _margin;
    final cellW = usableW / cols;
    final cellH = usableH / rows;

    final placed = <Ball>[];
    for (var i = 0; i < balls.length; i++) {
      final ball = balls[i];
      final half = _halfExtent(
        ball,
        screenWidth: width,
        ballCount: ballCount,
        boardHeight: height,
      );
      final col = i % cols;
      final row = i ~/ cols;
      final jitterX = (i % 3 - 1) * 3.0;
      final jitterY = ((i * 5) % 3 - 1) * 3.0;
      final x = (_margin + cellW * (col + 0.5) + jitterX)
          .clamp(_margin + half, width - _margin - half);
      final y = (_margin + cellH * (row + 0.5) + jitterY)
          .clamp(_margin + half, height - _margin - half);
      placed.add(
        ball.copyWith(
          x: x,
          y: y,
          vx: 0,
          vy: 0,
          isOnBoard: true,
        ),
      );
    }

    return resolveOverlaps(
      placed,
      width: width,
      height: height,
      ballCount: ballCount,
    );
  }

  static List<Ball> layoutWordBalls({
    required List<Ball> balls,
    required double width,
    required double height,
  }) {
    if (balls.isEmpty) return balls;
    return layoutFragments(balls: balls, width: width, height: height);
  }

  static Ball layoutSingleSuperBall({
    required Ball ball,
    required double width,
    required double height,
  }) {
    return ball.copyWith(x: width / 2, y: height * 0.42, vx: 0, vy: 0);
  }

  /// Push overlapping balls apart while keeping them inside the playfield.
  static List<Ball> resolveOverlaps(
    List<Ball> balls, {
    required double width,
    required double height,
    int? ballCount,
  }) {
    if (balls.length < 2) return balls;

    final count = ballCount ?? balls.length;
    var result = List<Ball>.from(balls);
    for (var pass = 0; pass < 120; pass++) {
      var moved = false;

      for (var i = 0; i < result.length; i++) {
        for (var j = i + 1; j < result.length; j++) {
          final a = result[i];
          final b = result[j];
          if (!a.isOnBoard || !b.isOnBoard) continue;

          final ra = _halfExtent(
            a,
            screenWidth: width,
            ballCount: count,
            boardHeight: height,
          );
          final rb = _halfExtent(
            b,
            screenWidth: width,
            ballCount: count,
            boardHeight: height,
          );
          final dx = b.x - a.x;
          final dy = b.y - a.y;
          var dist = math.sqrt(dx * dx + dy * dy);
          final minDist = ra + rb + _minGap;

          if (dist >= minDist) continue;

          double nx;
          double ny;
          if (dist < 0.001) {
            final angle = (i * 2.399963 + j) % (math.pi * 2);
            nx = math.cos(angle);
            ny = math.sin(angle);
            dist = 0.001;
          } else {
            nx = dx / dist;
            ny = dy / dist;
          }

          final push = (minDist - dist) / 2 + 1;
          result[i] = a.copyWith(x: a.x - nx * push, y: a.y - ny * push);
          result[j] = b.copyWith(x: b.x + nx * push, y: b.y + ny * push);
          moved = true;
        }
      }

      result = result
          .map((b) => _clampToBounds(
                b,
                width: width,
                height: height,
                ballCount: count,
              ))
          .toList();

      if (!moved) break;
    }

    return result;
  }

  static Ball _clampToBounds(
    Ball ball, {
    required double width,
    required double height,
    required int ballCount,
  }) {
    final r = _halfExtent(
      ball,
      screenWidth: width,
      ballCount: ballCount,
      boardHeight: height,
    );
    return ball.copyWith(
      x: ball.x.clamp(_margin + r, width - _margin - r),
      y: ball.y.clamp(_margin + r, height - _margin - r),
    );
  }
}
