import 'dart:io';

import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_config.dart';

class RateAppService {
  final InAppReview _review = InAppReview.instance;

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
