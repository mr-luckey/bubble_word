import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../bloc/economy/economy_bloc.dart';
import '../bloc/game/game_bloc.dart';

class LevelFailOverlay extends StatelessWidget {
  const LevelFailOverlay({
    super.key,
    required this.gameState,
    required this.onRetry,
    required this.onWatchAd,
    required this.onSpendCoins,
    required this.onHome,
  });

  final GameFailed gameState;
  final VoidCallback onRetry;
  final VoidCallback onWatchAd;
  final VoidCallback onSpendCoins;
  final VoidCallback onHome;

  String _formatRefill(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EconomyBloc, EconomyBlocState>(
      builder: (context, econ) {
        final refill = _formatRefill(econ.economy.lifeRefillSeconds);
        return Container(
          color: AppColors.darkBg.withValues(alpha: 0.95),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(AppDimensions.paddingL),
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              decoration: AppDecorations.card(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, color: AppColors.accentRed, size: 64),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(AppStrings.levelFailed, style: AppTextStyles.heading(context)),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text('${AppStrings.moves}: 0', style: AppTextStyles.body(context)),
                  if (refill.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingS),
                    Text(
                      '${AppStrings.waitForLife}: $refill',
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.paddingL),
                  _FailOption(
                    label: AppStrings.watchAdFree,
                    subtitle: AppStrings.continueWithMoves,
                    highlighted: true,
                    onTap: onWatchAd,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  _FailOption(
                    label: '${AppStrings.useCoins} (100)',
                    subtitle: AppStrings.continueWithMoves,
                    onTap: econ.economy.coins >= 100 ? onSpendCoins : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  _FailOption(
                    label: '${AppStrings.tryAgain} (-1 ❤)',
                    subtitle: '${AppStrings.lives}: ${econ.economy.lives}',
                    onTap: econ.economy.lives > 0 ? onRetry : null,
                  ),
                  TextButton(onPressed: onHome, child: Text(AppStrings.map)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FailOption extends StatelessWidget {
  const _FailOption({
    required this.label,
    required this.subtitle,
    this.highlighted = false,
    this.onTap,
  });

  final String label;
  final String subtitle;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.accentBlue.withValues(alpha: 0.2)
                : AppColors.darkBg,
            borderRadius: BorderRadius.circular(AppDimensions.paddingS),
            border: Border.all(
              color: highlighted ? AppColors.accentBlue : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.subheading(context)),
              Text(subtitle, style: AppTextStyles.caption(context)),
            ],
          ),
        ),
      ),
    );
  }
}
