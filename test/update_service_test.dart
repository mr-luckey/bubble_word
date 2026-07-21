import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_word/core/utils/update_service.dart';

void main() {
  final service = UpdateService();

  group('UpdateService version compare', () {
    test('store newer when patch is higher', () {
      expect(service.isStoreVersionNewer('0.1.1', '0.1.0'), isTrue);
    });

    test('store newer when minor is higher', () {
      expect(service.isStoreVersionNewer('0.2.0', '0.1.9'), isTrue);
    });

    test('not newer when versions match', () {
      expect(service.isStoreVersionNewer('1.0.0', '1.0.0'), isFalse);
    });

    test('not newer when installed version is ahead', () {
      expect(service.isStoreVersionNewer('1.0.0', '1.0.1'), isFalse);
    });
  });
}
