import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_word/core/services/analytics_service.dart';

void main() {
  group('AnalyticsService.sanitize', () {
    test('keeps primitive values', () {
      expect(
        AnalyticsService.sanitize({
          'level_number': 3,
          'difficulty': 'easy',
          'ok': true,
        }),
        {'level_number': 3, 'difficulty': 'easy', 'ok': true},
      );
    });

    test('drops keys that look like PII', () {
      expect(
        AnalyticsService.sanitize({
          'email': 'user@example.com',
          'level_number': 1,
          'auth_token': 'secret',
        }),
        {'level_number': 1},
      );
    });
  });
}
