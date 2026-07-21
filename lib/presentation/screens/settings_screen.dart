import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/utils/rate_app_service.dart';
import '../../core/utils/update_dialog.dart';
import '../../core/utils/update_service.dart';
import '../../core/widgets/app_logo.dart';
import '../bloc/economy/economy_bloc.dart';
import '../bloc/settings/settings_bloc.dart';
import '../widgets/app_screen_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '…';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = info.version);
    }
  }

  Future<void> _rateApp() async {
    final ok = await getIt<RateAppService>().requestReview();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.rateAppUnavailable)),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await getIt<UpdateService>().checkForUpdate();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (!result.checkSucceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.updateCheckFailed)),
      );
      return;
    }

    if (result.updateAvailable) {
      await showUpdateDialogIfNeeded(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.upToDate} ($_appVersion)')),
      );
    }
  }

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
                  const Center(child: AppLogo(size: 72)),
                  const SizedBox(height: AppDimensions.paddingM),
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
                  const SizedBox(height: AppDimensions.paddingM),
                  _ActionTile(
                    title: AppStrings.rateApp,
                    icon: Icons.star_rate_rounded,
                    iconColor: AppColors.neonGold,
                    onTap: _rateApp,
                  ),
                  _ActionTile(
                    title: AppStrings.checkForUpdates,
                    icon: Icons.system_update_rounded,
                    iconColor: AppColors.bubbleGlow,
                    onTap: _checkForUpdates,
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
                      '${AppStrings.version} $_appVersion',
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1040).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
