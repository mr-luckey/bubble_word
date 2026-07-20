import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_text_styles.dart';

class TopStatusBar extends StatelessWidget {
  const TopStatusBar({
    super.key,
    required this.coins,
    required this.lives,
    this.showBack = false,
  });

  final int coins;
  final int lives;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.go('/home'),
            ),
          const Spacer(),
          _Badge(icon: Icons.monetization_on, value: '$coins', color: AppColors.accentGold),
          const SizedBox(width: AppDimensions.paddingS),
          _Badge(icon: Icons.favorite, value: '$lives', color: AppColors.accentRed),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(value, style: AppTextStyles.caption(context).copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: AppColors.cardBg,
      indicatorColor: AppColors.accentBlue.withValues(alpha: 0.3),
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go('/home');
          case 1:
            context.go('/shop');
          case 2:
            context.go('/daily');
          case 3:
            context.go('/settings');
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.map), label: AppStrings.map),
        NavigationDestination(icon: Icon(Icons.store), label: AppStrings.shop),
        NavigationDestination(icon: Icon(Icons.local_fire_department), label: AppStrings.daily),
        NavigationDestination(icon: Icon(Icons.settings), label: AppStrings.settings),
      ],
    );
  }
}
