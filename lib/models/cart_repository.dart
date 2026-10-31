import 'package:dio/dio.dart';
import 'package:get/get.dart' show Trans;

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

  /// Like [fetchList], but "cart not found" means an empty general cart.
  /// Restaurant-only carts have none, and that must not hide the restaurant cart.
  Future<
    ({
      String vendorName,
      List<Map<String, dynamic>> items,
      int? vendorId,
      int? cartId,
    })
  >
  fetchListOrEmpty(String language) async {
    try {
      return await fetchList(language);
    } on ApiException {
      return (
        vendorName: '',
        items: const <Map<String, dynamic>>[],
        vendorId: null,
        cartId: null,
      );
    }
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
      ..._lines(data['items'], language),
      ..._lines(data['basket_items'], language),
    ];
    return (
      vendorName: _vendorName(data, language),
      items: items,
      vendorId: _positiveInt(data['vendor_id']),
      cartId: _positiveInt(data['cart_id']),
    );
  }

  /// Restaurant add: variant_id plus optional option_ids[] and extra_ids[] (add-ons).
  Future<String> addCatalogItem({
    required int restaurantId,
    required int variantId,
    required String language,
    int quantity = 1,
    List<int> optionIds = const [],
    List<int> extraIds = const [],
  }) async {
    final count = quantity < 1 ? 1 : quantity;
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.catalogCartAdd,
        data: FormData.fromMap({
          'restaurant_id': '$restaurantId',
          'variant_id': '$variantId',
          'quantity': '$count',
          if (optionIds.isNotEmpty)
            'option_ids[]': optionIds.map((id) => '$id').toList(),
          if (extraIds.isNotEmpty)
            'extra_ids[]': extraIds.map((id) => '$id').toList(),
        }),
      ),
      language,
    );
    return envelope.message;
  }

  /// Restaurant cart (vendor, cart id and lines in the catalog shape).
  Future<
    ({
      String vendorName,
      List<Map<String, dynamic>> items,
      int? vendorId,
      int? cartId,
    })
  >
  fetchCatalogList(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.catalogCartList),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final vendor = asJsonMap(data['vendor']) ?? <String, dynamic>{};
    return (
      vendorName: _catalogVendorName(vendor, language),
      items: _catalogLines(data['items'], language),
      vendorId: _positiveInt(vendor['id']),
      cartId: _positiveInt(data['cart_id']),
    );
  }

  /// Totals across the general cart (grocery, pharmacy) and the restaurant cart.
  /// [cartName] is the store holding the items (restaurant or grocery), or empty.
  Future<({int count, double amount, String cartName})> fetchCartTotals(
    String language,
  ) async {
    var count = 0;
    var amount = 0.0;
    var cartName = '';
    var loaded = 0;
    Object? lastError;

    try {
      final general = await fetchList(language);
      loaded++;
      for (final line in general.items) {
        count += (line['quantity'] as num?)?.toInt() ?? 1;
        amount += (line['lineTotal'] as num?)?.toDouble() ?? 0;
      }
      if (general.items.isNotEmpty) cartName = general.vendorName;
    } catch (error) {
      lastError = error;
    }

    try {
      final catalog = await fetchCatalogList(language);
      loaded++;
      for (final line in catalog.items) {
        count += (line['quantity'] as num?)?.toInt() ?? 1;
        amount += (line['lineTotal'] as num?)?.toDouble() ?? 0;
      }
      if (catalog.items.isNotEmpty) cartName = catalog.vendorName;
    } catch (error) {
      lastError = error;
    }

    if (loaded == 0 && lastError != null) throw lastError;
    return (count: count, amount: amount, cartName: cartName);
  }

  /// Add-on names for a restaurant line, e.g. "Chilli, Rice".
  String _catalogAddOnNames(dynamic raw) {
    if (raw is! List) return '';
    return raw
        .map((option) => asJsonMap(option)?['option_name']?.toString().trim())
        .where((name) => name != null && name.isNotEmpty && name != 'null')
        .join(', ');
  }

  String _catalogVendorName(Map<String, dynamic> vendor, String language) {
    final localized = _localizedField(vendor, 'name', language);
    if (localized.isNotEmpty) return localized;
    final name = vendor['name']?.toString().trim() ?? '';
    return name == 'null' ? '' : name;
  }

  List<Map<String, dynamic>> _catalogLines(dynamic raw, String language) {
    if (raw is! List) return const [];
    final lines = <Map<String, dynamic>>[];
    for (final item in raw) {
      final map = asJsonMap(item);
      if (map == null) continue;
      final quantity = _asInt(map['quantity'], fallback: 1);
      final unit = _asDouble(map['unit_price'] ?? map['base_price']);
      final total = map['total_price'] == null
          ? unit * quantity
          : _asDouble(map['total_price']);
      final name = _localizedField(map, 'name', language);
      final variant = map['variant_name']?.toString().trim() ?? '';
      lines.add({
        'cartItemId': _asInt(map['cart_item_id']),
        'name': name.isEmpty ? 'Item' : name,
        'portion': variant == 'null' ? '' : variant,
        'addOns': _catalogAddOnNames(map['options']),
        'quantity': quantity < 1 ? 1 : quantity,
        'unitPrice': unit,
        'lineTotal': total,
        'maxQuantity': _positiveInt(map['quantity_allowed']),
        'image': ApiConstants.mediaUrl(map['image']?.toString()) ?? '',
      });
    }
    return lines;
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
          data['needs_prescription'] == true || data['needs_prescription'] == 1,
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

  List<Map<String, dynamic>> _lines(dynamic raw, String language) {
    if (raw is! List) return const [];
    final lines = <Map<String, dynamic>>[];
    for (final item in raw) {
      final map = asJsonMap(item);
      if (map == null) continue;
      final name = _itemName(map, language);
      final quantity = _asInt(map['quantity'], fallback: 1);
      final unit = _asDouble(
        map['unit_price'] ?? map['price'] ?? map['selling_price'],
      );
      // A zero total with a real unit price is missing data, so compute it.
      final serverTotal = _asDouble(map['total_price']);
      final total = serverTotal > 0 ? serverTotal : unit * quantity;
      lines.add({
        'cartItemId': _asInt(map['cart_item_id']),
        'name': name.isEmpty ? 'Item' : name,
        'portion': _itemPortion(map, language),
        'quantity': quantity < 1 ? 1 : quantity,
        'unitPrice': unit,
        'lineTotal': total,
        'maxQuantity':
            _positiveInt(map['quantity_allowed']) ?? _positiveInt(map['stock']),
        'image':
            ApiConstants.mediaUrl(
              map['image']?.toString() ?? map['item_image']?.toString(),
            ) ??
            '',
      });
    }
    return lines;
  }

  /// Changes a restaurant (catalog) cart line's quantity; the screen reloads the cart after.
  Future<void> updateCatalogItem({
    required int cartItemId,
    required int quantity,
    required String language,
  }) async {
    await _send(
      () => _client.dio.post(
        ApiConstants.catalogCartUpdate,
        data: {'cart_item_id': '$cartItemId', 'quantity': '$quantity'},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
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

  /// Removes every restaurant (catalog) line. The general replace call doesn't touch these,
  /// so a store switch to grocery deletes them one by one.
  Future<void> clearCatalogCart({required String language}) async {
    final catalog = await fetchCatalogListOrEmpty(language);
    for (final line in catalog.items) {
      final cartItemId = line['cartItemId'] as int;
      if (cartItemId < 1) continue;
      await deleteCatalogItem(cartItemId: cartItemId, language: language);
    }
  }

  /// Like [fetchCatalogList], but "cart not found" means no restaurant cart.
  Future<
    ({
      String vendorName,
      List<Map<String, dynamic>> items,
      int? vendorId,
      int? cartId,
    })
  >
  fetchCatalogListOrEmpty(String language) async {
    try {
      return await fetchCatalogList(language);
    } on ApiException {
      return (
        vendorName: '',
        items: const <Map<String, dynamic>>[],
        vendorId: null,
        cartId: null,
      );
    }
  }

  /// Removes a restaurant (catalog) cart line; the response is the cart after removal.
  Future<String> deleteCatalogItem({
    required int cartItemId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.catalogCartItemDelete,
        data: {'cart_item_id': '$cartItemId'},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
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

  String _itemPortion(Map<String, dynamic> item, String language) {
    final direct = item['portion']?.toString().trim() ?? '';
    if (direct.isNotEmpty && direct != 'null') return direct;
    final variant = _localizedField(item, 'variant_name', language);
    if (variant.isNotEmpty) return variant;
    final parts = [item['form'], item['dosage'], item['stock_unit']]
        .map((part) => part?.toString().trim() ?? '')
        .where((part) => part.isNotEmpty && part != 'null')
        .toList();
    return parts.join(' ');
  }

  /// Restaurant lines carry `<key>_<lang>` fields; try the app language first.
  String _localizedField(
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

  String _itemName(Map<String, dynamic> item, String language) {
    final localized = _localizedField(item, 'item_name', language);
    if (localized.isNotEmpty) return localized;
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
          error.message.isEmpty ? 'core_request_failed'.tr : error.message,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }
}
