import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class AppDimensions {
  static const double ballRadiusSmall = 28;
  static const double ballRadiusMedium = 34;
  static const double ballRadiusWord = 46;
  static const double ballRadiusSuper = 90;

  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;

  static const double hintBarHeight = 48;
  static const double boosterBarHeight = 56;
  static const double wordTrayHeight = 64;
  static const double moveCounterSize = 36;

  static const double tabletBreakpoint = 600;
  static const double splashDurationMs = 2500;

  static const Duration mergeAnimation = Duration(milliseconds: 300);
  static const Duration shakeAnimation = Duration(milliseconds: 200);
  static const Duration floatAnimation = Duration(milliseconds: 2000);
  static const Duration popAnimation = Duration(milliseconds: 500);

  static double scale(BuildContext context) => scaleForWidth(MediaQuery.sizeOf(context).width);

  static double scaleForWidth(double width) {
    if (width >= tabletBreakpoint) return 1.45;
    if (width >= 400) return 1.15;
    return 0.95;
  }

  /// Shrinks balls when the board is crowded so they fit without overlapping.
  static double densityScale(int ballCount, double width, double height) {
    if (ballCount <= 0 || width <= 0 || height <= 0) return 1.0;

    const margin = 56.0;
    const minGap = 16.0;
    final aspect = width / height;
    var cols = math.max(1, math.sqrt(ballCount * aspect).round());
    var rows = math.max(1, (ballCount / cols).ceil());
    while (cols * rows < ballCount) {
      cols++;
      rows = (ballCount / cols).ceil();
    }

    final cellW = (width - margin) / cols;
    final cellH = (height - margin) / rows;
    final maxCell = math.min(cellW, cellH);

    final baseRadius = ballRadiusSmall * scaleForWidth(width);
    final neededDiameter = baseRadius * 2 + 16 + minGap;
    if (neededDiameter <= maxCell) return 1.0;
    return (maxCell / neededDiameter).clamp(0.52, 1.0);
  }

  /// Half-size used for layout collision (includes glow padding).
  static double visualHalfExtent(double radius) => radius + 8;

  static double visualBallSize(double radius) => radius * 2 + 16;

  static double scaledBallRadius(BuildContext context, {required int charCount, required bool isWord, required bool isSuper, bool isDecoy = false, double densityScale = 1.0}) {
    final s = scale(context) * densityScale;
    if (isSuper) return ballRadiusSuper * s;
    if (isWord) return ballRadiusWord * s;
    if (isDecoy || charCount >= 3) return ballRadiusMedium * s;
    return ballRadiusSmall * s;
  }

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;
}
