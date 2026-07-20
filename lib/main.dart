import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/ad/ad_bloc.dart';
import 'presentation/bloc/economy/economy_bloc.dart';
import 'presentation/bloc/settings/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  getIt<AdBloc>().add(const InitializeAds());
  runApp(const BubbleWordApp());
}

class BubbleWordApp extends StatelessWidget {
  const BubbleWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<EconomyBloc>()),
        BlocProvider.value(value: getIt<AdBloc>()),
        BlocProvider.value(value: getIt<SettingsBloc>()),
      ],
      child: MaterialApp.router(
        title: 'BubbleWord',
        theme: AppTheme.darkTheme,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        routerConfig: createRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
