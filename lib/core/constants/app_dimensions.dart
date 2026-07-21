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

  /// Fixed objective panel height — must not grow when words complete.
  static const double targetWordsPanelHeight = 88;

  static const Duration mergeAnimation = Duration(milliseconds: 300);
  static const Duration shakeAnimation = Duration(milliseconds: 200);
  static const Duration floatAnimation = Duration(milliseconds: 2000);
  static const Duration popAnimation = Duration(milliseconds: 500);

  static double scale(BuildContext context) =>
      scaleForWidth(MediaQuery.sizeOf(context).width);

  static double scaleForWidth(double width) {
    if (width >= tabletBreakpoint) return 1.45;
    if (width >= 400) return 1.15;
    return 0.95;
  }

  /// Layout uses the full ball radius — no extra glow padding between balls.
  static double visualHalfExtent(double radius) => radius;

  static double visualBallSize(double radius) => radius * 2;

  static double scaledBallRadius(
    BuildContext context, {
    required int charCount,
    bool isSuper = false,
    bool isDecoy = false,
    double densityScale = 1.0,
  }) {
    final s = scale(context) * densityScale;
    if (isSuper) return ballRadiusSuper * s;
    if (isDecoy || charCount >= 3) return ballRadiusMedium * s;
    return ballRadiusSmall * s;
  }

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;
}
