import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/confetti_painter.dart';
import '../../core/widgets/nebula_background.dart';
import '../bloc/game/game_bloc.dart';

class LevelCompleteOverlay extends StatefulWidget {
  const LevelCompleteOverlay({
    super.key,
    required this.gameState,
    required this.onNext,
    required this.onHome,
  });

  final GameWon gameState;
  final VoidCallback onNext;
  final VoidCallback onHome;

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDimensions.popAnimation,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.gameState.gameState.level.words
        .map((w) => w.text)
        .join(' · ');

    return NebulaBackground(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: ConfettiPainter(_controller.value),
              size: MediaQuery.sizeOf(context),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Transform.scale(
                scale: 0.5 + _controller.value * 0.5,
                child: Opacity(
                  opacity: _controller.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.levelComplete,
                        style: AppTextStyles.heading(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (i) => Icon(
                            Icons.star,
                            size: 48,
                            color: i < widget.gameState.stars
                                ? AppColors.accentGold
                                : Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      Text(
                        '+${widget.gameState.coinsEarned} ${AppStrings.coins}',
                        style: AppTextStyles.subheading(context).copyWith(
                          color: AppColors.accentGold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingS),
                      Text(
                        words,
                        style: AppTextStyles.body(context).copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingL),
                      GestureDetector(
                        onTap: widget.onNext,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: AppDimensions.paddingM,
                          ),
                          decoration: AppDecorations.playButton(),
                          child: Text(
                            AppStrings.nextLevel,
                            style: AppTextStyles.button(context),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onHome,
                        child: Text(
                          AppStrings.map,
                          style: AppTextStyles.body(context).copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
