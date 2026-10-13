import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_user.dart';

class SessionStore {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final profileRevision = 0.obs;
  final isLoggedIn = false.obs;
  SharedPreferences? _prefs;
  String? _token;

  String? get token => _token;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString(_tokenKey);
    isLoggedIn.value = _token != null && _token!.isNotEmpty;
  }

  Future<void> saveSession({
    required String token,
    required AuthUser user,
  }) async {
    _token = token;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    isLoggedIn.value = true;
    profileRevision.value++;
  }

  AuthUser? readUser() {
    final raw = _prefs?.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      final map = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      if (map == null) return null;
      return AuthUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    _token = null;
    isLoggedIn.value = false;
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userKey);
    profileRevision.value++;
  }
}
