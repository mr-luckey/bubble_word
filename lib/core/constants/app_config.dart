/// Store & release config.
///
/// TODO: Replace example IDs with your real values before publishing:
/// - [androidPackage] → e.g. `com.yourcompany.bubbleword`
/// - [iosAppStoreId] → numeric ID from App Store Connect
abstract final class AppConfig {
  // --- Example placeholders (replace before release) ---

  /// Google Play application ID (example).
  static const String androidPackage = 'com.bubbleword.app';

  /// App Store Connect numeric app ID (example).
  static const String iosAppStoreId = '1234567890';

  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackage';

  static const String iosStoreUrl =
      'https://apps.apple.com/app/id$iosAppStoreId';
}
