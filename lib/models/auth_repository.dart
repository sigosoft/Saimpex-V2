import 'package:dio/dio.dart';
import 'package:get/get.dart' show Trans;

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';
import 'auth_user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final DioClient _client;

  Future<String> sendOtp({
    required String countryCode,
    required String mobile,
    required String language,
  }) async {
    final envelope = await _post(ApiConstants.sendOtp, {
      'country_code': countryCode,
      'language': language,
      'mobile': mobile,
    }, language);
    return envelope.message;
  }

  Future<({String token, AuthUser user, String message})> verifyOtp({
    required String countryCode,
    required String mobile,
    required String otp,
    required String language,
    String? fcmToken,
  }) async {
    final envelope = await _post(ApiConstants.verifyOtp, {
      'country_code': countryCode,
      'mobile': mobile,
      'otp': otp,
      if (fcmToken != null && fcmToken.trim().isNotEmpty)
        'fcm_token': fcmToken.trim(),
    }, language);

    final data = asJsonMap(envelope.data);
    if (data == null) {
      throw ApiException('core_unexpected_response'.tr);
    }

    final token = _readToken(data);
    if (token == null || token.isEmpty) {
      throw ApiException('core_login_no_token'.tr);
    }

    final userJson = asJsonMap(data['user']) ?? <String, dynamic>{};
    final user = AuthUser.fromJson(
      userJson,
      isNewUser: data['is_new_user'] == true,
    );

    return (token: token, user: user, message: envelope.message);
  }

  /// False when the stored token is rejected. A connection problem keeps the
  /// session so the user is not logged out while offline.
  Future<bool> customerCheck() async {
    try {
      final response = await _client.dio.get(ApiConstants.customerCheck);
      final body = asJsonMap(response.data);
      return body?['status'] == true;
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      if (code == 401 || code == 403) return false;
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<String> logout(String language) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.logout,
        data: {'language': language},
        options: Options(contentType: Headers.jsonContentType),
      );
      final body = asJsonMap(response.data);
      final message = resolveApiMessage(
        body?['message'],
        language,
        fallback: 'core_logged_out'.tr,
      );
      if (response.statusCode == 200) return message;

      return ApiEnvelope.parse(
        response.data,
        language,
        statusCode: response.statusCode,
      ).message;
    } on FormatException catch (error) {
      throw ApiException(
        error.message.isEmpty ? 'core_request_failed'.tr : error.message,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }

  Future<ApiEnvelope> _post(
    String path,
    Map<String, dynamic> body,
    String language,
  ) async {
    try {
      final response = await _client.dio.post(
        path,
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      try {
        return ApiEnvelope.parse(
          response.data,
          language,
          statusCode: response.statusCode,
        );
      } on FormatException catch (error) {
        throw ApiException(
          error.message.isEmpty ? 'core_request_failed'.tr : error.message,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }

  String? _readToken(Map<String, dynamic> data) {
    final direct = data['token'];
    if (direct is String && direct.isNotEmpty) return direct;

    final details = data['details'];
    if (details is Map && details['token'] is String) {
      final token = details['token'] as String;
      if (token.isNotEmpty) return token;
    }

    final user = data['user'];
    if (user is Map && user['token'] is String) {
      final token = user['token'] as String;
      if (token.isNotEmpty) return token;
    }

    return null;
  }
}
