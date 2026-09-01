import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';
import '../constants/app_colors.dart';

/// Reference latex balloon — vivid candy color + crisp specular + sphere depth.
class BalloonLatexPainter extends CustomPainter {
  BalloonLatexPainter({
    required this.ball,
    required this.radius,
    required this.showProgressRing,
    required this.isDragging,
  });

  final Ball ball;
  final double radius;
  final bool showProgressRing;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - radius * 0.05;
    final r = radius;
    final center = Offset(cx, cy);
    final body = Rect.fromCircle(center: center, radius: r);
    final bodyPath = Path()..addOval(body);

    final pair = _palettePair();
    final vivid = pair[0];
    final shade = pair[1];
    final gloss = Color.lerp(vivid, Colors.white, 0.22)!;

    // Soft float shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.82),
        width: r * 0.85,
        height: r * 0.22,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Colored floor reflection.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.82),
        width: r * 0.72,
        height: r * 0.18,
      ),
      Paint()
        ..color = vivid.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    if (ball.isHighlighted) {
      canvas.drawCircle(
        center,
        r + 3,
        Paint()
          ..color = AppColors.neonGold.withValues(alpha: 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    if (isDragging) {
      canvas.drawCircle(
        center,
        r + 5,
        Paint()
          ..color = vivid.withValues(alpha: 0.42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    canvas.save();
    canvas.clipPath(bodyPath);

    // Sphere body — vivid dominates; shade only on rim (no black).
    canvas.drawOval(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - r * 0.38, cy - r * 0.42),
          r * 1.35,
          [gloss, vivid, vivid, shade],
          [0.0, 0.28, 0.72, 1.0],
        ),
    );

    // Bottom-right depth — same hue, low alpha.
    canvas.drawOval(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx + r * 0.32, cy + r * 0.34),
          r * 0.82,
          [Colors.transparent, shade.withValues(alpha: 0.42)],
          [0.55, 1.0],
        ),
    );

    _drawSpecular(canvas, center, r);

    canvas.restore();

    canvas.drawOval(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: 0.28),
    );

    _drawKnotAndRibbon(canvas, center, r, shade, vivid);
    _drawRings(canvas, center, r);
  }

  void _drawSpecular(Canvas canvas, Offset c, double r) {
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(c.dx - r, c.dy - r, r * 0.82, r * 0.78),
    );

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.38);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.24, -r * 0.34),
        width: r * 0.44,
        height: r * 0.26,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-r * 0.24, -r * 0.34),
          r * 0.28,
          [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ],
          [0.0, 0.55, 1.0],
        ),
    );
    canvas.restore();

    canvas.drawCircle(
      c.translate(-r * 0.3, -r * 0.4),
      r * 0.065,
      Paint()..color = Colors.white,
    );
    canvas.restore();
  }

  void _drawKnotAndRibbon(
    Canvas canvas,
    Offset c,
    double r,
    Color shade,
    Color vivid,
  ) {
    final knotY = c.dy + r * 0.9;
    final knot = Path()
      ..moveTo(c.dx, knotY - r * 0.02)
      ..lineTo(c.dx - r * 0.09, knotY + r * 0.11)
      ..lineTo(c.dx + r * 0.09, knotY + r * 0.11)
      ..close();
    canvas.drawPath(knot, Paint()..color = shade);

    final stringColor = Color.lerp(vivid, shade, 0.35)!;
    final ribbon = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = stringColor.withValues(alpha: 0.85);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, knotY + r * 0.11)
        ..quadraticBezierTo(
          c.dx + r * 0.14,
          knotY + r * 0.22,
          c.dx - r * 0.05,
          knotY + r * 0.3,
        )
        ..quadraticBezierTo(
          c.dx - r * 0.13,
          knotY + r * 0.38,
          c.dx + r * 0.06,
          knotY + r * 0.44,
        ),
      ribbon,
    );
  }

  void _drawRings(Canvas canvas, Offset c, double r) {
    if (ball.isHighlighted) {
      canvas.drawCircle(
        c,
        r + 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.neonGold,
      );
    }
    if (ball.type == BallType.completeWord) {
      canvas.drawCircle(
        c,
        r + 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.accentGreen,
      );
    }
    if (ball.type == BallType.junk) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.junkGrey,
      );
    }
    if (showProgressRing &&
        ball.type == BallType.wordInProgress &&
        ball.mergeTotal > 0) {
      final progress = ball.mergeProgress / ball.mergeTotal;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r + 2.5),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = AppColors.neonGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
    if (ball.type == BallType.superBall) {
      for (var i = 0; i < AppColors.superBallGradient.length; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r + 2.5),
          (math.pi * 2 / AppColors.superBallGradient.length) * i,
          math.pi * 2 / AppColors.superBallGradient.length,
          false,
          Paint()
            ..color = AppColors.superBallGradient[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }
  }

  List<Color> _palettePair() {
    if (ball.type == BallType.junk) {
      return [const Color(0xFF78909C), const Color(0xFF546E7A)];
    }
    if (ball.type == BallType.superBall) {
      return [AppColors.nebulaPurple, const Color(0xFF5E35B1)];
    }
    if (ball.type == BallType.completeWord ||
        ball.type == BallType.wordInProgress) {
      return AppColors.marbleForWordChip(ball.chars);
    }
    return AppColors.marbleForBall(ball.id);
  }

  @override
  bool shouldRepaint(covariant BalloonLatexPainter oldDelegate) =>
      oldDelegate.ball != ball ||
      oldDelegate.radius != radius ||
      oldDelegate.isDragging != isDragging ||
      oldDelegate.showProgressRing != showProgressRing;
}
