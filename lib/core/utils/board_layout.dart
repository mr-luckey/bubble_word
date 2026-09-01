import 'dart:math' as math;

import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';
import '../constants/app_dimensions.dart';

/// Oval balloons packed edge-to-edge — fills the measured playfield.
abstract final class BoardLayout {
  static const double _marginH = 0;
  static const double _marginV = 0;
  static const double _hr = AppDimensions.balloonHeightRatio;
  static const double _wr = AppDimensions.balloonWidthRatio;

  static int? _cachedCount;
  static double? _cachedWidth;
  static double? _cachedHeight;
  static double? _cachedRadius;

  static double _halfW(double r) => AppDimensions.balloonHalfWidth(r);
  static double _halfH(double r) => AppDimensions.balloonHalfHeight(r);

  /// Columns that span the playfield width (no empty side gutters).
  static int targetColumns(double usableW) {
    if (usableW >= AppDimensions.tabletBreakpoint) return 7;
    if (usableW >= 400) return 6;
    return 5;
  }

  static List<int> _rowCounts(int count, int cols) {
    final rows = <int>[];
    var placed = 0;
    while (placed < count) {
      rows.add(math.min(cols, count - placed));
      placed += rows.last;
    }
    return rows;
  }

  static ({
    double r,
    int cols,
    List<int> rowCounts,
    double colGap,
    double rowGap,
    double usableW,
    double usableH,
  }) _layoutSpec({
    required int ballCount,
    required double width,
    required double height,
  }) {
    final usableW = width - 2 * _marginH;
    final usableH = height - 2 * _marginV;
    final cols = targetColumns(usableW);
    final rowCounts = _rowCounts(ballCount, cols);
    final rowCount = rowCounts.length;

    double r;
    double colGap;
    double rowGap;

    if (rowCount <= 1) {
      final rFromW = usableW / (2.0 * cols * _wr);
      final rFromH = usableH / (2.0 * _hr);
      r = math.min(rFromW, rFromH).clamp(10.0, usableW / (2 * _wr));
      final hw = _halfW(r);
      colGap = cols > 1 ? (usableW - cols * 2 * hw) / (cols - 1) : 0;
      rowGap = 0;
    } else {
      // Prefer filling width, then distribute leftover height as row spacing.
      r = (usableW / (2.0 * cols * _wr)).clamp(10.0, usableW / (2 * _wr));
      var hh = _halfH(r);
      var totalBallHeight = rowCount * 2 * hh;
      rowGap = (usableH - totalBallHeight) / (rowCount - 1);

      if (rowGap < 0) {
        r = (usableH / (2.0 * _hr * rowCount)).clamp(10.0, usableW / (2 * _wr));
        hh = _halfH(r);
        final hw = _halfW(r);
        colGap = cols > 1 ? (usableW - cols * 2 * hw) / (cols - 1) : 0;
        totalBallHeight = rowCount * 2 * hh;
        rowGap = math.max(0, (usableH - totalBallHeight) / (rowCount - 1));
      } else {
        final hw = _halfW(r);
        colGap = cols > 1 ? (usableW - cols * 2 * hw) / (cols - 1) : 0;
      }
    }

    return (
      r: r,
      cols: cols,
      rowCounts: rowCounts,
      colGap: colGap,
      rowGap: rowGap,
      usableW: usableW,
      usableH: usableH,
    );
  }

  /// Radius sized so [ballCount] ovals fill the measured playfield.
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

    final spec = _layoutSpec(
      ballCount: ballCount,
      width: width,
      height: height,
    );

    _cachedCount = ballCount;
    _cachedWidth = width;
    _cachedHeight = height;
    _cachedRadius = spec.r;
    return spec.r;
  }

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
    final spec = _layoutSpec(
      ballCount: count,
      width: width,
      height: height,
    );
    final r = spec.r;
    final hw = _halfW(r);
    final hh = _halfH(r);
    final colPitch = 2 * hw + spec.colGap;
    final rowPitch = 2 * hh + spec.rowGap;
    final rowCounts = _rowCounts(balls.length, spec.cols);
    final gridLeft = _marginH + hw;
    final topY = rowCounts.length <= 1
        ? _marginV + spec.usableH / 2
        : _marginV + hh;

    final placed = <Ball>[];
    var index = 0;

    for (var row = 0; row < rowCounts.length; row++) {
      final ballsInRow = rowCounts[row];
      final y = topY + row * rowPitch;

      for (var col = 0; col < ballsInRow && index < balls.length; col++) {
        final double x;
        if (ballsInRow == spec.cols) {
          x = gridLeft + col * colPitch;
        } else if (ballsInRow == 1) {
          x = _marginH + spec.usableW / 2;
        } else {
          final spacing = (spec.usableW - ballsInRow * 2 * hw) / (ballsInRow - 1);
          x = _marginH + hw + col * (2 * hw + spacing);
        }

        placed.add(
          balls[index].copyWith(
            x: x,
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
