import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../../domain/entities/level.dart';

/// Shows the level hint and target words at the top of the playfield.
class TargetWordsPanel extends StatelessWidget {
  const TargetWordsPanel({
    super.key,
    required this.level,
    required this.completedWordIds,
  });

  final Level level;
  final List<String> completedWordIds;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        2,
        AppDimensions.paddingM,
        4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.bubbleGlow.withValues(alpha: 0.10),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            level.hint,
            textAlign: TextAlign.center,
            style: AppTextStyles.hintBar(context).copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final word in level.words)
                _WordChip(
                  text: word.text,
                  isComplete: completedWordIds.contains(word.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.text,
    required this.isComplete,
  });

  final String text;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: isComplete
            ? LinearGradient(
                colors: [
                  AppColors.accentGreen.withValues(alpha: 0.35),
                  AppColors.accentGreen.withValues(alpha: 0.15),
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.bubbleGlow.withValues(alpha: 0.25),
                  AppColors.bubbleCore.withValues(alpha: 0.35),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete
              ? AppColors.accentGreen.withValues(alpha: 0.7)
              : AppColors.bubbleGlow.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isComplete) ...[
            const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 16),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTextStyles.caption(context).copyWith(
              color: isComplete ? AppColors.accentGreen : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              decoration: isComplete ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.accentGreen,
            ),
          ),
        ],
      ),
    );
  }
}
