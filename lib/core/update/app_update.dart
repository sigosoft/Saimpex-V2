import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../views/server_down_screen.dart';
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
  static bool _downShown = false;

  static Future<Map<String, dynamic>?> _settings() async {
    final response = await Get.find<DioClient>().dio.get(
      ApiConstants.appSettings,
    );
    final data = asJsonMap(asJsonMap(response.data)?['data']);
    final list = data?['settings'];
    return list is List && list.isNotEmpty ? asJsonMap(list.first) : null;
  }

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// True while Admin has maintenance on for this platform, or the server
  /// can't be reached with a 5xx answer.
  static Future<bool> isServerDown() async {
    try {
      final settings = await _settings();
      return '${settings?['maintenance_$_platform'] ?? 0}' == '1';
    } on DioException catch (error) {
      return (error.response?.statusCode ?? 0) >= 500;
    } catch (_) {
      return false;
    }
  }

  /// Shows "We'll be right back" once at a time (Admin maintenance or a 503).
  static void showServerDown([String reason = '']) {
    if (_downShown) return;
    _downShown = true;
    Get.to(() => ServerDownScreen(reason: reason))?.whenComplete(() {
      _downShown = false;
    });
  }

  /// Opens the Update screen when Admin lists a newer version. [manual] is
  /// Account → "Check for update": it checks again even after the screen was
  /// shown once. True when the Update (or Server Down) screen opened.
  static Future<bool> check({bool manual = false}) async {
    if ((_shown && !manual) || kIsWeb || !Get.isRegistered<DioClient>()) {
      return false;
    }
    try {
      final settings = await _settings();
      if (settings == null) return false;
      if ('${settings['maintenance_$_platform'] ?? 0}' == '1') {
        showServerDown('${settings['maintenance_reason_$_platform'] ?? ''}');
        return true;
      }
      final prefix = Platform.isIOS ? 'app_store' : 'play_store';
      final latest = '${settings['${prefix}_version'] ?? ''}'.trim();
      final force = '${settings['${prefix}_update'] ?? 0}' == '1';
      final link = '${settings['${prefix}_link'] ?? ''}'.trim();
      final current = (await PackageInfo.fromPlatform()).version;
      if (latest.isEmpty || !isNewer(latest, current)) return false;
      _shown = true;
      final screen = UpdateRequiredScreen(force: force, storeLink: link);
      if (force) {
        Get.offAll(() => screen);
      } else {
        Get.to(() => screen);
      }
      return true;
    } catch (error) {
      debugPrint('Update check skipped: $error');
      return false;
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
