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
    final userMap =
        asJsonMap(data['user']) ?? asJsonMap(data['profile']) ?? data;
    return AuthUser.fromJson(userMap);
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

    final user = AuthUser.fromJson(userJson).copyWith(countryCode: countryCode);

    return (user: user, message: envelope.message);
  }

  Future<String> updateLanguage(String languageCode) async {
    final code = languageCode.trim().toLowerCase();
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.updateLanguage,
        data: {'language': code, 'language_code': code},
      ),
      code,
    );
    return envelope.message;
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

  /// The address book: `{id, label, address, latitude, longitude}` rows.
  Future<List<Map<String, dynamic>>> savedAddresses(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.addresses),
      language,
    );
    return _rows(asJsonMap(envelope.data)?['addresses']);
  }

  /// Creates a saved address, or edits [addressId]. [label] is Home, Office
  /// or Other; saving a second Home/Office replaces the first.
  Future<String> saveAddress({
    int? addressId,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.saveAddress,
        data: {
          'address_id': ?addressId,
          'label': label,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  Future<String> deleteAddress({
    required int addressId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.deleteAddress,
        data: {'address_id': addressId},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  /// Hearted cards: the card fields saved with each, plus `id`.
  Future<List<Map<String, dynamic>>> favourites(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.favourites),
      language,
    );
    return _rows(asJsonMap(envelope.data)?['favourites']);
  }

  /// Sets whether [itemId] is a favourite, saving [card] for My Favourites.
  Future<void> setFavourite({
    required String itemId,
    required bool favourite,
    Map<String, dynamic> card = const {},
    required String language,
  }) async {
    await _send(
      () => _client.dio.post(
        ApiConstants.toggleFavourite,
        data: {'item_id': itemId, 'favourite': favourite, 'card': card},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
  }

  static List<Map<String, dynamic>> _rows(dynamic value) => [
    if (value is List)
      for (final row in value)
        if (asJsonMap(row) != null) asJsonMap(row)!,
  ];

  Future<({String address, double? latitude, double? longitude})> fetchLocation(
    String language,
  ) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.fetchLocation),
      language,
    );
    final data = asJsonMap(envelope.data);
    final location =
        asJsonMap(data?['location']) ?? data ?? <String, dynamic>{};
    return (
      address: location['address']?.toString().trim() ?? '',
      latitude: _asDouble(location['latitude'] ?? location['lat']),
      longitude: _asDouble(
        location['longitude'] ?? location['long'] ?? location['lng'],
      ),
    );
  }

  Future<({num userPoints, num redeemableAmount})> fetchUserPoints(
    String language,
  ) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.userPoints),
      language,
    );
    final data = asJsonMap(envelope.data);
    final userPoints = _asNum(data?['user_points']) ?? 0;
    final redeemableAmount =
        _asNum(data?['redeemable amount'] ?? data?['redeemable_amount']) ?? 0;
    return (userPoints: userPoints, redeemableAmount: redeemableAmount);
  }

  /// Whether push notifications are on (notification/preference).
  Future<bool> fetchNotificationPreference(String language) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.notificationPreference,
        queryParameters: {'notification_enabled': 1},
      ),
      language,
    );
    final data = asJsonMap(envelope.data);
    final value = data?['notification_enabled'];
    return value == true || value == 1 || value == '1';
  }

  /// Turns push notifications on or off.
  Future<String> updateNotificationPreference({
    required bool enabled,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.notificationPreference,
        data: {'notification_enabled': enabled ? '1' : '0'},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  /// Recent notifications, newest first (notifications).
  Future<List<Map<String, dynamic>>> fetchNotifications({
    required String language,
    int limit = 20,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.notifications,
        queryParameters: {'limit': limit, 'notification_enabled': 1},
      ),
      language,
    );
    final data = asJsonMap(envelope.data);
    final raw = data?['notifications'];
    if (raw is! List) return const [];
    return raw
        .map((item) => asJsonMap(item))
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => {
            'title': _localizedText(item, 'title', language),
            'content': _localizedText(item, 'content', language),
            'date': item['date']?.toString() ?? '',
            'time': item['time']?.toString() ?? '',
          },
        )
        .toList();
  }

  /// Deletes the customer account on the server (delete).
  Future<String> deleteAccount(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.customerDelete),
      language,
    );
    return envelope.message;
  }

  String _localizedText(
    Map<String, dynamic> item,
    String key,
    String language,
  ) {
    for (final code in [language, 'en', 'fr', 'ar']) {
      final value = item['${key}_$code']?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return '';
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
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
