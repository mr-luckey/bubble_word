import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_word/core/config/ads_config.dart';

void main() {
  group('AdsConfig placements', () {
    const config = AdsConfig(
      testMode: false,
      bannerAdUnits: ['banner-0', '', 'banner-2', 'banner-3', 'banner-4'],
      interstitialAdUnits: ['int-0', 'int-1', '', 'int-3', 'int-4'],
      rewardedAdUnits: ['rew-0', '', 'rew-2', 'rew-3', 'rew-4'],
      bannerPlacements: {
        AdsPlacements.home: 0,
        AdsPlacements.game: 1,
        AdsPlacements.result: 2,
      },
      interstitialPlacements: {
        AdsPlacements.interstitialAfterLevel: 0,
        AdsPlacements.interstitialHintGate: 1,
      },
      rewardedPlacements: {
        AdsPlacements.rewardedHint: 0,
        'extra_life': 1,
      },
    );

    test('maps a placement to a single unit id', () {
      expect(config.bannerUnitId(AdsPlacements.home), 'banner-0');
      expect(config.interstitialUnitId(AdsPlacements.interstitialHintGate),
          'int-1');
      expect(config.rewardedUnitId(AdsPlacements.rewardedHint), 'rew-0');
    });

    test('empty unit disables that placement only', () {
      expect(config.bannerUnitId(AdsPlacements.game), isNull);
      expect(config.rewardedUnitId('extra_life'), isNull);
      expect(config.bannerUnitId(AdsPlacements.result), 'banner-2');
    });

    test('unknown placement is disabled', () {
      expect(config.bannerUnitId('does_not_exist'), isNull);
    });

    test('does not walk to the next id on an empty slot', () {
      expect(config.bannerUnitId(AdsPlacements.game), isNull);
      expect(config.bannerUnitId(AdsPlacements.home), isNot(equals('banner-2')));
    });
  });

  group('AdsConfig testMode', () {
    test('debug uses official Google test ids, not production lists', () {
      const config = AdsConfig(
        testMode: true,
        bannerAdUnits: ['ca-app-pub-production/banner'],
        bannerPlacements: {AdsPlacements.home: 0},
      );
      expect(
        config.bannerUnitId(AdsPlacements.home),
        defaultTargetPlatform == TargetPlatform.iOS
            ? GoogleTestAdUnits.iosBanner
            : GoogleTestAdUnits.androidBanner,
      );
      expect(
        config.bannerUnitId(AdsPlacements.home),
        isNot('ca-app-pub-production/banner'),
      );
    });
  });

  group('appAdsConfig', () {
    test('holds up to five unit ids per format', () {
      expect(appAdsConfig.bannerAdUnits, hasLength(5));
      expect(appAdsConfig.interstitialAdUnits, hasLength(5));
      expect(appAdsConfig.rewardedAdUnits, hasLength(5));
    });

    test('uses named placements instead of a fill waterfall', () {
      expect(appAdsConfig.bannerPlacements[AdsPlacements.home], 0);
      expect(appAdsConfig.bannerPlacements[AdsPlacements.game], 1);
      expect(appAdsConfig.bannerPlacements[AdsPlacements.result], 2);
      expect(
        appAdsConfig.interstitialPlacements[
            AdsPlacements.interstitialAfterLevel],
        0,
      );
      expect(
        appAdsConfig
            .interstitialPlacements[AdsPlacements.interstitialHintGate],
        1,
      );
    });
  });
}
