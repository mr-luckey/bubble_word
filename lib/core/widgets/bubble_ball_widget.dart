import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Glossy 3D glass bubble — styled after Bouncy Match reference app.
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
  /// When set, keeps render size in sync with [BoardLayout] placement.
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

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.enableIdleFloat && !widget.ball.isDragging) {
      _floatController.repeat(reverse: true);
    }
    _shakeController = AnimationController(
      vsync: this,
      duration: AppDimensions.shakeAnimation,
    );
    _snapController = AnimationController(
      vsync: this,
      duration: AppDimensions.mergeAnimation,
    );
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
              isWord: widget.ball.type == BallType.completeWord ||
                  widget.ball.type == BallType.wordInProgress,
              isSuper: widget.ball.type == BallType.superBall,
              isDecoy: widget.ball.type == BallType.decoy,
            );
    final size = AppDimensions.visualBallSize(radius) + (widget.compact ? -12 : 0);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatController,
        _shakeController,
        _snapController,
      ]),
      builder: (context, _) {
        final floatY = !widget.compact &&
                widget.enableIdleFloat &&
                !widget.ball.isDragging
            ? math.sin(_floatController.value * math.pi * 2) * 4
            : 0.0;
        final shakeX = widget.ball.type == BallType.junk
            ? math.sin(_shakeController.value * math.pi * 8) * 10
            : 0.0;
        final snapScale = widget.mergeSnapping
            ? 1.0 + Curves.elasticOut.transform(_snapController.value) * 0.2
            : 1.0;
        final dragScale = widget.ball.isDragging ? 1.15 : 1.0;

        return Transform.translate(
          offset: Offset(shakeX, floatY),
          child: Transform.scale(
            scale: snapScale * dragScale,
            child: GestureDetector(
              onPanStart: widget.onPanStart,
              onPanUpdate: widget.onPanUpdate,
              onPanEnd: widget.onPanEnd,
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _GlassBubblePainter(
                    ball: widget.ball,
                    radius: radius,
                    showProgressRing: widget.showProgressRing,
                    isDragging: widget.ball.isDragging,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: radius * 0.12),
                        child: Text(
                          _displayText(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: AppTextStyles.ballText(context, radius: radius),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _displayText() => widget.ball.chars;
}

class _GlassBubblePainter extends CustomPainter {
  _GlassBubblePainter({
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
    final colors = _innerColors();

    // Outer glow (blue rim like reference)
    if (ball.type != BallType.junk) {
      final glowPaint = Paint()
        ..color = (isDragging ? AppColors.bubbleGlow : AppColors.bubbleGlow)
            .withValues(alpha: isDragging ? 0.7 : 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDragging ? 16 : 10);
      canvas.drawCircle(center, radius + 6, glowPaint);
    }

    // Drop shadow
    canvas.drawCircle(
      center.translate(0, 4),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Main glass sphere
    final spherePaint = Paint()
      ..shader = ui.Gradient.radial(
        center.translate(-radius * 0.25, -radius * 0.3),
        radius * 1.3,
        [
          Colors.white.withValues(alpha: 0.85),
          colors[0].withValues(alpha: 0.95),
          colors.length > 1 ? colors[1] : colors[0],
          colors[0].withValues(alpha: 0.9),
        ],
        [0.0, 0.2, 0.65, 1.0],
      );
    canvas.drawCircle(center, radius, spherePaint);

    // Inner depth
    final innerShadow = Paint()
      ..shader = ui.Gradient.radial(
        center.translate(radius * 0.2, radius * 0.25),
        radius * 0.9,
        [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.25),
        ],
        [0.5, 1.0],
      );
    canvas.drawCircle(center, radius, innerShadow);

    // Specular highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.22, -radius * 0.28),
        width: radius * 0.55,
        height: radius * 0.35,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // Rim light
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(center, radius - 1, rimPaint);

    if (ball.isHighlighted) {
      final hintPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.accentGold;
      canvas.drawCircle(center, radius + 5, hintPaint);
    }

    if (ball.type == BallType.completeWord) {
      final donePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.accentGreen.withValues(alpha: 0.8);
      canvas.drawCircle(center, radius + 4, donePaint);
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
        Rect.fromCircle(center: center, radius: radius + 7),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = AppColors.accentGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    if (ball.type == BallType.superBall) {
      for (var i = 0; i < AppColors.superBallGradient.length; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius + 5),
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

  List<Color> _innerColors() {
    if (ball.type == BallType.junk) {
      return [AppColors.junkGrey, const Color(0xFF4A5568)];
    }
    if (ball.type == BallType.superBall) {
      return [AppColors.nebulaPurple, AppColors.bubbleCore];
    }
    final cat = AppColors.forCategory(ball.category);
    return [cat[0], cat.length > 1 ? cat[1] : AppColors.bubbleDeep];
  }

  @override
  bool shouldRepaint(covariant _GlassBubblePainter oldDelegate) =>
      oldDelegate.ball != ball ||
      oldDelegate.radius != radius ||
      oldDelegate.isDragging != isDragging;
}
