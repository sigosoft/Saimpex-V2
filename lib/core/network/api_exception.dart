import 'package:dio/dio.dart';
import 'package:get/get.dart' show Trans;

import 'api_message.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error, String language) {
    final statusCode = error.response?.statusCode;
    // A guest's background load that needs an account: no message to show.
    if (error.requestOptions.extra['guest_silent'] == true) {
      return ApiException('', statusCode: statusCode);
    }
    final body = asJsonMap(error.response?.data);
    if (body != null && body['message'] != null) {
      return ApiException(
        resolveApiMessage(
          body['message'],
          language,
          fallback: 'ease_err_generic'.tr,
        ),
        statusCode: statusCode,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('ease_err_slow'.tr, statusCode: statusCode);
      case DioExceptionType.connectionError:
        return ApiException('ease_err_network'.tr, statusCode: statusCode);
      default:
        return ApiException(
          statusCode != null && statusCode >= 500
              ? 'ease_err_server'.tr
              : 'ease_err_generic'.tr,
          statusCode: statusCode,
        );
    }
  }

  @override
  String toString() => message;
}
