import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Purple glowing stage at the bottom of the playfield.
class GlowPlatform extends StatelessWidget {
  const GlowPlatform({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _GlowPlatformPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _GlowPlatformPainter extends CustomPainter {
  const _GlowPlatformPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.88,
      height: size.height * 0.75,
    );

    canvas.drawOval(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          size.width * 0.45,
          [
            AppColors.neonPurple.withValues(alpha: 0.55),
            AppColors.nebulaPurple.withValues(alpha: 0.25),
            Colors.transparent,
          ],
          [0.0, 0.55, 1.0],
        ),
    );

    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.neonPurple.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
