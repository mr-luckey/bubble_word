class NotificationMessage {
  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

enum NotificationRotationMode { alternate, sequential }

/// Flip to `true` to schedule [NotificationConfig.testCount] notifications
/// every [NotificationConfig.testInterval] (default 10s) for manual QA.
/// Production uses 17:00 / 21:00 local times and works fully offline.
const notificationTestMode = true;

class NotificationConfig {
  const NotificationConfig({
    this.enabled = true,
    this.testMode = notificationTestMode,
    this.testInterval = const Duration(seconds: 10),
    this.testCount = 5,
    this.assetPath = 'assets/notifications/notifications.json',
    this.scheduleTimes = const ['17:00', '21:00'],
    this.rotationMode = NotificationRotationMode.alternate,
    this.daysToSchedule = 14,
    this.androidChannelId = 'daily_local',
    this.androidChannelName = 'Daily reminders',
    this.pluginVersion = 'v1',
  });

  final bool enabled;

  /// When true, schedules [testCount] notifications at [testInterval] steps.
  final bool testMode;
  final Duration testInterval;
  final int testCount;

  final String assetPath;

  /// Local clock times `HH:mm`. Alternating mode walks this list by day index.
  final List<String> scheduleTimes;
  final NotificationRotationMode rotationMode;
  final int daysToSchedule;
  final String androidChannelId;
  final String androidChannelName;
  final String pluginVersion;
}
