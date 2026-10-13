import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

class CartRepository {
  CartRepository(this._client);

  final DioClient _client;

  Future<({String vendorName, List<Map<String, dynamic>> items})> fetchList(
    String language,
  ) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.cartList),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final items = [
      ..._lines(data['items']),
      ..._lines(data['basket_items']),
    ];
    return (vendorName: _vendorName(data, language), items: items);
  }

  String _vendorName(Map<String, dynamic> data, String language) {
    final localized = data['vendor_name_$language']?.toString().trim() ?? '';
    if (localized.isNotEmpty && localized != 'null') return localized;
    for (final code in ['en', 'fr', 'ar']) {
      final value = data['vendor_name_$code']?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    final name = data['vendor_name']?.toString().trim() ?? '';
    return name == 'null' ? '' : name;
  }

  List<Map<String, dynamic>> _lines(dynamic raw) {
    if (raw is! List) return const [];
    final lines = <Map<String, dynamic>>[];
    for (final item in raw) {
      final map = asJsonMap(item);
      if (map == null) continue;
      final name = _itemName(map);
      final quantity = _asInt(map['quantity'], fallback: 1);
      final unit = _asDouble(map['unit_price'] ?? map['price'] ?? map['selling_price']);
      final total = map['total_price'] == null
          ? unit * quantity
          : _asDouble(map['total_price']);
      lines.add({
        'name': name.isEmpty ? 'Item' : name,
        'quantity': quantity < 1 ? 1 : quantity,
        'unitPrice': unit,
        'lineTotal': total,
        'image': ApiConstants.mediaUrl(map['image']?.toString()) ?? '',
      });
    }
    return lines;
  }

  String _itemName(Map<String, dynamic> item) {
    for (final key in ['menu_name', 'name', 'product_name', 'title']) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return '';
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
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
