import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Lightweight confetti burst for win overlay (PDF Section 11).
class ConfettiPainter extends CustomPainter {
  ConfettiPainter(this.progress);

  final double progress;
  static final _random = math.Random(42);
  static final _particles = List.generate(40, (_) {
    final angle = _random.nextDouble() * math.pi * 2;
    final speed = 80 + _random.nextDouble() * 120;
    return (
      color: AppColors.superBallGradient[_random.nextInt(5)],
      vx: math.cos(angle) * speed,
      vy: math.sin(angle) * speed - 60,
      size: 4 + _random.nextDouble() * 6,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = progress.clamp(0.0, 1.0);
    for (final p in _particles) {
      final x = center.dx + p.vx * t;
      final y = center.dy + p.vy * t + 120 * t * t;
      final paint = Paint()
        ..color = p.color.withValues(alpha: 1 - t);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
