import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Soft stage glow on park pathway.
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
    final center = Offset(size.width / 2, size.height * 0.6);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.92,
      height: size.height * 0.85,
    );

    canvas.drawOval(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          size.width * 0.48,
          [
            AppColors.neonPurple.withValues(alpha: 0.35),
            const Color(0xFF4A2D8C).withValues(alpha: 0.15),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        ),
    );

    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.neonPurple.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
