import 'package:dio/dio.dart';

import 'api_message.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error, String language) {
    final statusCode = error.response?.statusCode;
    final body = asJsonMap(error.response?.data);
    if (body != null && body['message'] != null) {
      return ApiException(
        resolveApiMessage(
          body['message'],
          language,
          fallback: 'Request failed. Please try again.',
        ),
        statusCode: statusCode,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(
          'Unable to connect. Please check your internet and try again.',
          statusCode: statusCode,
        );
      default:
        return ApiException(
          'Something went wrong. Please try again.',
          statusCode: statusCode,
        );
    }
  }

  @override
  String toString() => message;
}
