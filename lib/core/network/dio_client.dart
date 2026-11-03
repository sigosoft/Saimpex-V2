import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' show Trans;

import '../storage/session_store.dart';
import 'api_constants.dart';
import 'api_message.dart';

class DioClient {
  DioClient(this.session) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final path = options.path;
          final isOpenAuth =
              path == ApiConstants.sendOtp || path == ApiConstants.verifyOtp;
          // Logged-in token first; otherwise the guest cart token (V2_DECISIONS §19).
          final token = (session.token != null && session.token!.isNotEmpty)
              ? session.token
              : session.guestToken;
          if (!isOpenAuth && token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          logDioRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          logDioResponse(response);
          handler.next(response);
        },
        onError: (error, handler) async {
          logDioError(error);
          // A guest's first cart request: start a guest session and retry once.
          if (_needsGuestSession(error)) {
            final retried = await _retryWithGuestSession(error.requestOptions);
            if (retried != null) return handler.resolve(retried);
          }
          // A guest token the server no longer knows (e.g. merged at login on another phone): drop it.
          if (error.response?.statusCode == 401 &&
              !_serverSaysLoginRequired(error) &&
              session.guestToken != null &&
              error.requestOptions.headers['Authorization']?.toString() ==
                  'Bearer ${session.guestToken}') {
            await session.saveGuestToken(null);
          }
          _checkSessionExpired(error);
          // 503: the server is under maintenance; show "We'll be right back".
          // A request that uses 503 for its own "not available" answer (the
          // assistant before Admin sets it up) shows that message instead.
          if (error.response?.statusCode == 503 &&
              error.requestOptions.extra[DioClient.ownServiceUnavailable] !=
                  true) {
            onServerDown?.call();
          }
          if (_isGuestLoginRequired(error)) {
            // Guest tried something that needs an account: friendly message, and
            // the login sheet (V2_DECISIONS §17), not "Unauthenticated."
            // Only for actions: screens load account data (wallet, notifications)
            // in the background with GET, and those must not pop the sheet.
            if (error.requestOptions.method.toUpperCase() != 'GET') {
              onLoginRequired?.call();
            } else {
              // Background load for a guest: fail quietly (no toast).
              error.requestOptions.extra['guest_silent'] = true;
            }
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: error.requestOptions,
                  statusCode: 401,
                  data: {'status': false, 'message': 'ease_login_required'.tr},
                ),
              ),
            );
            return;
          }
          handler.next(error);
        },
      ),
    );
  }

  final SessionStore session;
  late final Dio dio;

  /// Called when the server answers 401 to a request sent with the current
  /// session (token expired or revoked). Set in main.dart: it clears the
  /// session and returns to Login. Not called again once the session is gone.
  void Function()? onSessionExpired;

  /// Request `extra` key: true when the caller shows a 503's own message
  /// (no "We'll be right back" screen).
  static const ownServiceUnavailable = 'own_service_unavailable';

  /// Called when the server answers 503 (maintenance). Set in main.dart.
  void Function()? onServerDown;

  /// Called when a guest (no session) gets a 401: show the login sheet.
  void Function()? onLoginRequired;

  bool _isGuestLoginRequired(DioException error) {
    if (error.response?.statusCode != 401) return false;
    if (_serverSaysLoginRequired(error)) return true;
    final token = session.token;
    return token == null || token.isEmpty;
  }

  bool _serverSaysLoginRequired(DioException error) {
    final data = error.response?.data;
    return data is Map && data['login_required'] == true;
  }

  static final _cartPath = RegExp(
    r'^customer/(cart|catalog/cart)/|^customer/(catalog/)?checkoutSummary',
  );

  bool _needsGuestSession(DioException error) {
    if (error.response?.statusCode != 401) return false;
    final hasLogin = session.token != null && session.token!.isNotEmpty;
    return !hasLogin &&
        session.guestToken == null &&
        _cartPath.hasMatch(error.requestOptions.path);
  }

  Future<Response<dynamic>?> _retryWithGuestSession(
    RequestOptions failed,
  ) async {
    try {
      final plain = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          headers: const {'Accept': 'application/json'},
        ),
      );
      final res = await plain.post(ApiConstants.guestSession);
      final data = res.data is Map ? res.data['data'] : null;
      final guest = data is Map ? data['token']?.toString() : null;
      if (guest == null || guest.isEmpty) return null;
      await session.saveGuestToken(guest);
      failed.headers['Authorization'] = 'Bearer $guest';
      return await dio.fetch(failed);
    } catch (_) {
      return null;
    }
  }

  void _checkSessionExpired(DioException error) {
    if (error.response?.statusCode != 401) return;
    // Logging out with a dead token is fine; the account screen handles it.
    if (error.requestOptions.path == ApiConstants.logout) return;
    final token = session.token;
    if (token == null || token.isEmpty) return;
    final sent = error.requestOptions.headers['Authorization']?.toString();
    if (sent != 'Bearer $token') return;
    onSessionExpired?.call();
  }
}

/// "Bearer …a1b2c3": enough to tell tokens apart in debug logs without
/// leaking them into shared logs or screenshots.
String _maskAuthorization(String? authorization) {
  if (authorization == null || authorization.isEmpty) return '-';
  final token = authorization.replaceFirst('Bearer ', '');
  final tail = token.length > 6 ? token.substring(token.length - 6) : '';
  return 'Bearer …$tail';
}

String _formatData(dynamic data) {
  if (data == null) return 'null';
  if (data is FormData) {
    final fields = data.fields.map((e) => '${e.key}: ${e.value}').toList();
    final files = data.files
        .map((e) => '${e.key}: ${e.value.filename}')
        .toList();
    return 'FormData(fields: $fields, files: $files)';
  }
  // Binary downloads (images) would otherwise print every byte
  if (data is List<int>) {
    return '<binary ${data.length} bytes>';
  }
  if (data is Map || data is List) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
  if (data is String) {
    try {
      final decoded = jsonDecode(data);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return data;
    }
  }
  return data.toString();
}

void _printConsole(String message) {
  if (!kDebugMode) return;
  const int maxLen = 8000;
  if (message.length > maxLen) {
    debugPrint(
      '${message.substring(0, maxLen)}\n... [TRUNCATED - Payload too large (${message.length} chars)]',
    );
  } else {
    debugPrint(message);
  }
}

void logDioRequest(RequestOptions options) {
  final token = options.headers['Authorization']?.toString();
  final headers = {
    ...options.headers,
    if (token != null) 'Authorization': _maskAuthorization(token),
  };
  final query = options.queryParameters.isNotEmpty
      ? '\n[Query Parameters]: ${options.queryParameters}'
      : '';
  _printConsole(
    '==================== [API REQUEST] ====================\n'
    '[Method & URL]: ${options.method} ${options.uri}\n'
    '[Token]: ${token != null && token.isNotEmpty ? _maskAuthorization(token) : 'No Token'}\n'
    '[Headers]: $headers'
    '$query\n'
    '[Request Body]:\n${_formatData(options.data)}\n'
    '=======================================================',
  );
}

void logDioResponse(Response response) {
  _printConsole(
    '==================== [API RESPONSE] ====================\n'
    '[Method & URL]: ${response.requestOptions.method} ${response.requestOptions.uri}\n'
    '[Status Code]: ${response.statusCode} ${response.statusMessage ?? ''}\n'
    '[Headers]: ${response.headers.map}\n'
    '[Response Body]:\n${_formatData(response.data)}\n'
    '========================================================',
  );
}

void logDioError(DioException error) {
  final statusCode = error.response?.statusCode;
  final statusMessage = error.response?.statusMessage;
  _printConsole(
    '==================== [API ERROR] ====================\n'
    '[Method & URL]: ${error.requestOptions.method} ${error.requestOptions.uri}\n'
    '[Status Code]: ${statusCode ?? '-'} ${statusMessage ?? ''}\n'
    '[Error Message]: ${error.message}\n'
    '[Error Type]: ${error.type}\n'
    '[Response Body]:\n${_formatData(error.response?.data)}\n'
    '======================================================',
  );
}

void logDioResult({
  required RequestOptions options,
  required int? statusCode,
  required dynamic data,
  String? fallbackMessage,
}) {
  final body = asJsonMap(data);
  final message = body?['message'] ?? fallbackMessage ?? '-';
  final bearer = _maskAuthorization(
    options.headers['Authorization']?.toString(),
  );
  _printConsole(
    '[DIO] ${options.method} ${options.uri}\n'
    'bearer: $bearer\n'
    'status: ${statusCode ?? '-'}\n'
    'message: $message',
  );
}
