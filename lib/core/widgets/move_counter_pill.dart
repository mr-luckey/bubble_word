import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class MoveCounterPill extends StatelessWidget {
  const MoveCounterPill({
    super.key,
    required this.movesLeft,
    required this.movesTotal,
    required this.levelId,
  });

  final int movesLeft;
  final int movesTotal;
  final int levelId;

  @override
  Widget build(BuildContext context) {
    final ratio = movesTotal > 0 ? movesLeft / movesTotal : 0.0;
    final color = ratio > 0.3
        ? AppColors.accentGold
        : ratio > 0.1
            ? AppColors.accentCyan
            : AppColors.accentRed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
            vertical: AppDimensions.paddingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Level $levelId',
            style: AppTextStyles.caption(context),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingS,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            '$movesLeft',
            style: AppTextStyles.moveCounter(context).copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
