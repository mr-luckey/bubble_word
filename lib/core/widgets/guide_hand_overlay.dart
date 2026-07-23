import 'package:flutter/material.dart';

/// Cartoon white-glove hand that demos dragging [from] → [to] on level 1.
class GuideHandOverlay extends StatefulWidget {
  const GuideHandOverlay({
    super.key,
    required this.from,
    required this.to,
  });

  final Offset from;
  final Offset to;

  @override
  State<GuideHandOverlay> createState() => _GuideHandOverlayState();
}

class _GuideHandOverlayState extends State<GuideHandOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant GuideHandOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from || oldWidget.to != widget.to) {
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // 0.00–0.15 appear/press on source
          // 0.15–0.70 drag to target
          // 0.70–0.85 release
          // 0.85–1.00 fade / reset
          late Offset pos;
          late double press;
          late double opacity;

          if (t < 0.15) {
            final p = Curves.easeOut.transform(t / 0.15);
            pos = widget.from;
            press = p;
            opacity = p;
          } else if (t < 0.70) {
            final p = Curves.easeInOut.transform((t - 0.15) / 0.55);
            pos = Offset.lerp(widget.from, widget.to, p)!;
            press = 1.0;
            opacity = 1.0;
          } else if (t < 0.85) {
            final p = (t - 0.70) / 0.15;
            pos = widget.to;
            press = 1.0 - p;
            opacity = 1.0;
          } else {
            final p = (t - 0.85) / 0.15;
            pos = widget.to;
            press = 0.0;
            opacity = 1.0 - p;
          }

          // Tip of finger sits on ball center; hand body offset below-right.
          const handSize = 72.0;
          final scale = 0.92 + press * 0.08;
          final yNudge = (1.0 - press) * 10;

          return CustomPaint(
            painter: _GloveHandPainter(
              anchor: Offset(pos.dx + 8, pos.dy + 18 + yNudge),
              size: handSize * scale,
              opacity: opacity.clamp(0.0, 1.0),
              pressing: press,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Classic cartoon white glove (pointing index finger).
class _GloveHandPainter extends CustomPainter {
  _GloveHandPainter({
    required this.anchor,
    required this.size,
    required this.opacity,
    required this.pressing,
  });

  final Offset anchor;
  final double size;
  final double opacity;
  final double pressing;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (opacity <= 0.01) return;

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(-0.35);
    canvas.scale(size / 72);

    final fill = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF90A4AE).withValues(alpha: opacity * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    final cuff = Paint()
      ..color = const Color(0xFFF5F5F5).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Soft contact shadow under fingertip when pressing.
    if (pressing > 0.2) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(-6, -28),
          width: 22 + pressing * 6,
          height: 10 + pressing * 4,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12 * opacity * pressing),
      );
    }

    final palm = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(22, 4, 28, 22)
      ..quadraticBezierTo(30, 38, 18, 48)
      ..quadraticBezierTo(4, 56, -10, 48)
      ..quadraticBezierTo(-24, 38, -20, 18)
      ..quadraticBezierTo(-16, 4, 0, 0)
      ..close();

    // Index finger (pointing up-left toward ball).
    final index = Path()
      ..moveTo(-6, -2)
      ..quadraticBezierTo(-14, -22, -10, -40)
      ..quadraticBezierTo(-6, -48, 0, -46)
      ..quadraticBezierTo(6, -42, 4, -24)
      ..quadraticBezierTo(2, -8, 6, 2)
      ..close();

    // Middle / ring stubs for cartoon glove look.
    final mid = Path()
      ..moveTo(8, 2)
      ..quadraticBezierTo(14, -10, 16, -18)
      ..quadraticBezierTo(18, -22, 22, -16)
      ..quadraticBezierTo(20, -4, 14, 8)
      ..close();

    final ring = Path()
      ..moveTo(14, 10)
      ..quadraticBezierTo(22, 2, 26, -4)
      ..quadraticBezierTo(30, -6, 30, 2)
      ..quadraticBezierTo(26, 12, 18, 16)
      ..close();

    // Thumb.
    final thumb = Path()
      ..moveTo(-12, 16)
      ..quadraticBezierTo(-28, 10, -32, 22)
      ..quadraticBezierTo(-30, 34, -16, 32)
      ..quadraticBezierTo(-10, 28, -8, 20)
      ..close();

    // Drop shadow of glove.
    canvas.save();
    canvas.translate(3, 4);
    canvas.drawPath(palm, shadow);
    canvas.drawPath(index, shadow);
    canvas.restore();

    canvas.drawPath(palm, fill);
    canvas.drawPath(palm, stroke);
    canvas.drawPath(thumb, fill);
    canvas.drawPath(thumb, stroke);
    canvas.drawPath(mid, fill);
    canvas.drawPath(mid, stroke);
    canvas.drawPath(ring, fill);
    canvas.drawPath(ring, stroke);
    canvas.drawPath(index, fill);
    canvas.drawPath(index, stroke);

    // Cuff stripes.
    final cuffRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-8, 42, 28, 14),
      const Radius.circular(6),
    );
    canvas.drawRRect(cuffRect, cuff);
    canvas.drawRRect(cuffRect, stroke);
    canvas.drawLine(
      const Offset(-4, 49),
      const Offset(16, 49),
      stroke..strokeWidth = 1.6,
    );

    // Knuckle dots.
    final dot = Paint()
      ..color = const Color(0xFFB0BEC5).withValues(alpha: opacity * 0.55);
    for (final o in const [Offset(-2, 8), Offset(8, 10), Offset(16, 14)]) {
      canvas.drawCircle(o, 1.8, dot);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GloveHandPainter oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.size != size ||
      oldDelegate.opacity != opacity ||
      oldDelegate.pressing != pressing;
}
