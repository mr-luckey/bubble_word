import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Balloon-pop burst when two letter balloons merge successfully.
class MergeBlastEffect extends StatefulWidget {
  const MergeBlastEffect({
    super.key,
    required this.center,
    required this.color,
    required this.radius,
    this.celebratory = false,
    this.onComplete,
  });

  final Offset center;
  final Color color;
  final double radius;
  final bool celebratory;
  final VoidCallback? onComplete;

  @override
  State<MergeBlastEffect> createState() => _MergeBlastEffectState();
}

class _MergeBlastEffectState extends State<MergeBlastEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_BurstParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    final count = widget.celebratory ? 22 : 14;
    _particles = List.generate(count, (i) {
      final angle = (math.pi * 2 / count) * i + rng.nextDouble() * 0.4;
      final speed = widget.radius * (1.2 + rng.nextDouble() * 1.8);
      final size = widget.radius * (0.12 + rng.nextDouble() * 0.22);
      final hueShift = rng.nextDouble() * 0.15 - 0.075;
      return _BurstParticle(
        angle: angle,
        distance: speed,
        size: size,
        colorShift: hueShift,
        wobble: rng.nextDouble() * math.pi * 2,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.celebratory ? 650 : 480,
      ),
    )..forward().whenComplete(() {
        widget.onComplete?.call();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _MergeBlastPainter(
            progress: _controller.value,
            center: widget.center,
            color: widget.color,
            radius: widget.radius,
            particles: _particles,
            celebratory: widget.celebratory,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BurstParticle {
  const _BurstParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.colorShift,
    required this.wobble,
  });

  final double angle;
  final double distance;
  final double size;
  final double colorShift;
  final double wobble;
}

class _MergeBlastPainter extends CustomPainter {
  _MergeBlastPainter({
    required this.progress,
    required this.center,
    required this.color,
    required this.radius,
    required this.particles,
    required this.celebratory,
  });

  final double progress;
  final Offset center;
  final Color color;
  final double radius;
  final List<_BurstParticle> particles;
  final bool celebratory;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));

    // Flash ring — instant pop satisfaction.
    final flashAlpha = (1.0 - t * 2.2).clamp(0.0, 1.0);
    if (flashAlpha > 0) {
      final flashRadius = radius * (0.4 + t * 2.6);
      canvas.drawCircle(
        center,
        flashRadius,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            flashRadius,
            [
              Colors.white.withValues(alpha: flashAlpha * 0.95),
              color.withValues(alpha: flashAlpha * 0.55),
              Colors.transparent,
            ],
            [0.0, 0.35, 1.0],
          ),
      );
    }

    // Expanding shockwave ring.
    final ringT = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    final ringAlpha = (1.0 - ringT).clamp(0.0, 1.0) * 0.7;
    if (ringAlpha > 0.02) {
      canvas.drawCircle(
        center,
        radius * (0.6 + ringT * 2.4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (radius * 0.14).clamp(2.0, 6.0)
          ..color = Colors.white.withValues(alpha: ringAlpha),
      );
    }

    // Particle burst — balloon fragments + candy sparks.
    for (final p in particles) {
      final particleT = Curves.easeOut.transform(
        ((progress - p.colorShift * 0.08).clamp(0.0, 1.0)),
      );
      final fade = (1.0 - particleT * 1.15).clamp(0.0, 1.0);
      if (fade <= 0) continue;

      final dist = p.distance * particleT;
      final wobbleY = math.sin(particleT * math.pi * 3 + p.wobble) * radius * 0.15;
      final pos = Offset(
        center.dx + math.cos(p.angle) * dist,
        center.dy + math.sin(p.angle) * dist + wobbleY,
      );

      final particleColor = HSLColor.fromColor(color)
          .withSaturation(
            (HSLColor.fromColor(color).saturation + p.colorShift).clamp(0.0, 1.0),
          )
          .withLightness(
            (HSLColor.fromColor(color).lightness + 0.12).clamp(0.0, 0.92),
          )
          .toColor()
          .withValues(alpha: fade);

      final particleSize = p.size * (1.0 - particleT * 0.35);
      canvas.drawCircle(
        pos,
        particleSize,
        Paint()
          ..shader = ui.Gradient.radial(
            pos,
            particleSize,
            [
              Colors.white.withValues(alpha: fade * 0.85),
              particleColor,
            ],
            [0.0, 1.0],
          ),
      );
    }

    if (celebratory && progress > 0.15) {
      final starT = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
      final starAlpha = (1.0 - starT).clamp(0.0, 1.0);
      for (var i = 0; i < 6; i++) {
        final angle = (math.pi * 2 / 6) * i + progress * math.pi;
        final dist = radius * (0.8 + starT * 2.2);
        final starPos = Offset(
          center.dx + math.cos(angle) * dist,
          center.dy + math.sin(angle) * dist,
        );
        _drawStar(
          canvas,
          starPos,
          radius * 0.18 * (1.0 - starT * 0.5),
          Colors.white.withValues(alpha: starAlpha * 0.9),
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outerAngle = (math.pi * 2 / 5) * i - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 5;
      final outer = Offset(
        center.dx + math.cos(outerAngle) * size,
        center.dy + math.sin(outerAngle) * size,
      );
      final inner = Offset(
        center.dx + math.cos(innerAngle) * size * 0.42,
        center.dy + math.sin(innerAngle) * size * 0.42,
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MergeBlastPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
