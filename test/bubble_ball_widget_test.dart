import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_word/core/widgets/bubble_ball_widget.dart';
import 'package:bubble_word/domain/entities/ball.dart';
import 'package:bubble_word/domain/entities/enums.dart';

void main() {
  testWidgets('BubbleBallWidget renders fragment ball', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BubbleBallWidget(
            ball: const Ball(
              id: '1',
              chars: 'BL',
              type: BallType.fragment,
              wordId: 'BLUE',
              category: 'Colors',
            ),
          ),
        ),
      ),
    );
    // Fill + stroke layers share the same text.
    expect(find.text('BL'), findsNWidgets(2));
  });

  testWidgets('BubbleBallWidget renders complete word ball', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BubbleBallWidget(
            ball: const Ball(
              id: '1',
              chars: 'BLUE',
              type: BallType.completeWord,
              wordId: 'BLUE',
              category: 'Colors',
            ),
          ),
        ),
      ),
    );
    expect(find.text('BLUE'), findsNWidgets(2));
  });
}
