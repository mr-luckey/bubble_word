import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../config/notification_config.dart';

typedef NotificationTapCallback = void Function(String? payload);

/// Fully offline local notifications. Idempotent. Device-local timezone.
class LocalNotificationService {
  LocalNotificationService({
    required SharedPreferences prefs,
    NotificationConfig config = const NotificationConfig(),
    FlutterLocalNotificationsPlugin? plugin,
    this.onTap,
  })  : _config = config,
        _prefs = prefs,
        _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const fingerprintKey = 'local_notification_fingerprint_v1';

  final NotificationConfig _config;
  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin;
  NotificationTapCallback? onTap;

  bool _initialized = false;
  String? _pendingLaunchPayload;

  void attachTapHandler(NotificationTapCallback handler) {
    onTap = handler;
    final pending = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    if (pending != null) handler(pending);
  }

  Future<void> init() async {
    if (!_config.enabled || _initialized) return;
    try {
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation(await localTimezoneName()));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (response) {
          onTap?.call(response.payload);
        },
      );

      await _ensureAndroidChannel();

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final payload = launch!.notificationResponse?.payload;
        if (onTap != null) {
          onTap!(payload);
        } else {
          _pendingLaunchPayload = payload;
        }
      }

      _initialized = true;
    } catch (error, stack) {
      debugPrint('LocalNotificationService.init failed: $error\n$stack');
    }
  }

  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final notificationsOk =
            await android.requestNotificationsPermission() ?? true;
        if (!notificationsOk) {
          debugPrint('Notification permission denied (POST_NOTIFICATIONS).');
          return false;
        }

        if (_config.testMode) {
          final canExact =
              await android.canScheduleExactNotifications() ?? true;
          if (!canExact) {
            final exactOk =
                await android.requestExactAlarmsPermission() ?? false;
            if (!exactOk) {
              debugPrint(
                'Exact alarm permission denied. Test notifications may be '
                'delayed; enable Alarms & reminders in system settings.',
              );
            }
          }
        }
        return true;
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final iosOk = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (iosOk != true) {
          debugPrint('Notification permission denied (alert/badge/sound).');
        }
        return iosOk ?? false;
      }

      return true;
    } catch (error, stack) {
      debugPrint('Notification permission failed: $error\n$stack');
      return false;
    }
  }

  Future<void> _ensureAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        _config.androidChannelId,
        _config.androidChannelName,
        description: 'BubbleWord reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  NotificationDetails _testNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _config.androidChannelId,
        _config.androidChannelName,
        channelDescription: 'BubbleWord reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        ticker: 'BubbleWord test notification',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  Future<AndroidScheduleMode> _androidScheduleModeForTest() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await android?.canScheduleExactNotifications() ?? true;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Safe to call on every launch. Does not create duplicates.
  Future<int> scheduleNotifications() async {
    if (!_config.enabled) return 0;
    await init();
    if (!_initialized) return 0;

    final allowed = await requestPermission();
    if (!allowed) return 0;

    try {
      final messages = await loadMessages();
      if (messages.isEmpty) return 0;

      if (_config.testMode) {
        await _plugin.cancelAll();
        final count = await _scheduleTestBurst(messages);
        debugPrint(
          'Notification test mode: scheduled $count notifications '
          'every ${_config.testInterval.inSeconds}s',
        );
        return count;
      }

      final fingerprint = await buildFingerprint(messages);
      if (_prefs.getString(fingerprintKey) == fingerprint) {
        final pending = await _plugin.pendingNotificationRequests();
        if (pending.isNotEmpty) return pending.length;
      }

      await _plugin.cancelAll();
      final count = await _scheduleUpcoming(messages);
      await _prefs.setString(fingerprintKey, fingerprint);
      return count;
    } catch (error, stack) {
      debugPrint('scheduleNotifications failed: $error\n$stack');
      return 0;
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      await _prefs.remove(fingerprintKey);
    } catch (error, stack) {
      debugPrint('cancelAll notifications failed: $error\n$stack');
    }
  }

  @visibleForTesting
  Future<List<NotificationMessage>> loadMessages() async {
    final raw = await rootBundle.loadString(_config.assetPath);
    return parseMessages(raw);
  }

  @visibleForTesting
  static List<NotificationMessage> parseMessages(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded['notifications'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationMessage.fromJson)
        .where((m) => m.id.isNotEmpty && m.title.isNotEmpty)
        .toList();
  }

  @visibleForTesting
  Future<String> buildFingerprint(List<NotificationMessage> messages) async {
    return fingerprintFor(
      timezoneName: await localTimezoneName(),
      times: _config.scheduleTimes,
      mode: _config.rotationMode,
      days: _config.daysToSchedule,
      pluginVersion: _config.pluginVersion,
      testMode: _config.testMode,
      testIntervalSeconds: _config.testInterval.inSeconds,
      testCount: _config.testCount,
      messages: messages,
    );
  }

  @visibleForTesting
  static String fingerprintFor({
    required String timezoneName,
    required List<String> times,
    required NotificationRotationMode mode,
    required int days,
    required String pluginVersion,
    bool testMode = false,
    int testIntervalSeconds = 0,
    int testCount = 0,
    required List<NotificationMessage> messages,
  }) {
    return jsonEncode({
      'tz': timezoneName,
      'times': times,
      'mode': mode.name,
      'days': days,
      'plugin': pluginVersion,
      'testMode': testMode,
      'testIntervalSeconds': testIntervalSeconds,
      'testCount': testCount,
      'messages': messages
          .map((m) => {'id': m.id, 'title': m.title, 'body': m.body})
          .toList(),
    });
  }

  /// Schedules [testCount] notifications at [testInterval] steps from now.
  /// Also fires one immediate notification so QA can confirm delivery.
  Future<int> _scheduleTestBurst(List<NotificationMessage> messages) async {
    var scheduled = 0;
    final now = tz.TZDateTime.now(tz.local);
    final androidScheduleMode = await _androidScheduleModeForTest();
    final details = _testNotificationDetails();
    final first = messages.first;

    await _plugin.show(
      id: 8998,
      title: '[TEST NOW] ${first.title}',
      body: first.body,
      notificationDetails: details,
      payload: first.id,
    );
    scheduled++;

    for (var i = 0; i < _config.testCount; i++) {
      final fire = now.add(_config.testInterval * (i + 1));
      final message = messages[i % messages.length];
      await _plugin.zonedSchedule(
        id: 9000 + i,
        title: '[TEST ${i + 1}/${_config.testCount}] ${message.title}',
        body: message.body,
        scheduledDate: fire,
        notificationDetails: details,
        androidScheduleMode: androidScheduleMode,
        payload: message.id,
      );
      scheduled++;
    }
    return scheduled;
  }

  @visibleForTesting
  static List<Duration> testDelaysFromNow(NotificationConfig config) {
    return List.generate(
      config.testCount,
      (i) => config.testInterval * (i + 1),
    );
  }

  Future<int> _scheduleUpcoming(List<NotificationMessage> messages) async {
    var scheduled = 0;
    final now = tz.TZDateTime.now(tz.local);
    for (var day = 0; day < _config.daysToSchedule; day++) {
      final time = timeForDay(day, _config);
      if (time == null) continue;
      var fire = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      ).add(Duration(days: day));
      if (!fire.isAfter(now)) continue;
      final message = messages[day % messages.length];
      await _plugin.zonedSchedule(
        id: day + 1,
        title: message.title,
        body: message.body,
        scheduledDate: fire,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _config.androidChannelId,
            _config.androidChannelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: message.id,
      );
      scheduled++;
    }
    return scheduled;
  }

  @visibleForTesting
  static ({int hour, int minute})? timeForDay(
    int dayIndex,
    NotificationConfig config,
  ) {
    final times = config.scheduleTimes;
    if (times.isEmpty) return null;
    final token = config.rotationMode == NotificationRotationMode.alternate
        ? times[dayIndex % times.length]
        : times[0];
    final parts = token.split(':');
    if (parts.length != 2) return null;
    return (hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @visibleForTesting
  static Future<String> localTimezoneName() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return info.identifier;
    } catch (_) {
      return 'UTC';
    }
  }
}
