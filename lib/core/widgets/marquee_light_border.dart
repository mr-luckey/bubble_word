import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/reference_theme.dart';

/// Carnival bulb frame — small chase lights (reference UI).
class MarqueeLightBorder extends StatefulWidget {
  const MarqueeLightBorder({
    super.key,
    required this.child,
    this.borderRadius = 14,
    this.bulbSize = 3,
    this.bulbSpacing = 8,
    this.padding = 4,
    this.bulbOnColor = ReferenceTheme.bulbOn,
    this.bulbOffColor = ReferenceTheme.bulbOff,
    this.glowColor = ReferenceTheme.goldDeep,
    this.bulbPalette,
    this.duration = const Duration(milliseconds: 1700),
    this.backgroundColor = ReferenceTheme.panelBg,
    this.backgroundOpacity = 0.94,
    this.frameBorderColor = ReferenceTheme.goldBorder,
    this.frameBorderWidth = 2,
  });

  final Widget child;
  final double borderRadius;
  final double bulbSize;
  final double bulbSpacing;
  final double padding;
  final Color bulbOnColor;
  final Color bulbOffColor;
  final Color glowColor;
  final List<Color>? bulbPalette;
  final Duration duration;
  final Color backgroundColor;
  final double backgroundOpacity;
  final Color frameBorderColor;
  final double frameBorderWidth;

  @override
  State<MarqueeLightBorder> createState() => _MarqueeLightBorderState();
}

class _MarqueeLightBorderState extends State<MarqueeLightBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant MarqueeLightBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (_controller.isAnimating) _controller.repeat();
    }
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
          painter: _MarqueeBulbsPainter(
            progress: _controller.value,
            borderRadius: widget.borderRadius,
            bulbSize: widget.bulbSize,
            bulbSpacing: widget.bulbSpacing,
            bulbOnColor: widget.bulbOnColor,
            bulbOffColor: widget.bulbOffColor,
            glowColor: widget.glowColor,
            bulbPalette: widget.bulbPalette,
            backgroundColor: widget.backgroundColor.withValues(
              alpha: widget.backgroundOpacity,
            ),
            frameBorderColor: widget.frameBorderColor,
            frameBorderWidth: widget.frameBorderWidth,
          ),
          child: Padding(
            padding: EdgeInsets.all(
              widget.padding + widget.bulbSize + widget.frameBorderWidth * 0.6,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _MarqueeBulbsPainter extends CustomPainter {
  _MarqueeBulbsPainter({
    required this.progress,
    required this.borderRadius,
    required this.bulbSize,
    required this.bulbSpacing,
    required this.bulbOnColor,
    required this.bulbOffColor,
    required this.glowColor,
    this.bulbPalette,
    required this.backgroundColor,
    required this.frameBorderColor,
    required this.frameBorderWidth,
  });

  final double progress;
  final double borderRadius;
  final double bulbSize;
  final double bulbSpacing;
  final Color bulbOnColor;
  final Color bulbOffColor;
  final Color glowColor;
  final List<Color>? bulbPalette;
  final Color backgroundColor;
  final Color frameBorderColor;
  final double frameBorderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = bulbSize + frameBorderWidth * 0.45;
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      Radius.circular(borderRadius),
    );

    canvas.drawRRect(innerRRect, Paint()..color = backgroundColor);

    canvas.drawRRect(
      innerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = frameBorderWidth
        ..color = frameBorderColor.withValues(alpha: 0.9),
    );

    final bulbPath = Path()..addRRect(innerRRect);
    final metric = bulbPath.computeMetrics().first;
    final perimeter = metric.length;
    final count = math.max(14, (perimeter / bulbSpacing).round());
    final head = progress * count;

    for (var i = 0; i < count; i++) {
      final tangent = metric.getTangentForOffset(perimeter * i / count);
      if (tangent == null) continue;

      final dist = _wrappedDistance(i, head, count);
      final brightness = _bulbBrightness(dist);
      final pos = tangent.position;

      Color off = bulbOffColor;
      Color on = bulbOnColor;
      if (bulbPalette != null && bulbPalette!.isNotEmpty) {
        final c = bulbPalette![i % bulbPalette!.length];
        off = Color.lerp(c, Colors.black, 0.35)!;
        on = Color.lerp(c, Colors.white, 0.45)!;
      }
      final bulbColor = Color.lerp(off, on, brightness)!;

      if (brightness > 0.45) {
        canvas.drawCircle(
          pos,
          bulbSize * 1.1,
          Paint()
            ..color = bulbColor.withValues(alpha: brightness * 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }

      canvas.drawCircle(pos, bulbSize, Paint()..color = bulbColor);

      if (brightness > 0.3) {
        canvas.drawCircle(
          pos.translate(-bulbSize * 0.18, -bulbSize * 0.18),
          bulbSize * 0.22,
          Paint()..color = Colors.white.withValues(alpha: brightness * 0.7),
        );
      }
    }
  }

  double _wrappedDistance(int i, double head, int count) {
    final raw = (i - head).abs();
    return math.min(raw, count - raw);
  }

  double _bulbBrightness(double dist) {
    if (dist < 0.5) return 1.0;
    if (dist < 1.2) return 0.62;
    if (dist < 2.0) return 0.28;
    return 0.1;
  }

  @override
  bool shouldRepaint(covariant _MarqueeBulbsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
