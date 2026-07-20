import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  int _dailyLevelId() {
    final now = DateTime.now();
    return (now.difference(DateTime(now.year)).inDays % 1000) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final levelId = _dailyLevelId();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: AppColors.accentGold,
                      size: 64,
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      AppStrings.dailyChallenge,
                      style: AppTextStyles.heading(context),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      'Level $levelId',
                      style: AppTextStyles.subheading(context),
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    Text(
                      '${AppStrings.streak}: 0 ${AppStrings.days}',
                      style: AppTextStyles.body(context),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      decoration: AppDecorations.card(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite, color: AppColors.accentGold),
                          const SizedBox(width: 8),
                          Text(
                            'Golden Hearts: 3',
                            style: AppTextStyles.body(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),
                    GestureDetector(
                      onTap: () => context.go('/game/$levelId'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: AppDimensions.paddingM,
                        ),
                        decoration: AppDecorations.playButton(),
                        child: Text(AppStrings.play, style: AppTextStyles.button(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const BottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }
}
