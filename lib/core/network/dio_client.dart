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
          handler.next(options);
        },
        onResponse: (response, handler) {
          logDioResult(
            options: response.requestOptions,
            statusCode: response.statusCode,
            data: response.data,
          );
          handler.next(response);
        },
        onError: (error, handler) {
          logDioResult(
            options: error.requestOptions,
            statusCode: error.response?.statusCode,
            data: error.response?.data,
            fallbackMessage: error.message,
          );
          handler.next(error);
        },
      ),
    );
  }

  final SessionStore session;
  late final Dio dio;
}

void logDioResult({
  required RequestOptions options,
  required int? statusCode,
  required dynamic data,
  String? fallbackMessage,
}) {
  if (!kDebugMode) return;

  final body = asJsonMap(data);
  final message = body?['message'] ?? fallbackMessage ?? '-';
  final authorization = options.headers['Authorization']?.toString();
  final bearer = (authorization != null && authorization.isNotEmpty)
      ? authorization
      : '-';
  debugPrint(
    '[DIO] ${options.method} ${options.uri}\n'
    'bearer: $bearer\n'
    'status: ${statusCode ?? '-'}\n'
    'message: $message',
  );
}
