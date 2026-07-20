import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// In-game header: LEVEL + progress | hint.
class GameHeaderBar extends StatelessWidget {
  const GameHeaderBar({
    super.key,
    required this.levelId,
    required this.wordsComplete,
    required this.wordsTotal,
    this.onBack,
    this.onHint,
    this.hintCount = 0,
  });

  final int levelId;
  final int wordsComplete;
  final int wordsTotal;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final int hintCount;

  @override
  Widget build(BuildContext context) {
    final progress = wordsTotal > 0 ? wordsComplete / wordsTotal : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: onBack,
            ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'LEVEL $levelId',
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    color: AppColors.bubbleGlow,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$wordsComplete/$wordsTotal',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.bubbleGlow,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (onHint != null)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.lightbulb, color: AppColors.accentGold, size: 26),
                  onPressed: onHint,
                ),
                if (hintCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accentGold,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$hintCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.darkBg,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
