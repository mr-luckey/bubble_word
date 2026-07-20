import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../bloc/settings/settings_bloc.dart';
import '../widgets/bottom_nav_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<SettingsBloc, SettingsBlocState>(
                builder: (context, state) {
                  return ListView(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    children: [
                      Text(AppStrings.settings, style: AppTextStyles.heading(context)),
                      SwitchListTile(
                        title: Text(AppStrings.sound, style: AppTextStyles.body(context)),
                        value: state.sound,
                        onChanged: (v) =>
                            context.read<SettingsBloc>().add(ToggleSound(v)),
                      ),
                      SwitchListTile(
                        title: Text(AppStrings.music, style: AppTextStyles.body(context)),
                        value: state.music,
                        onChanged: (v) =>
                            context.read<SettingsBloc>().add(ToggleMusic(v)),
                      ),
                      SwitchListTile(
                        title: Text(AppStrings.haptics, style: AppTextStyles.body(context)),
                        value: state.haptics,
                        onChanged: (v) =>
                            context.read<SettingsBloc>().add(ToggleHaptics(v)),
                      ),
                    ],
                  );
                },
              ),
            ),
            const BottomNavBar(currentIndex: 3),
          ],
        ),
      ),
    );
  }
}
