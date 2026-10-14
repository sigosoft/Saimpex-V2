import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

class FoodRepository {
  FoodRepository(this._client);

  final DioClient _client;

  Future<List<Map<String, dynamic>>> fetchVendorCategories({
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.foodVendorCategories,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'featured_only': '',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return _categories(data['categories'], language);
  }

  List<Map<String, dynamic>> _categories(dynamic raw, String language) {
    if (raw is! List) return const [];
    final categories = <Map<String, dynamic>>[];
    for (final item in raw) {
      final category = asJsonMap(item);
      if (category == null) continue;
      final id = _asInt(category['category_id']);
      final name = _localized(category, 'name', language);
      categories.add({
        'id': id,
        'label': name.isEmpty ? (id == 0 ? 'All' : 'Category') : name,
        'isAll': id == 0,
        'image': ApiConstants.mediaUrl(category['image']?.toString()),
      });
    }
    return categories;
  }

  String _localized(Map<String, dynamic> item, String key, String language) {
    final localized = item['${key}_$language']?.toString().trim() ?? '';
    if (localized.isNotEmpty) return localized;
    for (final code in ['en', 'fr', 'ar']) {
      final value = item['${key}_$code']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return item[key]?.toString().trim() ?? '';
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
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
