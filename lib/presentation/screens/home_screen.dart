import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/nebula_background.dart';
import '../bloc/economy/economy_bloc.dart';
import '../widgets/top_status_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EconomyBloc, EconomyBlocState>(
      builder: (context, state) {
        final currentLevel = state.economy.currentLevel;
        return NebulaBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
              children: [
                TopStatusBar(
                  coins: state.economy.coins,
                  lives: state.economy.lives,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: Column(
                      children: [
                        Text(
                          'Level Map',
                          style: AppTextStyles.heading(context).copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppDimensions.paddingL),
                        _WindingLevelPath(
                          currentLevel: currentLevel,
                          levelStars: state.economy.levelStars,
                        ),
                        const SizedBox(height: AppDimensions.paddingL),
                        _PlayButton(level: currentLevel),
                      ],
                    ),
                  ),
                ),
                const BottomNavBar(currentIndex: 0),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.level});
  final int level;

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: 1.0 + _pulse.value * 0.05,
        child: child,
      ),
      child: GestureDetector(
        onTap: () => context.go('/game/${widget.level}'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 48,
            vertical: AppDimensions.paddingM,
          ),
          decoration: AppDecorations.playButton(),
          child: Text(
            '${AppStrings.play} — Lv ${widget.level}',
            style: AppTextStyles.button(context),
          ),
        ),
      ),
    );
  }
}

/// Winding S-curve level path (PDF Screen 02).
class _WindingLevelPath extends StatelessWidget {
  const _WindingLevelPath({
    required this.currentLevel,
    required this.levelStars,
  });

  final int currentLevel;
  final Map<int, int> levelStars;

  @override
  Widget build(BuildContext context) {
    final start = (currentLevel - 4).clamp(1, 996);
    final count = 12;
    final levels = List.generate(count, (i) => start + i).where((l) => l <= 1000);

    return SizedBox(
      height: levels.length * 72.0,
      child: CustomPaint(
        painter: _PathLinePainter(levelCount: levels.length),
        child: Stack(
          children: [
            for (var i = 0; i < levels.length; i++)
              Positioned(
                left: _nodeX(i, MediaQuery.sizeOf(context).width - 32),
                top: i * 72.0 + 8,
                child: _LevelNode(
                  level: levels.elementAt(i),
                  stars: levelStars[levels.elementAt(i)] ?? 0,
                  isCurrent: levels.elementAt(i) == currentLevel,
                  isLocked: levels.elementAt(i) > currentLevel,
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _nodeX(int index, double width) {
    final side = index.isEven ? 0.15 : 0.65;
    return width * side;
  }
}

class _PathLinePainter extends CustomPainter {
  _PathLinePainter({required this.levelCount});

  final int levelCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (levelCount < 2) return;
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < levelCount - 1; i++) {
      final x1 = size.width * (i.isEven ? 0.15 : 0.65) + 28;
      final y1 = i * 72.0 + 36;
      final x2 = size.width * ((i + 1).isEven ? 0.15 : 0.65) + 28;
      final y2 = (i + 1) * 72.0 + 36;
      if (i == 0) path.moveTo(x1, y1);
      path.cubicTo(x1, y1 + 36, x2, y2 - 36, x2, y2);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathLinePainter oldDelegate) =>
      oldDelegate.levelCount != levelCount;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.stars,
    required this.isCurrent,
    required this.isLocked,
  });

  final int level;
  final int stars;
  final bool isCurrent;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : () => context.go('/game/$level'),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCurrent
              ? AppColors.accentBlue
              : isLocked
                  ? AppColors.border
                  : AppColors.cardBg,
          border: Border.all(
            color: isCurrent ? AppColors.accentCyan : AppColors.border,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.45),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$level',
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (stars > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  math.min(stars, 3),
                  (_) => const Icon(Icons.star, size: 8, color: AppColors.accentGold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
