import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../domain/entities/level.dart';

/// Neon objective panel matching reference screenshot.
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
      height: AppDimensions.targetWordsPanelHeight,
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        4,
        AppDimensions.paddingM,
        6,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1040).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonPurple, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPurple.withValues(alpha: 0.45),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            level.hint.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: AppColors.neonGold,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < level.words.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    _WordChip(
                      text: level.words[i].text,
                      isComplete: completedWordIds.contains(level.words[i].id),
                    ),
                  ],
                ],
              ),
            ),
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
    final colors = AppColors.marbleForWordChip(text);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isComplete
              ? [
                  AppColors.accentGreen.withValues(alpha: 0.9),
                  AppColors.accentGreen.withValues(alpha: 0.65),
                ]
              : [
                  Color.lerp(colors.first, Colors.white, 0.2)!,
                  colors.last,
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: isComplete ? 0.8 : 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? AppColors.accentGreen : colors.first)
                .withValues(alpha: 0.45),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.6,
          decoration: isComplete ? TextDecoration.lineThrough : null,
          decorationColor: Colors.white,
          decorationThickness: 2,
        ),
      ),
    );
  }
}
