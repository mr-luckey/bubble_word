import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/game_constants.dart';
import '../../core/theme/app_decorations.dart';
import '../../domain/entities/enums.dart';
import '../bloc/economy/economy_bloc.dart';
import '../bloc/game/game_bloc.dart';

class LevelFailOverlay extends StatelessWidget {
  const LevelFailOverlay({
    super.key,
    required this.gameState,
    required this.onRetry,
    required this.onHome,
    this.isDailyChallenge = false,
  });

  final GameFailed gameState;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final bool isDailyChallenge;

  String _formatRefill(int seconds) {
    if (seconds <= 0) return '';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EconomyBloc, EconomyBlocState>(
      builder: (context, econ) {
        final lives = econ.economy.lives;
        final goldenHearts = econ.economy.goldenHearts;
        final heartCount =
            isDailyChallenge ? goldenHearts : lives;
        final maxHearts = isDailyChallenge
            ? GameConstants.maxGoldenHearts
            : GameConstants.maxHearts;
        final heartColor =
            isDailyChallenge ? AppColors.neonGold : AppColors.accentRed;
        final canRetry = heartCount > 0;
        final showRefill = !canRetry &&
            isDailyChallenge &&
            econ.economy.goldenHeartRefillSeconds > 0;
        final refillText = _formatRefill(econ.economy.goldenHeartRefillSeconds);

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(maxHearts, (i) {
                      final isBroken = i == heartCount && heartCount < maxHearts;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < heartCount
                              ? Icons.favorite
                              : (isBroken
                                  ? Icons.heart_broken
                                  : Icons.favorite_border),
                          color: isBroken || i < heartCount
                              ? heartColor
                              : Colors.white38,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  if (isDailyChallenge) ...[
                    const SizedBox(height: AppDimensions.paddingS),
                    Text(
                      'Golden Hearts',
                      style: GoogleFonts.nunito(
                        color: AppColors.neonGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    AppStrings.tryAgain,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  if (gameState.reason == FailReason.timeOut)
                    Text(
                      "Time's up!",
                      style: GoogleFonts.nunito(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (showRefill) ...[
                    const SizedBox(height: AppDimensions.paddingS),
                    Text(
                      'Next golden heart in $refillText',
                      style: GoogleFonts.nunito(
                        color: AppColors.neonGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.paddingL),
                  GestureDetector(
                    onTap: canRetry ? onRetry : null,
                    child: Opacity(
                      opacity: canRetry ? 1 : 0.5,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingM,
                        ),
                        decoration: AppDecorations.playButton(),
                        child: Text(
                          AppStrings.tryAgain,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onHome,
                    child: Text(
                      isDailyChallenge ? AppStrings.daily : AppStrings.map,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
