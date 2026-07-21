import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_config.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.updateAvailable,
    this.storeVersion,
    this.checkSucceeded = true,
  });

  final String currentVersion;
  final String? storeVersion;
  final bool updateAvailable;
  final bool checkSucceeded;
}

class UpdateService {
  static final _playStorePatterns = [
    RegExp(r'\[\[\["([\d.]+?)"\]\]'),
    RegExp(r'"\d+",\[\[\["([\d.]+?)"\]\]'),
    RegExp(r'Current Version.*?>([\d.]+)<'),
    RegExp(r'"softwareVersion":"([\d.]+?)"'),
  ];

  Future<UpdateCheckResult> checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;

    final storeVersion = await _fetchStoreVersion();
    if (storeVersion == null) {
      return UpdateCheckResult(
        currentVersion: current,
        updateAvailable: false,
        checkSucceeded: false,
      );
    }

    return UpdateCheckResult(
      currentVersion: current,
      storeVersion: storeVersion,
      updateAvailable: isStoreVersionNewer(storeVersion, current),
      checkSucceeded: true,
    );
  }

  Future<String?> _fetchStoreVersion() async {
    try {
      if (Platform.isIOS) {
        return _fetchIosStoreVersion();
      }
      return _fetchAndroidStoreVersion();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fetchAndroidStoreVersion() async {
    final uri = Uri.https(
      'play.google.com',
      '/store/apps/details',
      {'id': AppConfig.androidPackage, 'hl': 'en_US'},
    );
    final response = await http
        .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) return null;

    for (final pattern in _playStorePatterns) {
      final match = pattern.firstMatch(response.body);
      if (match != null && match.groupCount >= 1) {
        final version = match.group(1);
        if (version != null && version.isNotEmpty) return version;
      }
    }
    return null;
  }

  Future<String?> _fetchIosStoreVersion() async {
    final uri = Uri.parse(
      'https://itunes.apple.com/lookup?id=${AppConfig.iosAppStoreId}',
    );
    final response =
        await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final version = (results.first as Map<String, dynamic>)['version'];
    if (version is String && version.isNotEmpty) return version;
    return null;
  }

  bool isStoreVersionNewer(String store, String current) {
    final s = _parseVersion(store);
    final c = _parseVersion(current);
    final length = s.length > c.length ? s.length : c.length;
    for (var i = 0; i < length; i++) {
      final sv = i < s.length ? s[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (sv > cv) return true;
      if (sv < cv) return false;
    }
    return false;
  }

  List<int> _parseVersion(String v) {
    final core = v.split('+').first.trim();
    return core
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }
}
