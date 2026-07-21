import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_decorations.dart';
import '../bloc/economy/economy_bloc.dart';
import '../widgets/app_screen_shell.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  int _dailyLevelId() {
    final now = DateTime.now();
    return (now.difference(DateTime(now.year)).inDays % 1000) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EconomyBloc, EconomyBlocState>(
      builder: (context, state) {
        final economy = state.economy;
        final levelId = _dailyLevelId();

        return AppScreenShell(
          bottomNavIndex: 1,
          showTopBar: true,
          coins: economy.coins,
          lives: economy.lives,
          lifeRefillSeconds: economy.lifeRefillSeconds,
          body: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonGold.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.neonGold, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonGold.withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: AppColors.neonGold,
                    size: 56,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),
                Text(
                  AppStrings.dailyChallenge.toUpperCase(),
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Text(
                  'Level $levelId',
                  style: GoogleFonts.nunito(
                    color: AppColors.bubbleGlow,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1040).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neonPurple, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${AppStrings.streak}: ${economy.dailyStreak} ${AppStrings.days}',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite, color: AppColors.neonGold),
                          const SizedBox(width: 8),
                          Text(
                            'Golden Hearts: ${economy.goldenHearts}',
                            style: GoogleFonts.nunito(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                GestureDetector(
                  onTap: () {
                    if (economy.lives <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(AppStrings.outOfLives)),
                      );
                      return;
                    }
                    context.read<EconomyBloc>().add(const SpendLife());
                    context.go('/game/$levelId');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingM,
                    ),
                    decoration: AppDecorations.playButton(),
                    child: Text(
                      AppStrings.play,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
