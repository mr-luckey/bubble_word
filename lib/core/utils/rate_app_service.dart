import 'dart:io';
import 'dart:math';

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_config.dart';

class RateAppService {
  RateAppService(this._prefs);

  static const _ratedKey = 'rate_app_completed';
  static const _dismissedKey = 'rate_app_dismissed';
  static const _lastPromptMsKey = 'rate_app_last_prompt_ms';

  static const _minLevelBeforePrompt = 3;
  static const _promptCooldown = Duration(days: 7);
  static const _promptChancePercent = 22;

  final SharedPreferences _prefs;
  final InAppReview _review = InAppReview.instance;
  final Random _random = Random();

  bool get hasCompletedOrDismissed =>
      _prefs.getBool(_ratedKey) == true || _prefs.getBool(_dismissedKey) == true;

  bool shouldRandomlyPrompt({required int levelId}) {
    if (hasCompletedOrDismissed) return false;
    if (levelId < _minLevelBeforePrompt) return false;

    final lastMs = _prefs.getInt(_lastPromptMsKey) ?? 0;
    if (lastMs > 0) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
      if (elapsed < _promptCooldown.inMilliseconds) return false;
    }

    return _random.nextInt(100) < _promptChancePercent;
  }

  Future<void> markPromptShown() async {
    await _prefs.setInt(
      _lastPromptMsKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> markRated() async {
    await _prefs.setBool(_ratedKey, true);
  }

  Future<void> markDismissed() async {
    await _prefs.setBool(_dismissedKey, true);
  }

  Future<bool> requestReview() async {
    if (await _review.isAvailable()) {
      await _review.requestReview();
      return true;
    }
    return openStoreListing();
  }

  Future<bool> openStoreListing() async {
    try {
      await _review.openStoreListing(appStoreId: AppConfig.iosAppStoreId);
      return true;
    } catch (_) {
      final url = Platform.isIOS
          ? AppConfig.iosStoreUrl
          : AppConfig.androidStoreUrl;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    }
  }
}
