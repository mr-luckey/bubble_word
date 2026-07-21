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
import '../widgets/level_map_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EconomyBloc, EconomyBlocState>(
      buildWhen: (prev, curr) =>
          prev.economy.coins != curr.economy.coins ||
          prev.economy.lives != curr.economy.lives ||
          prev.economy.lifeRefillSeconds != curr.economy.lifeRefillSeconds,
      builder: (context, state) {
        final economy = state.economy;

        return AppScreenShell(
          bottomNavIndex: 0,
          showTopBar: true,
          coins: economy.coins,
          lives: economy.lives,
          lifeRefillSeconds: economy.lifeRefillSeconds,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingM,
                  0,
                  AppDimensions.paddingM,
                  AppDimensions.paddingS,
                ),
                child: BlocBuilder<EconomyBloc, EconomyBlocState>(
                  buildWhen: (prev, curr) =>
                      prev.economy.currentLevel != curr.economy.currentLevel ||
                      prev.economy.lives != curr.economy.lives,
                  builder: (context, state) {
                    return Column(
                      children: [
                        Text(
                          AppStrings.appName.toUpperCase(),
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: AppColors.neonPurple.withValues(alpha: 0.8),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.tagline,
                          style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        _PlayButton(
                          level: state.economy.currentLevel,
                          lives: state.economy.lives,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingM,
                    0,
                    AppDimensions.paddingM,
                    AppDimensions.paddingS,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1040).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neonPurple, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonPurple.withValues(alpha: 0.35),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 4),
                          child: Text(
                            'LEVEL MAP — 1000 LEVELS',
                            style: GoogleFonts.nunito(
                              color: AppColors.neonGold,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: BlocBuilder<EconomyBloc, EconomyBlocState>(
                            buildWhen: (prev, curr) =>
                                prev.economy.currentLevel !=
                                    curr.economy.currentLevel ||
                                prev.economy.levelStars !=
                                    curr.economy.levelStars ||
                                prev.economy.lives != curr.economy.lives,
                            builder: (context, mapState) {
                              return LevelMapLoader(
                                currentLevel: mapState.economy.currentLevel,
                                levelStars: mapState.economy.levelStars,
                                lives: mapState.economy.lives,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.level, required this.lives});

  final int level;
  final int lives;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _onPlay(BuildContext context) {
    if (widget.lives <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.outOfLives)),
      );
      return;
    }
    final playLevel = widget.level.clamp(1, 1000);
    context.read<EconomyBloc>().add(const SpendLife());
    context.go('/game/$playLevel');
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.lives <= 0;
    final playLevel = widget.level.clamp(1, 1000);
    final allComplete = widget.level > 1000;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: disabled || allComplete ? 1.0 : 1.0 + _pulse.value * 0.04,
        child: child,
      ),
      child: GestureDetector(
        onTap: disabled || allComplete ? null : () => _onPlay(context),
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
            decoration: AppDecorations.playButton(),
            child: Column(
              children: [
                Text(
                  allComplete
                      ? 'ALL 1000 LEVELS COMPLETE!'
                      : '${AppStrings.play} — LEVEL $playLevel',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: allComplete ? 15 : 18,
                    letterSpacing: 0.8,
                  ),
                ),
                if (disabled)
                  Text(
                    AppStrings.outOfLives,
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
