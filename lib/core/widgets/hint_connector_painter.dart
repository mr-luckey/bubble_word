import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../../domain/entities/ball.dart';

/// Dotted line between two hint-highlighted balls (PDF Section 8).
class HintConnectorPainter extends CustomPainter {
  HintConnectorPainter({required this.ballA, required this.ballB});

  final Ball ballA;
  final Ball ballB;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentGold.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dash = 6.0;
    const gap = 4.0;
    final start = Offset(ballA.x, ballA.y);
    final end = Offset(ballB.x, ballB.y);
    final total = (end - start).distance;
    if (total <= 0) return;

    final dir = (end - start) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final segEnd = math.min(drawn + dash, total);
      canvas.drawLine(
        start + dir * drawn,
        start + dir * segEnd,
        paint,
      );
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant HintConnectorPainter oldDelegate) =>
      oldDelegate.ballA.x != ballA.x ||
      oldDelegate.ballA.y != ballA.y ||
      oldDelegate.ballB.x != ballB.x ||
      oldDelegate.ballB.y != ballB.y;
}
