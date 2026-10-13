import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

class PharmacyRepository {
  PharmacyRepository(this._client);

  final DioClient _client;

  Future<
    ({
      List<String> sliders,
      List<Map<String, dynamic>> categories,
      List<Map<String, dynamic>> trustedPharmacies,
      List<Map<String, dynamic>> nearbyPharmacies,
      List<Map<String, dynamic>> pharmacies,
      List<Map<String, dynamic>> sections,
    })
  >
  fetchHome({
    required double latitude,
    required double longitude,
    required String language,
    int limit = 10,
  }) async {
    final data = await _postHome(
      latitude: latitude,
      longitude: longitude,
      language: language,
      limit: limit,
    );
    return (
      sliders: _sliderImages(data),
      categories: _homeCategories(data['categories'], language),
      trustedPharmacies: _pharmacyCards(data['trusted_pharmacies'], language),
      nearbyPharmacies: _pharmacyCards(data['nearby_pharmacies'], language),
      pharmacies: _pharmacyCards(data['pharmacies'], language),
      sections: _homeSections(data['sections'], language),
    );
  }

  List<String> _sliderImages(Map<String, dynamic> data) {
    final sliders = data['sliders'];
    if (sliders is! List) return const [];

    final images = <String>[];
    for (final item in sliders) {
      final slider = asJsonMap(item);
      final image = ApiConstants.mediaUrl(slider?['image']?.toString());
      if (image != null) images.add(image);
    }
    return images;
  }

  List<Map<String, dynamic>> _homeCategories(dynamic raw, String language) {
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

  List<Map<String, dynamic>> _homeSections(dynamic raw, String language) {
    if (raw is! List) return const [];
    final sections = <Map<String, dynamic>>[];
    for (final item in raw) {
      final section = asJsonMap(item);
      if (section == null) continue;
      final key = section['key']?.toString().trim() ?? '';
      if (key.isEmpty) continue;
      sections.add({
        'key': key,
        'title': _localized(section, 'title', language),
        'seeAll': section['see_all'],
      });
    }
    return sections;
  }

  List<Map<String, dynamic>> _pharmacyCards(dynamic raw, String language) {
    if (raw is! List) return const [];

    final pharmacies = <Map<String, dynamic>>[];
    for (final item in raw) {
      final pharmacy = asJsonMap(item);
      if (pharmacy == null) continue;
      pharmacies.add(_nearbyCard(pharmacy, language));
    }
    return pharmacies;
  }

  Future<
    ({
      Map<String, dynamic> pharmacy,
      List<Map<String, dynamic>> categories,
      int selectedCategoryId,
      List<Map<String, dynamic>> items,
      int currentPage,
      int lastPage,
    })
  >
  fetchStore({
    required int pharmacyId,
    required double latitude,
    required double longitude,
    required String language,
    int? categoryId,
    String keyword = '',
    int limit = 20,
    int page = 1,
  }) async {
    final query = <String, dynamic>{
      'pharmacy_id': pharmacyId,
      'lat': latitude.toString(),
      'long': longitude.toString(),
      'limit': limit,
      'page': page,
    };
    if (categoryId != null && categoryId != 0) {
      query['category_id'] = categoryId;
    }
    final search = keyword.trim();
    if (search.isNotEmpty) query['keyword'] = search;

    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.pharmacyStore,
        queryParameters: query,
      ),
      language,
    );

    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final items = asJsonMap(data['items']);
    return (
      pharmacy: _storeHeader(asJsonMap(data['pharmacy']) ?? {}, language),
      categories: _storeCategories(data['categories'], language),
      selectedCategoryId: _asInt(data['selected_category_id']),
      items: _storeItems(items?['data'], language),
      currentPage: _asInt(items?['current_page'], fallback: page),
      lastPage: _asInt(items?['last_page'], fallback: page),
    );
  }

  Future<Map<String, dynamic>> fetchItemDetail({
    required int menuId,
    required int pharmacyId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.pharmacyItemDetail,
        queryParameters: {
          'menu_id': menuId,
          'pharmacy_id': pharmacyId,
        },
      ),
      language,
    );

    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final menu = asJsonMap(data['menu']);
    if (menu == null) {
      throw const ApiException('Unexpected server response');
    }
    final variants = data['variants'];
    final variant = variants is List && variants.isNotEmpty
        ? asJsonMap(variants.first)
        : null;
    return _itemDetail(menu, variant, language);
  }

  Future<List<Map<String, dynamic>>> fetchSelectablePharmacies({
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final data = await _postHome(
      latitude: latitude,
      longitude: longitude,
      language: language,
    );
    final pharmacies = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final source in [
      data['nearby_pharmacies'],
      data['trusted_pharmacies'],
      data['pharmacies'],
    ]) {
      for (final card in _pharmacyCards(source, language)) {
        final id = '${card['id'] ?? ''}';
        if (id.isEmpty || !seen.add(id)) continue;
        pharmacies.add(card);
      }
    }
    return pharmacies;
  }

  Future<String> uploadPrescription({
    required int pharmacyId,
    required String contactNumber,
    required bool callBeforeAlternative,
    required String filePath,
    required String language,
    String? note,
  }) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final fields = <String, dynamic>{
      'pharmacy_id': '$pharmacyId',
      'contact_number': contactNumber,
      'call_before_alternative': callBeforeAlternative ? '1' : '0',
      'files': await MultipartFile.fromFile(filePath, filename: fileName),
    };
    final trimmedNote = note?.trim() ?? '';
    if (trimmedNote.isNotEmpty) fields['note'] = trimmedNote;

    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.prescriptionUpload,
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

  Future<
    ({
      List<Map<String, dynamic>> orders,
      int currentPage,
      int lastPage,
    })
  >
  fetchOrders({
    required String language,
    int limit = 10,
    int page = 1,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.pharmacyOrders,
        queryParameters: {'limit': limit, 'page': page},
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final raw = data['data'];
    final orders = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final item in raw) {
        final order = asJsonMap(item);
        if (order != null) orders.add(_orderCard(order));
      }
    }
    return (
      orders: orders,
      currentPage: _asInt(data['current_page'], fallback: page),
      lastPage: _asInt(data['last_page'], fallback: page),
    );
  }

  Map<String, dynamic> _orderCard(Map<String, dynamic> item) {
    final file = asJsonMap(item['file']);
    final statusText =
        (item['status_text'] ?? item['prescription_status_label'] ?? '')
            .toString()
            .trim();
    final cardType = item['card_type']?.toString() ?? '';
    final isPrescription = cardType == 'prescription';
    final quoted =
        item['action']?.toString().toUpperCase() == 'PAY' ||
        item['prescription_status']?.toString() == 'quoted' ||
        statusText.toLowerCase().contains('quotation');
    final selfPickup =
        item['is_self_pickup'] == 1 || item['is_self_pickup'] == true;
    final code = item['order_code']?.toString().trim() ?? '';
    final prescriptionId = item['prescription_id'];
    final orderId = code.isNotEmpty
        ? code
        : (prescriptionId == null ? '' : '#$prescriptionId');
    return {
      'pharmacyName': (item['vendor_name']?.toString().trim().isNotEmpty ??
              false)
          ? item['vendor_name'].toString().trim()
          : 'Pharmacy',
      'statusText': statusText.isEmpty ? 'Order' : statusText,
      'isQuotation': quoted,
      'isPrescription': isPrescription,
      'isSelfPickup': selfPickup,
      'isCancelled': statusText.toLowerCase().contains('cancel'),
      'orderId': orderId,
      'amount': _moneyText(item['quote_amount'] ?? item['total']),
      'totalText': _moneyText(item['total']),
      'expiresInSeconds': _asInt(item['quote_expires_in_seconds']),
      'itemsCount': _asInt(item['items_count']),
      'fileName': file?['name']?.toString().trim() ?? '',
    };
  }

  Future<Map<String, dynamic>> _postHome({
    required double latitude,
    required double longitude,
    required String language,
    int limit = 10,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.pharmacyHome,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'limit': limit,
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return asJsonMap(envelope.data) ?? <String, dynamic>{};
  }

  Map<String, dynamic> _itemDetail(
    Map<String, dynamic> menu,
    Map<String, dynamic>? variant,
    String language,
  ) {
    final images = _itemImages(menu);
    final name = _localized(menu, 'name', language);
    final description = _localized(menu, 'description', language);
    final detail = variant ?? menu;
    final tag = _itemTag(detail);
    final selling = detail['selling_price'] ?? detail['discount_price'];
    final mrp = detail['mrp_amount'] ?? detail['mrp'] ?? menu['mrp'];
    return {
      'id': '${menu['menu_id'] ?? ''}',
      'title': name,
      'image': images.isEmpty ? '' : images.first,
      'images': images,
      'tag': tag.isNotEmpty ? tag : _itemTag(menu),
      'rating': _ratingText(menu['rating'] ?? menu['avg_rating']),
      'reviews': '${menu['rating_count'] ?? 0}',
      'price': _moneyText(selling ?? menu['selling_price']),
      'originalPrice': _moneyText(mrp ?? menu['price']),
      'discount': _offerText(
        variant == null ? menu['offer_percentage'] : variant['offer_percentage'],
      ),
      'prescriptionRequired':
          detail['prescription_required'] == 1 ||
          detail['prescription_required'] == true,
      'description': description,
      'stock': variant?['stock'],
      'quantityAllowed': variant?['quantity_allowed'],
    };
  }

  Map<String, dynamic> _storeHeader(
    Map<String, dynamic> item,
    String language,
  ) {
    final name = _localized(item, 'name', language);
    final time = item['preparation_time']?.toString().trim() ?? '';
    return {
      'id': '${item['pharmacy_id'] ?? ''}',
      'title': name,
      'subtitle': item['address']?.toString() ?? '',
      'image': ApiConstants.mediaUrl(item['image']?.toString()) ?? '',
      'rating': _ratingText(item['rating']),
      'time': time,
      'dist': _distanceText(item['distance_km']),
      'discount': _offerText(item['offer_percentage']),
    };
  }

  List<Map<String, dynamic>> _storeCategories(dynamic raw, String language) {
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

  List<Map<String, dynamic>> _storeItems(dynamic raw, String language) {
    if (raw is! List) return const [];
    final items = <Map<String, dynamic>>[];
    for (final entry in raw) {
      final item = asJsonMap(entry);
      if (item == null) continue;
      final images = _itemImages(item);
      final name = _localized(item, 'name', language);
      final description = _localized(item, 'description', language);
      final subtitle = _localized(item, 'subtitle', language);
      final selling = item['selling_price'] ?? item['discount_price'];
      items.add({
        'id': '${item['menu_id'] ?? ''}',
        'title': name,
        'image': images.isEmpty ? '' : images.first,
        'images': images,
        'tag': _itemTag(item),
        'rating': _ratingText(item['rating']),
        'reviews': '${item['rating_count'] ?? 0}',
        'price': _moneyText(selling),
        'originalPrice': _moneyText(item['mrp'] ?? item['price']),
        'discount': _offerText(item['offer_percentage']),
        'prescriptionRequired':
            item['prescription_required'] == 1 ||
            item['prescription_required'] == true,
        'description': description.isNotEmpty ? description : subtitle,
      });
    }
    return items;
  }

  List<String> _itemImages(Map<String, dynamic> item) {
    final images = <String>[];
    final raw = item['images'];
    if (raw is List) {
      for (final entry in raw) {
        final url = ApiConstants.mediaUrl(entry?.toString());
        if (url != null && !images.contains(url)) images.add(url);
      }
    }
    final single = ApiConstants.mediaUrl(item['image']?.toString());
    if (single != null && !images.contains(single)) images.insert(0, single);
    return images;
  }

  String _itemTag(Map<String, dynamic> item) {
    return [item['form'], item['dosage'], item['stock_unit']]
        .map((part) => part?.toString().trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(' • ');
  }

  String _ratingText(dynamic value) {
    final number = double.tryParse('$value');
    if (number == null) return '${value ?? ''}'.trim();
    if (number == number.roundToDouble()) return number.toInt().toString();
    return number.toStringAsFixed(1);
  }

  String _distanceText(dynamic value) {
    final number = double.tryParse('$value');
    if (number == null) {
      final text = '${value ?? ''}'.trim();
      if (text.isEmpty) return '';
      return text.toLowerCase().contains('km') ? text : '$text Km';
    }
    final text = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);
    return '$text Km';
  }

  String _offerText(dynamic value) {
    final number = double.tryParse('$value');
    if (number == null || number <= 0) return '';
    final text = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(0);
    return '$text% OFF';
  }

  String _moneyText(dynamic value) {
    final number = double.tryParse('$value');
    if (number == null) {
      final text = '${value ?? ''}'.trim();
      if (text.isEmpty) return '';
      return text.toUpperCase().contains('MRU') ? text : '$text MRU';
    }
    final text = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(2);
    return '$text MRU';
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
  }

  Map<String, dynamic> _nearbyCard(
    Map<String, dynamic> item,
    String language,
  ) {
    final name = _localized(item, 'name', language);
    final status = _localized(item, 'status_label', language);
    final points = item['points_label']?.toString().trim() ?? '';
    final offer = item['offer_text']?.toString().trim() ?? '';
    final isOpen = item['is_open'] == 1 || item['is_open'] == true;
    final isOpenAllDay = item['is_open_24h'] == 1 || item['is_open_24h'] == true;

    return {
      'id': '${item['pharmacy_id'] ?? item['id'] ?? item['store_id'] ?? ''}',
      'title': name.isEmpty ? 'Pharmacy' : name,
      'subtitle': item['address']?.toString() ?? '',
      'rating': '${item['rating'] ?? 0}',
      'time': '${item['delivery_time_text'] ?? item['estimated_time'] ?? ''}',
      'dist': '${item['distance'] ?? ''}',
      'discount': offer,
      'points': points,
      'isClosed': !isOpen,
      'isTemporarilyClosed': false,
      'isOpen247': isOpenAllDay,
      'opensAt': status,
      'image': ApiConstants.mediaUrl(item['image']?.toString()) ?? '',
      'latitude': double.tryParse('${item['latitude']}'),
      'longitude': double.tryParse('${item['longitude']}'),
    };
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
