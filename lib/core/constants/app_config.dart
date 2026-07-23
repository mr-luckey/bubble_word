/// Store & release config.
abstract final class AppConfig {
  /// Google Play application ID (must match android applicationId).
  static const String androidPackage = 'com.appwaretech.bubbleword';

  /// App Store Connect numeric app ID (replace when iOS ships).
  static const String iosAppStoreId = '1234567890';

  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackage';

  static const String iosStoreUrl =
      'https://apps.apple.com/app/id$iosAppStoreId';
}
