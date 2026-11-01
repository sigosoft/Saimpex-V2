import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../views/update_required_screen.dart';
import '../network/api_constants.dart';
import '../network/api_message.dart';
import '../network/dio_client.dart';

/// Checks the app version against Admin → App versions (`customer/settings`:
/// `play_store_version` / `app_store_version`, `…_update` = force, `…_link`).
/// A newer version shows the Update screen; a forced one can't be skipped.
class AppUpdate {
  AppUpdate._();

  static bool _shown = false;

  static Future<void> check() async {
    if (_shown || kIsWeb || !Get.isRegistered<DioClient>()) return;
    try {
      final response = await Get.find<DioClient>().dio.get(
        ApiConstants.appSettings,
      );
      final data = asJsonMap(asJsonMap(response.data)?['data']);
      final list = data?['settings'];
      final settings = list is List && list.isNotEmpty
          ? asJsonMap(list.first)
          : null;
      if (settings == null) return;
      final prefix = Platform.isIOS ? 'app_store' : 'play_store';
      final latest = '${settings['${prefix}_version'] ?? ''}'.trim();
      final force = '${settings['${prefix}_update'] ?? 0}' == '1';
      final link = '${settings['${prefix}_link'] ?? ''}'.trim();
      final current = (await PackageInfo.fromPlatform()).version;
      if (latest.isEmpty || !isNewer(latest, current)) return;
      _shown = true;
      final screen = UpdateRequiredScreen(force: force, storeLink: link);
      if (force) {
        Get.offAll(() => screen);
      } else {
        Get.to(() => screen);
      }
    } catch (error) {
      debugPrint('Update check skipped: $error');
    }
  }

  /// True when [latest] (e.g. "2.1") is higher than [current] (e.g. "2.0.3").
  static bool isNewer(String latest, String current) {
    List<int> parts(String v) =>
        v.split(RegExp(r'[.+-]')).map((p) => int.tryParse(p) ?? 0).toList();
    final a = parts(latest);
    final b = parts(current);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
