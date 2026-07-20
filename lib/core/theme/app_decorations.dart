import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

abstract final class AppDecorations {
  static BoxDecoration card({Color? color}) => BoxDecoration(
        color: color ?? AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.paddingM),
        border: Border.all(color: AppColors.border),
      );

  static BoxDecoration glow({required Color color, double blur = 12}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.paddingM),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: blur,
            spreadRadius: 2,
          ),
        ],
      );

  static BoxDecoration hintBar() => BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.paddingS),
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
      );

  static BoxDecoration playButton() => BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentBlue, AppColors.accentCyan],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      );

  static LinearGradient categoryGradient(String category) {
    final colors = AppColors.forCategory(category);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}
