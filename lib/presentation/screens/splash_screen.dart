import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/nebula_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    Future.delayed(
      const Duration(milliseconds: 2500),
      () {
        if (mounted) context.go('/home');
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: const AppLogo(size: 160),
                      ),
                      const SizedBox(height: AppDimensions.paddingL),
                      Text(
                        AppStrings.appName,
                        style: AppTextStyles.heading(context)
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppDimensions.paddingS),
                      Text(
                        AppStrings.tagline,
                        style: AppTextStyles.body(context)
                            .copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: AppDimensions.paddingL),
                      SizedBox(
                        width: 200,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (_, __) => LinearProgressIndicator(
                            value: _controller.value,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            color: AppColors.bubbleGlow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
