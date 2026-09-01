import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Oval latex balloon — inflated candy color with soft latex sheen.
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
    final cy = size.height / 2 - radius * 0.06;
    final rx = AppDimensions.balloonHalfWidth(radius);
    final ry = AppDimensions.balloonHalfHeight(radius);
    final center = Offset(cx, cy);
    final body = Rect.fromCenter(center: center, width: 2 * rx, height: 2 * ry);
    final bodyPath = Path()..addOval(body);

    final pair = _palettePair();
    final vivid = pair[0];
    final shade = pair[1];
    final gloss = Color.lerp(vivid, Colors.white, 0.1)!;

    // Soft colored floor shadow — not a dark ring.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + ry * 0.9),
        width: rx * 1.35,
        height: ry * 0.2,
      ),
      Paint()
        ..color = shade.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + ry * 0.88),
        width: rx * 1.2,
        height: ry * 0.16,
      ),
      Paint()
        ..color = vivid.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    if (ball.isHighlighted) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: 2 * (rx + 3),
          height: 2 * (ry + 3),
        ),
        Paint()
          ..color = AppColors.neonGold.withValues(alpha: 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    if (isDragging) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: 2 * (rx + 5),
          height: 2 * (ry + 5),
        ),
        Paint()
          ..color = vivid.withValues(alpha: 0.42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    canvas.save();
    canvas.clipPath(bodyPath);

    canvas.drawOval(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - rx * 0.34, cy - ry * 0.38),
          math.max(rx, ry) * 1.42,
          [gloss, vivid, vivid, shade, shade.withValues(alpha: 0.92)],
          [0.0, 0.22, 0.58, 0.86, 1.0],
        ),
    );

    canvas.drawOval(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx + rx * 0.28, cy + ry * 0.3),
          math.max(rx, ry) * 0.78,
          [Colors.transparent, shade.withValues(alpha: 0.36)],
          [0.5, 1.0],
        ),
    );

    canvas.restore();

    _drawKnotAndRibbon(canvas, center, rx, ry, shade, vivid);
    _drawRings(canvas, center, rx, ry);
  }

  void _drawKnotAndRibbon(
    Canvas canvas,
    Offset c,
    double rx,
    double ry,
    Color shade,
    Color vivid,
  ) {
    final knotY = c.dy + ry * 0.9;
    final knot = Path()
      ..moveTo(c.dx - rx * 0.1, knotY)
      ..quadraticBezierTo(c.dx, knotY - ry * 0.05, c.dx + rx * 0.1, knotY)
      ..lineTo(c.dx + rx * 0.14, knotY + ry * 0.09)
      ..quadraticBezierTo(c.dx, knotY + ry * 0.12, c.dx - rx * 0.14, knotY + ry * 0.09)
      ..close();
    canvas.drawPath(
      knot,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(c.dx, knotY - ry * 0.04),
          Offset(c.dx, knotY + ry * 0.1),
          [Color.lerp(vivid, Colors.white, 0.08)!, shade],
        ),
    );

    final stringColor = Color.lerp(vivid, shade, 0.45)!;
    final ribbon = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = stringColor.withValues(alpha: 0.72);
    final stringEnd = knotY + ry * 0.36;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, knotY + ry * 0.08)
        ..quadraticBezierTo(
          c.dx + rx * 0.18,
          knotY + ry * 0.16,
          c.dx - rx * 0.04,
          knotY + ry * 0.24,
        )
        ..quadraticBezierTo(
          c.dx - rx * 0.14,
          knotY + ry * 0.3,
          c.dx + rx * 0.06,
          stringEnd,
        ),
      ribbon,
    );
  }

  void _drawRings(Canvas canvas, Offset c, double rx, double ry) {
    final ring = Rect.fromCenter(
      center: c,
      width: 2 * (rx + 2),
      height: 2 * (ry + 2),
    );

    if (ball.isHighlighted) {
      canvas.drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.neonGold,
      );
    }
    if (ball.type == BallType.completeWord) {
      canvas.drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.accentGreen,
      );
    }
    if (ball.type == BallType.junk) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: 2 * rx, height: 2 * ry),
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
        ring,
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
          ring,
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
