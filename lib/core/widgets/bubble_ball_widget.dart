import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Flat glossy 2D marble bubble (reference screenshot style).
class BubbleBallWidget extends StatefulWidget {
  const BubbleBallWidget({
    super.key,
    required this.ball,
    this.radius,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.showProgressRing = true,
    this.enableIdleFloat = true,
    this.mergeSnapping = false,
    this.compact = false,
  });

  final Ball ball;
  final double? radius;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final bool showProgressRing;
  final bool enableIdleFloat;
  final bool mergeSnapping;
  final bool compact;

  @override
  State<BubbleBallWidget> createState() => _BubbleBallWidgetState();
}

class _BubbleBallWidgetState extends State<BubbleBallWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _shakeController;
  late AnimationController _snapController;
  late Listenable _animListenable;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: AppDimensions.shakeAnimation,
    );
    _snapController = AnimationController(
      vsync: this,
      duration: AppDimensions.mergeAnimation,
    );
    _animListenable = Listenable.merge([
      _floatController,
      _shakeController,
      _snapController,
    ]);
    _syncFloat();
  }

  @override
  void didUpdateWidget(covariant BubbleBallWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ball.type == BallType.junk &&
        oldWidget.ball.type != BallType.junk) {
      _shakeController.forward(from: 0);
    }
    if (widget.mergeSnapping && !oldWidget.mergeSnapping) {
      _snapController.forward(from: 0);
    }
    if (widget.enableIdleFloat != oldWidget.enableIdleFloat ||
        widget.ball.isDragging != oldWidget.ball.isDragging ||
        widget.compact != oldWidget.compact) {
      _syncFloat();
    }
  }

  void _syncFloat() {
    final shouldFloat =
        !widget.compact && widget.enableIdleFloat && !widget.ball.isDragging;
    if (shouldFloat) {
      if (!_floatController.isAnimating) {
        _floatController.repeat(reverse: true);
      }
    } else if (_floatController.isAnimating) {
      _floatController.stop();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shakeController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.compact
        ? 18.0
        : widget.radius ??
            AppDimensions.scaledBallRadius(
              context,
              charCount: widget.ball.chars.length,
              isDecoy: widget.ball.type == BallType.decoy,
            );
    final size =
        AppDimensions.visualBallSize(radius) + (widget.compact ? -12 : 0);

    // Built once per ball prop change — NOT every float frame.
    final face = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarbleBallPainter(
          ball: widget.ball,
          radius: radius,
          showProgressRing: widget.showProgressRing,
          isDragging: widget.ball.isDragging,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: radius * 0.08),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    widget.ball.chars,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: AppTextStyles.ballTextStroke(radius: radius),
                  ),
                  Text(
                    widget.ball.chars,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: AppTextStyles.ballText(radius: radius),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final ballFace = RepaintBoundary(
      child: widget.onPanStart != null ||
              widget.onPanUpdate != null ||
              widget.onPanEnd != null
          ? GestureDetector(
              onPanStart: widget.onPanStart,
              onPanUpdate: widget.onPanUpdate,
              onPanEnd: widget.onPanEnd,
              child: face,
            )
          : face,
    );

    return AnimatedBuilder(
      animation: _animListenable,
      child: ballFace,
      builder: (context, child) {
        final floatY = !widget.compact &&
                widget.enableIdleFloat &&
                !widget.ball.isDragging
            ? math.sin(_floatController.value * math.pi * 2) * 2
            : 0.0;
        final shakeX = widget.ball.type == BallType.junk
            ? math.sin(_shakeController.value * math.pi * 8) * 10
            : 0.0;
        final snapScale = widget.mergeSnapping
            ? 1.0 + Curves.elasticOut.transform(_snapController.value) * 0.15
            : 1.0;
        final dragScale = widget.ball.isDragging ? 1.1 : 1.0;

        return Transform.translate(
          offset: Offset(shakeX, floatY),
          child: Transform.scale(
            scale: snapScale * dragScale,
            child: child,
          ),
        );
      },
    );
  }
}

class _MarbleBallPainter extends CustomPainter {
  _MarbleBallPainter({
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
    final center = Offset(size.width / 2, size.height / 2);
    final colors = _marbleColors();
    final base = colors.first;
    final shade = colors.last;
    final ballRect = Rect.fromCircle(center: center, radius: radius);

    canvas.save();
    canvas.clipPath(Path()..addOval(ballRect));

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center.translate(-radius * 0.12, -radius * 0.14),
          radius * 1.05,
          [
            Color.lerp(base, Colors.white, 0.16)!,
            base,
            Color.lerp(shade, Colors.black, 0.08)!,
          ],
          [0.0, 0.55, 1.0],
        ),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center.translate(radius * 0.32, radius * 0.34),
          radius * 0.92,
          [Colors.transparent, Colors.black.withValues(alpha: 0.2)],
          [0.45, 1.0],
        )
        ..blendMode = BlendMode.multiply,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.16, -radius * 0.24),
        width: radius * 1.02,
        height: radius * 0.48,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.36),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.26, -radius * 0.34),
        width: radius * 0.38,
        height: radius * 0.17,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.58),
    );

    canvas.restore();

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.45),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color =
            Color.lerp(shade, Colors.black, 0.15)!.withValues(alpha: 0.28),
    );

    if (ball.isHighlighted) {
      canvas.drawCircle(
        center,
        radius + 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.neonGold,
      );
    }

    if (ball.type == BallType.completeWord) {
      canvas.drawCircle(
        center,
        radius + 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.accentGreen,
      );
    }

    if (ball.type == BallType.junk) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.junkGrey,
      );
    }

    if (showProgressRing &&
        ball.type == BallType.wordInProgress &&
        ball.mergeTotal > 0) {
      final progress = ball.mergeProgress / ball.mergeTotal;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 3),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = AppColors.neonGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    if (ball.type == BallType.superBall) {
      for (var i = 0; i < AppColors.superBallGradient.length; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius + 3),
          (math.pi * 2 / AppColors.superBallGradient.length) * i,
          math.pi * 2 / AppColors.superBallGradient.length,
          false,
          Paint()
            ..color = AppColors.superBallGradient[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
    }
  }

  List<Color> _marbleColors() {
    if (ball.type == BallType.junk) {
      return [const Color(0xFF78909C), const Color(0xFF455A64)];
    }
    if (ball.type == BallType.superBall) {
      return [AppColors.nebulaPurple, AppColors.nebulaBlue];
    }
    if (ball.type == BallType.completeWord ||
        ball.type == BallType.wordInProgress) {
      return AppColors.marbleForWordChip(ball.chars);
    }
    return AppColors.marbleForBall(ball.id);
  }

  @override
  bool shouldRepaint(covariant _MarbleBallPainter oldDelegate) =>
      oldDelegate.ball != ball ||
      oldDelegate.radius != radius ||
      oldDelegate.isDragging != isDragging ||
      oldDelegate.showProgressRing != showProgressRing;
}
