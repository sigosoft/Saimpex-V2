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
          handler.next(error);
        },
      ),
    );
  }

  final SessionStore session;
  late final Dio dio;
}

String _formatData(dynamic data) {
  if (data == null) return 'null';
  if (data is FormData) {
    final fields = data.fields.map((e) => '${e.key}: ${e.value}').toList();
    final files =
        data.files.map((e) => '${e.key}: ${e.value.filename}').toList();
    return 'FormData(fields: $fields, files: $files)';
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
  final query = options.queryParameters.isNotEmpty
      ? '\n[Query Parameters]: ${options.queryParameters}'
      : '';
  _printConsole(
    '==================== [API REQUEST] ====================\n'
    '[Method & URL]: ${options.method} ${options.uri}\n'
    '[Token]: ${token != null && token.isNotEmpty ? token : 'No Token'}\n'
    '[Headers]: ${options.headers}'
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
  final authorization = options.headers['Authorization']?.toString();
  final bearer = (authorization != null && authorization.isNotEmpty)
      ? authorization
      : '-';
  _printConsole(
    '[DIO] ${options.method} ${options.uri}\n'
    'bearer: $bearer\n'
    'status: ${statusCode ?? '-'}\n'
    'message: $message',
  );
}
