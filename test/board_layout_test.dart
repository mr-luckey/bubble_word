import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_word/domain/entities/ball.dart';
import 'package:bubble_word/domain/entities/enums.dart';
import 'package:bubble_word/core/utils/board_layout.dart';

void main() {
  group('BoardLayout', () {
    test('layoutFragments packs balls at bottom without overlap', () {
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

      final maxY = laid.map((b) => b.y).reduce(math.max);
      expect(maxY, greaterThan(height * 0.55),
          reason: 'balls should settle in lower half of board');

      for (var i = 0; i < laid.length; i++) {
        final a = laid[i];
        expect(a.x - r, greaterThanOrEqualTo(-1),
            reason: 'ball $i clips left edge');
        expect(a.x + r, lessThanOrEqualTo(width + 1),
            reason: 'ball $i clips right edge');

        for (var j = i + 1; j < laid.length; j++) {
          final b = laid[j];
          final dx = a.x - b.x;
          final dy = a.y - b.y;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dx.abs() < 0.1 && dy.abs() < 0.1) continue;
          if (dx.abs() < 0.1 || dy.abs() < 0.1) {
            expect(
              dist >= r * 2 - 0.5,
              true,
              reason: 'balls $i and $j overlap (dist=$dist, min=${r * 2})',
            );
          }
        }
      }
    });
  });
}
