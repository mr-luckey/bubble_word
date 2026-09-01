import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/analytics_config.dart';

/// Central analytics facade. Never throw to callers. Never send PII.
class AnalyticsService {
  AnalyticsService({
    AnalyticsConfig config = const AnalyticsConfig(),
    FirebaseAnalytics? analytics,
  })  : _config = config,
        _injected = analytics;

  final AnalyticsConfig _config;
  final FirebaseAnalytics? _injected;
  FirebaseAnalytics? _analytics;
  bool _ready = false;

  Future<void> init() async {
    if (!_config.enabled) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _analytics = _injected ?? FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _ready = true;
    } catch (error, stack) {
      _ready = false;
      debugPrint('Analytics init failed: $error\n$stack');
    }
  }

  void logLevelStarted({
    int? levelNumber,
    String? difficulty,
    int? attemptNumber,
    String? source,
  }) {
    unawaitedLog(AnalyticsConfig.eventLevelStarted, {
      'level_number': ?levelNumber,
      'difficulty': ?difficulty,
      'attempt_number': ?attemptNumber,
      'source': ?source,
    });
  }

  void logLevelCompleted({
    int? levelNumber,
    String? difficulty,
    int? moves,
    int? timeSeconds,
    int? attemptNumber,
    String? source,
  }) {
    unawaitedLog(AnalyticsConfig.eventLevelCompleted, {
      'level_number': ?levelNumber,
      'difficulty': ?difficulty,
      'moves': ?moves,
      'time_seconds': ?timeSeconds,
      'attempt_number': ?attemptNumber,
      'source': ?source,
    });
  }

  void logLevelFailed({
    int? levelNumber,
    String? difficulty,
    int? moves,
    int? timeSeconds,
    int? attemptNumber,
    String? source,
  }) {
    unawaitedLog(AnalyticsConfig.eventLevelFailed, {
      'level_number': ?levelNumber,
      'difficulty': ?difficulty,
      'moves': ?moves,
      'time_seconds': ?timeSeconds,
      'attempt_number': ?attemptNumber,
      'source': ?source,
    });
  }

  void logLevelAbandoned({
    int? levelNumber,
    String? difficulty,
    String? source,
  }) {
    unawaitedLog(AnalyticsConfig.eventLevelAbandoned, {
      'level_number': ?levelNumber,
      'difficulty': ?difficulty,
      'source': ?source,
    });
  }

  void logHintUsed({int? levelNumber, String? source}) {
    unawaitedLog(AnalyticsConfig.eventHintUsed, {
      'level_number': ?levelNumber,
      'source': ?source,
    });
  }

  void logRewardClaimed({String? rewardType, String? source}) {
    unawaitedLog(AnalyticsConfig.eventRewardClaimed, {
      'reward_type': ?rewardType,
      'source': ?source,
    });
  }

  void logDailyRewardClaimed({int? day, String? source}) {
    unawaitedLog(AnalyticsConfig.eventDailyRewardClaimed, {
      'day': ?day,
      'source': ?source,
    });
  }

  void logNotificationOpened({
    String? notificationId,
    String? source,
  }) {
    unawaitedLog(AnalyticsConfig.eventNotificationOpened, {
      'notification_id': ?notificationId,
      'source': ?source,
    });
  }

  void logNotificationScheduled({int? count, String? source}) {
    unawaitedLog(AnalyticsConfig.eventNotificationScheduled, {
      'count': ?count,
      'source': ?source,
    });
  }

  void logRewardedAdCompleted({String? placement, String? source}) {
    unawaitedLog(AnalyticsConfig.eventRewardedAdCompleted, {
      'placement': ?placement,
      'source': ?source,
    });
  }

  /// Fire-and-forget. Gameplay must never await this.
  void unawaitedLog(String name, [Map<String, Object>? parameters]) {
    unawaited(logEvent(name, parameters));
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    if (!_config.enabled || !_ready) return;
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(
        name: name,
        parameters: parameters == null ? null : sanitize(parameters),
      );
    } catch (error, stack) {
      debugPrint('Analytics event "$name" failed: $error\n$stack');
    }
  }

  @visibleForTesting
  static Map<String, Object> sanitize(Map<String, Object> parameters) {
    const blocked = {
      'password',
      'email',
      'phone',
      'token',
      'auth',
      'payment',
      'card',
    };
    final out = <String, Object>{};
    for (final entry in parameters.entries) {
      final key = entry.key.toLowerCase();
      if (blocked.any(key.contains)) continue;
      final value = entry.value;
      if (value is String || value is num || value is bool) {
        out[entry.key] = value;
      } else {
        out[entry.key] = value.toString();
      }
    }
    return out;
  }
}
