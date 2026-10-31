import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
          final token = session.token;
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
        onError: (error, handler) {
          logDioError(error);
          _checkSessionExpired(error);
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
