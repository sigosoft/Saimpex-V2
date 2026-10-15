import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

class CartRepository {
  CartRepository(this._client);

  final DioClient _client;

  Future<
    ({
      String vendorName,
      List<Map<String, dynamic>> items,
      int? vendorId,
      int? cartId,
    })
  >
  fetchList(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.cartList),
      language,
    );
    return _cartPayload(envelope.data, language);
  }

  Future<
    ({
      String vendorName,
      List<Map<String, dynamic>> items,
      int? vendorId,
      int? cartId,
    })
  >
  fetchListAll(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.cartListAll),
      language,
    );
    final data = envelope.data;
    if (data is List) {
      final items = <Map<String, dynamic>>[];
      String vendorName = '';
      int? vendorId;
      int? cartId;
      for (final entry in data) {
        final cart = _cartPayload(entry, language);
        if (vendorName.isEmpty) vendorName = cart.vendorName;
        vendorId ??= cart.vendorId;
        cartId ??= cart.cartId;
        items.addAll(cart.items);
      }
      return (
        vendorName: vendorName,
        items: items,
        vendorId: vendorId,
        cartId: cartId,
      );
    }
    return _cartPayload(data, language);
  }

  Future<String> replaceCart(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.cartReplace),
      language,
    );
    return envelope.message;
  }

  ({
    String vendorName,
    List<Map<String, dynamic>> items,
    int? vendorId,
    int? cartId,
  })
  _cartPayload(dynamic raw, String language) {
    final data = asJsonMap(raw) ?? <String, dynamic>{};
    final items = [
      ..._lines(data['items']),
      ..._lines(data['basket_items']),
    ];
    return (
      vendorName: _vendorName(data, language),
      items: items,
      vendorId: _positiveInt(data['vendor_id']),
      cartId: _positiveInt(data['cart_id']),
    );
  }

  Future<({String message, String? action, bool needsPrescription})>
  addPharmacyItem({
    required int pharmacyId,
    required int productId,
    required String language,
    int quantity = 1,
  }) async {
    final count = quantity < 1 ? 1 : quantity;
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.cartPharmacyAdd,
        data: {
          'pharmacy_id': '$pharmacyId',
          'product_id': '$productId',
          'quantity': '$count',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final action = data['action']?.toString().trim();
    return (
      message: envelope.message,
      action: action == null || action.isEmpty || action == 'null'
          ? null
          : action,
      needsPrescription:
          data['needs_prescription'] == true ||
          data['needs_prescription'] == 1,
    );
  }

  Future<String> attachPrescription({
    required int pharmacyId,
    required String filePath,
    required String language,
    String? contactNumber,
    String? note,
  }) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final fields = <String, dynamic>{
      'pharmacy_id': '$pharmacyId',
      'files': await MultipartFile.fromFile(filePath, filename: fileName),
    };
    final trimmedContact = contactNumber?.trim() ?? '';
    if (trimmedContact.isNotEmpty) fields['contact_number'] = trimmedContact;
    final trimmedNote = note?.trim() ?? '';
    if (trimmedNote.isNotEmpty) fields['note'] = trimmedNote;

    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.cartPharmacyAttachPrescription,
        data: FormData.fromMap(fields),
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ),
      language,
    );
    return envelope.message;
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
        'cartItemId': _asInt(map['cart_item_id']),
        'name': name.isEmpty ? 'Item' : name,
        'portion': _itemPortion(map),
        'quantity': quantity < 1 ? 1 : quantity,
        'unitPrice': unit,
        'lineTotal': total,
        'maxQuantity':
            _positiveInt(map['quantity_allowed']) ?? _positiveInt(map['stock']),
        'image': ApiConstants.mediaUrl(map['image']?.toString()) ?? '',
      });
    }
    return lines;
  }

  Future<void> updateItem({
    required int cartItemId,
    required int quantity,
    required String language,
  }) async {
    await _send(
      () => _client.dio.post(
        ApiConstants.cartUpdate,
        data: {
          'cart_item_id': '$cartItemId',
          'type': '',
          'quantity': '$quantity',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
  }

  Future<void> deleteItem({
    required int cartItemId,
    required String language,
  }) async {
    await _send(
      () => _client.dio.post(
        ApiConstants.cartItemDelete,
        data: {'cart_item_id': '$cartItemId'},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
  }

  String _itemPortion(Map<String, dynamic> item) {
    final direct = item['portion']?.toString().trim() ?? '';
    if (direct.isNotEmpty && direct != 'null') return direct;
    final parts = [item['form'], item['dosage'], item['stock_unit']]
        .map((part) => part?.toString().trim() ?? '')
        .where((part) => part.isNotEmpty && part != 'null')
        .toList();
    return parts.join(' ');
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

  int? _positiveInt(dynamic value) {
    final number = _asInt(value);
    return number > 0 ? number : null;
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
