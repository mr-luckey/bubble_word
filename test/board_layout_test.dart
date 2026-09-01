import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_word/core/constants/app_dimensions.dart';
import 'package:bubble_word/domain/entities/ball.dart';
import 'package:bubble_word/domain/entities/enums.dart';
import 'package:bubble_word/core/utils/board_layout.dart';

void main() {
  group('BoardLayout', () {
    test('layoutFragments fills playfield edge-to-edge without overlap', () {
      final balls = List.generate(
        27,
        (i) => Ball(
          id: 'b$i',
          chars: 'AB',
          type: BallType.fragment,
          wordId: 'w',
          category: 'Test',
        ),
      );

      const width = 360.0;
      const height = 520.0;
      final laid = BoardLayout.layoutFragments(
        balls: balls,
        width: width,
        height: height,
      );

      expect(laid.length, balls.length);

      final r = BoardLayout.uniformBoardRadius(
        ballCount: balls.length,
        width: width,
        height: height,
      );
      final rx = AppDimensions.balloonHalfWidth(r);
      final ry = AppDimensions.balloonHalfHeight(r);

      final minY = laid.map((b) => b.y).reduce(math.min);
      final maxY = laid.map((b) => b.y).reduce(math.max);
      expect(minY, closeTo(ry, 2),
          reason: 'top row should start at playfield top');
      expect(maxY, closeTo(height - ry, 4),
          reason: 'bottom row should reach playfield bottom');

      final minX = laid.map((b) => b.x).reduce(math.min);
      final maxX = laid.map((b) => b.x).reduce(math.max);
      expect(minX - rx, closeTo(0, 2),
          reason: 'leftmost balloon should touch playfield edge');
      expect(maxX + rx, closeTo(width, 2),
          reason: 'rightmost balloon should touch playfield edge');

      for (var i = 0; i < laid.length; i++) {
        for (var j = i + 1; j < laid.length; j++) {
          final a = laid[i];
          final b = laid[j];
          final dx = (a.x - b.x).abs();
          final dy = (a.y - b.y).abs();
          expect(dx >= 2 * rx - 0.5 || dy >= 2 * ry - 0.5, isTrue,
              reason: 'balls $i and $j overlap');
        }
      }

      final edgeBalls =
          laid.where((b) => b.x < width * 0.22 || b.x > width * 0.78);
      expect(edgeBalls.length, greaterThan(2),
          reason: 'grid should reach both sides of playfield');
    });
  });
}
