import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/bubble_ball_widget.dart';
import '../../core/widgets/nebula_background.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';

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
        body: Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _logoBall(context, 'BL', AppColors.accentBlue),
                const SizedBox(width: 8),
                _logoBall(context, 'UE', AppColors.accentGreen),
                const SizedBox(width: 8),
                _logoBall(context, 'RE', AppColors.accentRed),
                const SizedBox(width: 8),
                _logoBall(context, 'D', AppColors.accentGold),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              AppStrings.appName,
              style: AppTextStyles.heading(context).copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              AppStrings.tagline,
              style: AppTextStyles.body(context).copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            SizedBox(
              width: 200,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => LinearProgressIndicator(
                  value: _controller.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  color: AppColors.bubbleGlow,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _logoBall(BuildContext context, String chars, Color color) {
    return BubbleBallWidget(
      ball: Ball(
        id: chars,
        chars: chars,
        type: BallType.fragment,
        wordId: 'logo',
        category: 'Colors',
      ),
      showProgressRing: false,
    );
  }
}
