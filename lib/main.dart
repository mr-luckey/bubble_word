import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/audio_service.dart';
import 'presentation/bloc/ad/ad_bloc.dart';
import 'presentation/bloc/economy/economy_bloc.dart';
import 'presentation/bloc/settings/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  getIt<AdBloc>().add(const InitializeAds());
  runApp(const BubbleWordApp());
}

class BubbleWordApp extends StatefulWidget {
  const BubbleWordApp({super.key});

  @override
  State<BubbleWordApp> createState() => _BubbleWordAppState();
}

class _BubbleWordAppState extends State<BubbleWordApp> {
  @override
  void initState() {
    super.initState();
    final settings = getIt<SettingsBloc>().state;
    getIt<AudioService>().syncSettings(
      sound: settings.sound,
      music: settings.music,
      haptics: settings.haptics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<EconomyBloc>()),
        BlocProvider.value(value: getIt<AdBloc>()),
        BlocProvider.value(value: getIt<SettingsBloc>()),
      ],
      child: BlocListener<SettingsBloc, SettingsBlocState>(
        listener: (context, state) {
          getIt<AudioService>().syncSettings(
            sound: state.sound,
            music: state.music,
            haptics: state.haptics,
          );
        },
        child: MaterialApp.router(
          title: 'BubbleWord',
          theme: AppTheme.darkTheme,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          routerConfig: createRouter(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
