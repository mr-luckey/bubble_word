import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

abstract final class AppTextStyles {
  static TextStyle _base(BuildContext context, {
    required double size,
    FontWeight weight = FontWeight.normal,
    Color color = AppColors.textPrimary,
  }) {
    final scale = AppDimensions.scale(context);
    return GoogleFonts.nunito(
      fontSize: size * scale,
      fontWeight: weight,
      color: color,
      decoration: TextDecoration.none,
      height: 1.2,
    );
  }

  static TextStyle heading(BuildContext context) =>
      _base(context, size: 28, weight: FontWeight.w800);

  static TextStyle subheading(BuildContext context) =>
      _base(context, size: 20, weight: FontWeight.w700, color: AppColors.accentCyan);

  static TextStyle body(BuildContext context) =>
      _base(context, size: 16, color: AppColors.textBody);

  static TextStyle caption(BuildContext context) =>
      _base(context, size: 12, color: AppColors.textMuted);

  static TextStyle hintBar(BuildContext context) =>
      _base(context, size: 18, weight: FontWeight.w600, color: Colors.white);

  static TextStyle moveCounter(BuildContext context) {
    final scale = AppDimensions.scale(context);
    return GoogleFonts.nunito(
      fontSize: AppDimensions.moveCounterSize * scale,
      fontWeight: FontWeight.w800,
      color: AppColors.accentGold,
      decoration: TextDecoration.none,
    );
  }

  static final Map<int, TextStyle> _ballFillCache = {};
  static final Map<int, TextStyle> _ballStrokeCache = {};

  static int _ballRadiusKey(double radius) => (radius * 10).round();

  /// Cached — safe to call from hot paths (no per-frame GoogleFonts).
  static TextStyle ballText({required double radius}) {
    final key = _ballRadiusKey(radius);
    return _ballFillCache.putIfAbsent(
      key,
      () => GoogleFonts.nunito(
        fontSize: radius * 0.54,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        decoration: TextDecoration.none,
        letterSpacing: 0.3,
        height: 1.0,
      ),
    );
  }

  /// Light black outline so ball letters stay readable on bright marbles.
  static TextStyle ballTextStroke({required double radius}) {
    final key = _ballRadiusKey(radius);
    return _ballStrokeCache.putIfAbsent(
      key,
      () => ballText(radius: radius).copyWith(
        color: null,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (radius * 0.045).clamp(1.0, 2.2)
          ..color = Colors.black.withValues(alpha: 0.55),
      ),
    );
  }

  static TextStyle button(BuildContext context) =>
      _base(context, size: 16, weight: FontWeight.w800);
}
