import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_word/core/config/notification_config.dart';
import 'package:bubble_word/core/services/local_notification_service.dart';

void main() {
  group('NotificationMessage JSON', () {
    test('parses messages and drops empty titles', () {
      const raw = '''
{
  "notifications": [
    {"id": "daily_001", "title": "Hello", "body": "Play"},
    {"id": "", "title": "Skip", "body": "x"},
    {"id": "daily_002", "title": "", "body": "x"}
  ]
}
''';
      final messages = LocalNotificationService.parseMessages(raw);
      expect(messages, hasLength(1));
      expect(messages.first.id, 'daily_001');
    });
  });

  group('schedule rotation', () {
    const config = NotificationConfig(
      scheduleTimes: ['17:00', '21:00'],
      rotationMode: NotificationRotationMode.alternate,
    );

    test('alternates 17:00 and 21:00 by day index', () {
      expect(LocalNotificationService.timeForDay(0, config)?.hour, 17);
      expect(LocalNotificationService.timeForDay(1, config)?.hour, 21);
      expect(LocalNotificationService.timeForDay(2, config)?.hour, 17);
      expect(LocalNotificationService.timeForDay(3, config)?.hour, 21);
    });
  });

  group('test mode burst', () {
    const config = NotificationConfig(
      testMode: true,
      testInterval: Duration(seconds: 10),
      testCount: 5,
    );

    test('schedules five delays at 10 second steps', () {
      expect(
        LocalNotificationService.testDelaysFromNow(config),
        const [
          Duration(seconds: 10),
          Duration(seconds: 20),
          Duration(seconds: 30),
          Duration(seconds: 40),
          Duration(seconds: 50),
        ],
      );
    });
  });

  group('fingerprint idempotency', () {
    const messages = [
      NotificationMessage(id: 'a', title: 'T', body: 'B'),
    ];

    test('same inputs produce the same fingerprint', () {
      final a = LocalNotificationService.fingerprintFor(
        timezoneName: 'America/New_York',
        times: const ['17:00', '21:00'],
        mode: NotificationRotationMode.alternate,
        days: 14,
        pluginVersion: 'v1',
        messages: messages,
      );
      final b = LocalNotificationService.fingerprintFor(
        timezoneName: 'America/New_York',
        times: const ['17:00', '21:00'],
        mode: NotificationRotationMode.alternate,
        days: 14,
        pluginVersion: 'v1',
        messages: messages,
      );
      expect(a, b);
    });

    test('timezone or copy changes the fingerprint', () {
      final base = LocalNotificationService.fingerprintFor(
        timezoneName: 'America/New_York',
        times: const ['17:00', '21:00'],
        mode: NotificationRotationMode.alternate,
        days: 14,
        pluginVersion: 'v1',
        messages: messages,
      );
      final tzChanged = LocalNotificationService.fingerprintFor(
        timezoneName: 'Europe/London',
        times: const ['17:00', '21:00'],
        mode: NotificationRotationMode.alternate,
        days: 14,
        pluginVersion: 'v1',
        messages: messages,
      );
      final copyChanged = LocalNotificationService.fingerprintFor(
        timezoneName: 'America/New_York',
        times: const ['17:00', '21:00'],
        mode: NotificationRotationMode.alternate,
        days: 14,
        pluginVersion: 'v1',
        messages: const [
          NotificationMessage(id: 'a', title: 'New', body: 'B'),
        ],
      );
      expect(base, isNot(tzChanged));
      expect(base, isNot(copyChanged));
    });
  });
}
