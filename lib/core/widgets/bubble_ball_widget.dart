import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import 'balloon_latex_painter.dart';

/// Reference-style 3D latex letter balloons.
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
  late AnimationController _beatController;
  late Listenable _animListenable;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: AppDimensions.shakeAnimation,
    );
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animListenable = Listenable.merge([
      _floatController,
      _shakeController,
      _snapController,
      _beatController,
    ]);
    _syncFloat();
    _syncBeat();
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
    if (widget.ball.isHighlighted != oldWidget.ball.isHighlighted ||
        widget.ball.isDragging != oldWidget.ball.isDragging) {
      _syncBeat();
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

  void _syncBeat() {
    final shouldBeat =
        widget.ball.isHighlighted && !widget.ball.isDragging && !widget.compact;
    if (shouldBeat) {
      if (!_beatController.isAnimating) {
        _beatController.repeat(reverse: true);
      }
    } else if (_beatController.isAnimating) {
      _beatController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shakeController.dispose();
    _snapController.dispose();
    _beatController.dispose();
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
    final widgetSize = widget.compact
        ? Size(
            AppDimensions.balloonWidgetSize(radius).width - 12,
            AppDimensions.balloonWidgetSize(radius).height - 12,
          )
        : AppDimensions.balloonWidgetSize(radius);

    final face = SizedBox(
      width: widgetSize.width,
      height: widgetSize.height,
      child: CustomPaint(
        isComplex: true,
        painter: BalloonLatexPainter(
          ball: widget.ball,
          radius: radius,
          showProgressRing: widget.showProgressRing,
          isDragging: widget.ball.isDragging,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: radius * 0.1),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    widget.ball.chars,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: AppTextStyles.ballTextShadow(radius: radius),
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
      child:
          widget.onPanStart != null ||
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
        final phase = _floatController.value * math.pi * 2;
        final floatY =
            !widget.compact && widget.enableIdleFloat && !widget.ball.isDragging
            ? math.sin(phase) * 1.8
            : 0.0;

        final shakeX = widget.ball.type == BallType.junk
            ? math.sin(_shakeController.value * math.pi * 8) * 8
            : 0.0;

        final snapT = _snapController.value;
        final snapScale = widget.mergeSnapping
            ? 1.0 +
                (snapT < 0.3
                    ? -Curves.easeIn.transform(snapT / 0.3) * 0.14
                    : Curves.elasticOut.transform((snapT - 0.3) / 0.7) * 0.2)
            : 1.0;

        final beatScale = widget.ball.isHighlighted && !widget.ball.isDragging
            ? 1.0 + Curves.easeInOut.transform(_beatController.value) * 0.06
            : 1.0;
        final dragScale = widget.ball.isDragging ? 1.08 : 1.0;

        return Transform.translate(
          offset: Offset(shakeX, floatY),
          child: Transform.scale(
            scale: snapScale * dragScale * beatScale,
            child: child,
          ),
        );
      },
    );
  }
}
