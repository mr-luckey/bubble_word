import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Neon-styled in-game header with level progress and countdown timer.
class GameHeaderBar extends StatelessWidget {
  const GameHeaderBar({
    super.key,
    required this.levelId,
    required this.wordsComplete,
    required this.wordsTotal,
    required this.timeLeftSeconds,
    this.onBack,
    this.onHint,
    this.hintCount = 0,
  });

  final int levelId;
  final int wordsComplete;
  final int wordsTotal;
  final int timeLeftSeconds;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final int hintCount;

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = wordsTotal > 0 ? wordsComplete / wordsTotal : 0.0;
    final isLowTime = timeLeftSeconds <= 10;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      child: Row(
        children: [
          if (onBack != null)
            _NeonIconBox(
              borderColor: AppColors.neonPurple,
              glowColor: AppColors.neonPurple,
              onTap: onBack!,
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'LEVEL $levelId',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    color: AppColors.bubbleGlow,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$wordsComplete/$wordsTotal',
                  style: GoogleFonts.nunito(
                    color: AppColors.bubbleGlow,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _NeonIconBox(
            borderColor: isLowTime ? AppColors.accentRed : AppColors.neonGold,
            glowColor: isLowTime ? AppColors.accentRed : AppColors.neonGold,
            onTap: () {},
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: isLowTime ? AppColors.accentRed : AppColors.neonGold,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(timeLeftSeconds),
                  style: GoogleFonts.nunito(
                    color: isLowTime ? AppColors.accentRed : AppColors.neonGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (onHint != null) ...[
            const SizedBox(width: 8),
            _NeonIconBox(
              borderColor: AppColors.neonGold,
              glowColor: AppColors.neonGold,
              onTap: onHint!,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$hintCount',
                    style: GoogleFonts.nunito(
                      color: AppColors.neonGold,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.lightbulb, color: AppColors.neonGold, size: 22),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NeonIconBox extends StatelessWidget {
  const _NeonIconBox({
    required this.borderColor,
    required this.glowColor,
    required this.onTap,
    required this.child,
    this.padding,
  });

  final Color borderColor;
  final Color glowColor;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1040).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
