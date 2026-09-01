import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_word/core/config/ads_config.dart';
import 'package:bubble_word/core/services/ads_service.dart';
import 'package:bubble_word/core/services/network_guard.dart';

void main() {
  group('NetworkGuard.isUsable', () {
    test('none and empty are offline', () {
      expect(NetworkGuard.isUsable(const []), isFalse);
      expect(NetworkGuard.isUsable(const [ConnectivityResult.none]), isFalse);
    });

    test('wifi or mobile is treated as online', () {
      expect(NetworkGuard.isUsable(const [ConnectivityResult.wifi]), isTrue);
      expect(NetworkGuard.isUsable(const [ConnectivityResult.mobile]), isTrue);
      expect(
        NetworkGuard.isUsable(const [
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ]),
        isTrue,
      );
    });
  });

  group('AdsService interstitial interval', () {
    test('allows first interstitial and blocks inside the window', () {
      final ads = AdsService(
        config: const AdsConfig(
          testMode: false,
          isEnabled: false,
          minimumInterstitialInterval: Duration(minutes: 2),
        ),
      );
      expect(ads.frequencyAllowsInterstitial(), isTrue);
      ads.lastFullScreenAt = DateTime(2026, 1, 1, 12, 0);
      expect(
        ads.frequencyAllowsInterstitial(DateTime(2026, 1, 1, 12, 1)),
        isFalse,
      );
      expect(
        ads.frequencyAllowsInterstitial(DateTime(2026, 1, 1, 12, 2)),
        isTrue,
      );
    });
  });
}
