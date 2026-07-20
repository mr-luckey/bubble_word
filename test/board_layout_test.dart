import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_word/domain/entities/ball.dart';
import 'package:bubble_word/domain/entities/enums.dart';
import 'package:bubble_word/core/utils/board_layout.dart';
import 'package:bubble_word/core/constants/app_dimensions.dart';

void main() {
  group('BoardLayout', () {
    test('layoutFragments places balls without overlap', () {
      final balls = List.generate(
        25,
        (i) => Ball(
          id: 'b$i',
          chars: 'AB',
          type: BallType.fragment,
          wordId: 'w',
          category: 'Test',
        ),
      );

      const width = 360.0;
      const height = 480.0;
      final laid = BoardLayout.layoutFragments(
        balls: balls,
        width: width,
        height: height,
      );

      for (var i = 0; i < laid.length; i++) {
        for (var j = i + 1; j < laid.length; j++) {
          final a = laid[i];
          final b = laid[j];
          final dx = a.x - b.x;
          final dy = a.y - b.y;
          final dist = (dx * dx + dy * dy);
          final ha = AppDimensions.visualHalfExtent(
            BoardLayout.radiusFor(
              a,
              screenWidth: width,
              ballCount: balls.length,
              boardHeight: height,
            ),
          );
          final hb = AppDimensions.visualHalfExtent(
            BoardLayout.radiusFor(
              b,
              screenWidth: width,
              ballCount: balls.length,
              boardHeight: height,
            ),
          );
          final minDist = ha + hb + 16;
          expect(
            dist >= minDist * minDist * 0.92,
            true,
            reason: 'balls $i and $j overlap',
          );
        }
      }
    });
  });
}
