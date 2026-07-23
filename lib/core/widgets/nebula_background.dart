import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Space nebula background like [Bouncy Match: Bubble Word](https://play.google.com/store/apps/details?id=wordsort.merge.bubble).
class NebulaBackground extends StatelessWidget {
  const NebulaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A1628),
                Color(0xFF121B3A),
                Color(0xFF1A1040),
                Color(0xFF0D1B2A),
              ],
            ),
          ),
        ),
        const RepaintBoundary(
          child: CustomPaint(painter: _NebulaPainter()),
        ),
        const RepaintBoundary(
          child: CustomPaint(painter: _StarsPainter()),
        ),
        child,
      ],
    );
  }
}

class _NebulaPainter extends CustomPainter {
  const _NebulaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final purple = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.nebulaPurple.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.75, size.height * 0.25),
        radius: size.width * 0.45,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.25),
      size.width * 0.45,
      purple,
    );

    final blue = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.nebulaBlue.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.55),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.55),
      size.width * 0.5,
      blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  static final _rng = math.Random(7);
  static final _stars = List.generate(80, (_) {
    return (
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      r: 0.5 + _rng.nextDouble() * 1.5,
      a: 0.2 + _rng.nextDouble() * 0.6,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: s.a);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
