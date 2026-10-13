import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';
import 'auth_user.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final DioClient _client;

  Future<AuthUser> fetchProfile(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.profile),
      language,
    );
    final data = asJsonMap(envelope.data);
    if (data == null) {
      throw const ApiException('Unexpected server response');
    }
    return AuthUser.fromJson(data);
  }

  Future<({AuthUser user, String message})> updateProfile({
    required String name,
    required String countryCode,
    required String mobile,
    required String language,
    String? imagePath,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      'country_code': countryCode,
      'mobile': mobile,
    };

    if (imagePath != null && imagePath.trim().isNotEmpty) {
      final fileName = imagePath.split(RegExp(r'[/\\]')).last;
      fields['image'] = await MultipartFile.fromFile(
        imagePath,
        filename: fileName,
      );
    }

    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.updateProfile,
        data: FormData.fromMap(fields),
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ),
      language,
    );

    final data = asJsonMap(envelope.data);
    final userJson = asJsonMap(data?['user']);
    if (userJson == null) {
      throw const ApiException('Unexpected server response');
    }

    final user = AuthUser.fromJson(userJson).copyWith(
      countryCode: countryCode,
    );

    return (
      user: user,
      message: envelope.message,
    );
  }

  Future<String> updateLocation({
    required double latitude,
    required double longitude,
    required String address,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.updateLocation,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'address': address,
        },
      ),
      language,
    );
    return envelope.message;
  }

  Future<({String address, double? latitude, double? longitude})> fetchLocation(
    String language,
  ) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.fetchLocation),
      language,
    );
    final data = asJsonMap(envelope.data);
    final location = asJsonMap(data?['location']) ?? data ?? <String, dynamic>{};
    return (
      address: location['address']?.toString().trim() ?? '',
      latitude: _asDouble(location['latitude'] ?? location['lat']),
      longitude: _asDouble(
        location['longitude'] ?? location['long'] ?? location['lng'],
      ),
    );
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}'.trim());
  }

  Future<ApiEnvelope> _send(
    Future<Response<dynamic>> Function() call,
    String language,
  ) async {
    try {
      final response = await call();
      try {
        return ApiEnvelope.parse(
          response.data,
          language,
          statusCode: response.statusCode,
        );
      } on FormatException catch (error) {
        throw ApiException(
          error.message.isEmpty
              ? 'Request failed. Please try again.'
              : error.message,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }
}
