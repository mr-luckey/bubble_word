import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../bloc/economy/economy_bloc.dart';
import '../bloc/settings/settings_bloc.dart';
import '../widgets/app_screen_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EconomyBloc, EconomyBlocState>(
      builder: (context, econState) {
        return AppScreenShell(
          bottomNavIndex: 2,
          showTopBar: true,
          hearts: econState.economy.lives,
          refillSeconds: econState.economy.lifeRefillSeconds,
          body: BlocBuilder<SettingsBloc, SettingsBlocState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                children: [
                  Text(
                    AppStrings.settings.toUpperCase(),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  _SettingsTile(
                    title: AppStrings.sound,
                    value: state.sound,
                    onChanged: (v) =>
                        context.read<SettingsBloc>().add(ToggleSound(v)),
                  ),
                  _SettingsTile(
                    title: AppStrings.music,
                    value: state.music,
                    onChanged: (v) =>
                        context.read<SettingsBloc>().add(ToggleMusic(v)),
                  ),
                  _SettingsTile(
                    title: AppStrings.haptics,
                    value: state.haptics,
                    onChanged: (v) =>
                        context.read<SettingsBloc>().add(ToggleHaptics(v)),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1040).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neonPurple, width: 2),
                    ),
                    child: Text(
                      'BubbleWord v1.0.0',
                      style: GoogleFonts.nunito(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1040).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        value: value,
        activeTrackColor: AppColors.neonPurple,
        onChanged: onChanged,
      ),
    );
  }
}
