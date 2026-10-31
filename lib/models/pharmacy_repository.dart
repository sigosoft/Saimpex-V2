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
      List<Map<String, dynamic>> trustedPharmacies,
      List<Map<String, dynamic>> nearbyPharmacies,
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
      trustedPharmacies: _pharmacyCards(data['trusted_pharmacies'], language),
      nearbyPharmacies: _pharmacyCards(data['nearby_pharmacies'], language),
      sections: _homeSections(data['sections'], language),
    );
  }

  Future<List<Map<String, dynamic>>> fetchHomeCategories({
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.pharmacyHomeCategories,
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
    return _homeCategories(data['categories'], language);
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
    final entries = <({int order, int index, Map<String, dynamic> category})>[];
    for (var index = 0; index < raw.length; index++) {
      final category = asJsonMap(raw[index]);
      if (category == null) continue;
      entries.add((
        order: _asInt(category['sort_order']),
        index: index,
        category: category,
      ));
    }
    entries.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.index.compareTo(b.index);
    });
    final categories = <Map<String, dynamic>>[];
    for (final entry in entries) {
      final category = entry.category;
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
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.pharmacyStore,
        queryParameters: {
          'pharmacy_id': pharmacyId,
          'lat': latitude.toString(),
          'long': longitude.toString(),
          'category_id': categoryId == null || categoryId == 0
              ? ''
              : '$categoryId',
          'keyword': keyword.trim(),
          'limit': limit,
          'page': page,
        },
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

  Future<List<Map<String, dynamic>>> fetchPharmacyCategories({
    required int pharmacyId,
    required String language,
    String keyword = '',
  }) async {
    final query = <String, dynamic>{'pharmacy_id': pharmacyId};
    final search = keyword.trim();
    if (search.isNotEmpty) query['keyword'] = search;

    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.pharmacyCategories,
        queryParameters: query,
      ),
      language,
    );
    final data = envelope.data;
    return _storeCategories(
      data is List ? data : asJsonMap(data)?['categories'],
      language,
    );
  }

  Future<({List<Map<String, dynamic>> items, int currentPage, int lastPage})>
  fetchPharmacyItems({
    required int pharmacyId,
    required String language,
    int? categoryId,
    String keyword = '',
    int limit = 20,
    int page = 1,
  }) async {
    final body = <String, dynamic>{
      'pharmacy_id': pharmacyId.toString(),
      'keyword': keyword.trim(),
      'limit': limit.toString(),
      'page': page.toString(),
    };
    if (categoryId != null && categoryId != 0) {
      body['category_id'] = categoryId.toString();
    }

    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.pharmacyItems,
        data: body,
        queryParameters: {'page': page},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return (
      items: _storeItems(data['data'], language),
      currentPage: _asInt(data['current_page'], fallback: page),
      lastPage: _asInt(data['last_page'], fallback: page),
    );
  }

  Future<({List<Map<String, dynamic>> items, int currentPage, int lastPage})>
  fetchCategoryItems({
    required int pharmacyId,
    required int categoryId,
    required String language,
    int page = 1,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.pharmacyCategoryItems,
        data: {
          'pharmacy_id': pharmacyId.toString(),
          'category_id': categoryId.toString(),
        },
        queryParameters: {'page': page},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final items = asJsonMap(data['items']);
    return (
      items: _storeItems(items?['data'], language),
      currentPage: _asInt(items?['current_page'], fallback: page),
      lastPage: _asInt(items?['last_page'], fallback: page),
    );
  }

  Future<List<Map<String, dynamic>>> fetchCategoryPharmacies({
    required int categoryId,
    required double latitude,
    required double longitude,
    required String language,
    String keyword = '',
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.pharmacyCategoryPharmacies,
        data: {
          'skip_radius': '',
          'keyword': keyword.trim(),
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'category_id': categoryId.toString(),
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return _pharmacyCards(data['pharmacies'], language);
  }

  Future<Map<String, dynamic>> fetchDetails({
    required int pharmacyId,
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.pharmacyDetails,
        queryParameters: {
          'pharmacy_id': pharmacyId,
          'lat': latitude.toString(),
          'long': longitude.toString(),
        },
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return _pharmacyDetails(data, language);
  }

  Map<String, dynamic> _pharmacyDetails(
    Map<String, dynamic> item,
    String language,
  ) {
    final header = _storeHeader(item, language);
    header['latitude'] = double.tryParse('${item['latitude']}');
    header['longitude'] = double.tryParse('${item['longitude']}');
    header['deliveryRadius'] = item['delivery_radius_km'];
    header['ratingCount'] = _asInt(item['rating_count']);
    return header;
  }

  Future<Map<String, dynamic>> fetchItemDetail({
    required int menuId,
    required int pharmacyId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.pharmacyItemDetail,
        queryParameters: {'menu_id': menuId, 'pharmacy_id': pharmacyId},
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

  Future<List<Map<String, dynamic>>> fetchPrescriptionPharmacies({
    required double latitude,
    required double longitude,
    required String language,
    String keyword = '',
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.prescriptionPharmacies,
        data: {
          'keyword': keyword.trim(),
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return _pharmacyCards(data['pharmacies'], language);
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
    ({List<Map<String, dynamic>> prescriptions, int currentPage, int lastPage})
  >
  fetchPrescriptionsList({
    required String language,
    String? status,
    String? flowType,
    int limit = 10,
    int page = 1,
  }) async {
    final query = <String, dynamic>{'limit': limit, 'page': page};
    final trimmedStatus = status?.trim() ?? '';
    if (trimmedStatus.isNotEmpty) query['status'] = trimmedStatus;
    final trimmedFlow = flowType?.trim() ?? '';
    if (trimmedFlow.isNotEmpty) query['flow_type'] = trimmedFlow;

    final envelope = await _send(
      () => _client.dio.get(ApiConstants.prescriptions, queryParameters: query),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final paged = asJsonMap(data['prescriptions']) ?? <String, dynamic>{};
    final raw = paged['data'];
    final items = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final entry in raw) {
        final item = asJsonMap(entry);
        if (item != null) items.add(_prescriptionListItem(item));
      }
    }
    return (
      prescriptions: items,
      currentPage: _asInt(paged['current_page'], fallback: page),
      lastPage: _asInt(paged['last_page'], fallback: page),
    );
  }

  Map<String, dynamic> _prescriptionListItem(Map<String, dynamic> item) {
    return {
      'prescriptionId': _asInt(item['prescription_id']),
      'pharmacyId': _asInt(item['pharmacy_id']),
      'pharmacyName': '${item['pharmacy_name'] ?? ''}'.trim(),
      'flowType': '${item['flow_type'] ?? ''}'.trim(),
      'status': '${item['status'] ?? ''}'.trim(),
      'statusLabel': '${item['status_label'] ?? ''}'.trim(),
      'quoteAmountText': item['quote_amount'] == null
          ? ''
          : _moneyText(item['quote_amount']),
      'quoteExpiresAt': '${item['quote_expires_at'] ?? ''}'.trim(),
      'paymentRequestedAt': '${item['payment_requested_at'] ?? ''}'.trim(),
      'createdAt': '${item['created_at'] ?? ''}'.trim(),
      'contactNumber': '${item['contact_number'] ?? ''}'.trim(),
      'callBeforeAlternative':
          item['call_before_alternative'] == 1 ||
          item['call_before_alternative'] == true,
    };
  }

  Future<Map<String, dynamic>> fetchPrescription({
    required int prescriptionId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.prescriptionById(prescriptionId)),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final files = data['files'];
    Map<String, dynamic>? file;
    if (files is List && files.isNotEmpty) {
      file = asJsonMap(files.first);
    }
    final fileMap = file ?? asJsonMap(data['file']);
    var fileUrl = '${fileMap?['url'] ?? ''}'.trim();
    final images = data['images'];
    if (fileUrl.isEmpty && images is List && images.isNotEmpty) {
      fileUrl = '${images.first}'.trim();
    }
    final pathName = '${fileMap?['path'] ?? fileMap?['name'] ?? ''}'
        .split(RegExp(r'[/\\]'))
        .last;
    final rawItems = data['items'] ?? data['quoted_items'] ?? data['medicines'];
    final items = <Map<String, dynamic>>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        final item = asJsonMap(entry);
        if (item != null) items.add(_prescriptionItem(item, language));
      }
    }
    data['message'] = envelope.message;
    data['mapped_pharmacy_name'] =
        '${data['pharmacy_name'] ?? data['vendor_name'] ?? ''}'.trim();
    data['mapped_items'] = items;
    data['mapped_file_name'] = pathName;
    data['mapped_file_url'] = fileUrl;
    return data;
  }

  /// Pays an accepted quote. The server needs the same delivery fields as checkout:
  /// location is required for delivery. [paymentType] is online (2) or wallet (3);
  /// a wallet payment places and pays the order at once (payment_required false).
  Future<Map<String, dynamic>> payPrescription({
    required int prescriptionId,
    required bool selfPickup,
    required double latitude,
    required double longitude,
    required String location,
    String paymentType = '2',
    required String language,
    String couponCode = '',
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.prescriptionPay(prescriptionId),
        data: {
          'is_self_pickup': selfPickup ? '1' : '0',
          'lat': latitude.toString(),
          'long': longitude.toString(),
          'location': location,
          'payment_type': paymentType,
          if (couponCode.isNotEmpty) 'coupon_code': couponCode,
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    data['message'] = envelope.message;
    return data;
  }

  Future<String> acceptPrescription({
    required int prescriptionId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.prescriptionAccept(prescriptionId),
        data: <String, dynamic>{},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  /// Accepts or rejects suggested alternatives while the quote is `quoted`
  /// (prescription/{id}/alternatives). The server recomputes `quote_amount`.
  Future<String> decideAlternatives({
    required int prescriptionId,
    required Map<int, bool> decisions,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.prescriptionAlternatives(prescriptionId),
        data: {
          'decisions': [
            for (final entry in decisions.entries)
              {'item_id': entry.key, 'accept': entry.value},
          ],
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  /// Declines a quotation (status quoted → rejected).
  Future<String> declinePrescription({
    required int prescriptionId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.prescriptionDecline(prescriptionId),
        data: <String, dynamic>{},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  Map<String, dynamic> _prescriptionItem(
    Map<String, dynamic> item,
    String language,
  ) {
    var name = _localized(item, 'name', language);
    if (name.isEmpty) {
      name =
          '${item['menu_name'] ?? item['product_name'] ?? item['title'] ?? ''}'
              .trim();
    }
    final alternative = asJsonMap(
      item['alternative'] ?? item['suggested_alternative'],
    );
    var alternativeName = '';
    if (alternative != null) {
      alternativeName = _localized(alternative, 'name', language);
      if (alternativeName.isEmpty) {
        alternativeName =
            '${alternative['menu_name'] ?? alternative['product_name'] ?? ''}'
                .trim();
      }
    }
    // Per-item quote: an alternative is its own line, naming the requested
    // medicine it replaces in alternative_for.
    final alternativeFor = '${item['alternative_for'] ?? ''}'.trim();
    final requested = item['requested_quantity'];
    final decision = '${item['customer_decision'] ?? ''}'.trim();
    return {
      'itemId': _asInt(item['item_id'] ?? item['id']),
      // available | partial | unavailable
      'availability': '${item['availability'] ?? 'available'}'.trim(),
      'requestedQty': requested == null ? null : _asInt(requested),
      // accepted | rejected | '' (not decided yet)
      'decision': decision == 'null' ? '' : decision,
      'included': item['included'] != false && item['included'] != 0,
      'name': name.isEmpty ? 'Item' : name,
      'qty': _asInt(item['quantity'], fallback: 1),
      'unitText': _moneyText(item['unit_price'] ?? item['price']),
      'totalText': _moneyText(
        item['total_price'] ?? item['total'] ?? item['line_total'],
      ),
      'isAlternative':
          item['is_alternative'] == true ||
          item['is_alternative'] == 1 ||
          alternative != null ||
          alternativeFor.isNotEmpty,
      'originalName': alternativeFor.isNotEmpty
          ? alternativeFor
          : '${item['original_name'] ?? item['requested_name'] ?? ''}'.trim(),
      'outOfStock':
          item['out_of_stock'] == true ||
          item['in_stock'] == false ||
          (item['stock'] != null && _asInt(item['stock']) == 0),
      'alternativeName': alternativeName.isNotEmpty
          ? alternativeName
          : (alternativeFor.isNotEmpty ? name : ''),
      'alternativeQty': alternative == null
          ? _asInt(item['quantity'], fallback: 1)
          : _asInt(alternative['quantity'], fallback: 1),
      'alternativeUnitText': alternative == null
          ? _moneyText(item['unit_price'] ?? item['price'])
          : _moneyText(alternative['unit_price'] ?? alternative['price']),
      'alternativeTotalText': alternative == null
          ? _moneyText(item['total_price'] ?? item['total'])
          : _moneyText(
              alternative['total_price'] ??
                  alternative['total'] ??
                  alternative['line_total'],
            ),
    };
  }

  Future<({List<Map<String, dynamic>> orders, int currentPage, int lastPage})>
  fetchOrders({required String language, int limit = 10, int page = 1}) async {
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
      'pharmacyName':
          (item['vendor_name']?.toString().trim().isNotEmpty ?? false)
          ? item['vendor_name'].toString().trim()
          : 'Pharmacy',
      'statusText': statusText.isEmpty ? 'Order' : statusText,
      'isQuotation': quoted,
      'isPrescription': isPrescription,
      'isSelfPickup': selfPickup,
      'isCancelled': statusText.toLowerCase().contains('cancel'),
      'orderId': orderId,
      'numericOrderId': _asInt(item['order_id'] ?? item['id']),
      'vendorId': _asInt(item['vendor_id']),
      'prescriptionId': _asInt(prescriptionId),
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
      'productId': _productId(variant ?? menu),
      'title': name,
      'image': images.isEmpty ? '' : images.first,
      'images': images,
      'tag': tag.isNotEmpty ? tag : _itemTag(menu),
      'rating': _ratingText(menu['rating'] ?? menu['avg_rating']),
      'reviews': '${menu['rating_count'] ?? 0}',
      'price': _moneyText(selling ?? menu['selling_price']),
      'originalPrice': _moneyText(mrp ?? menu['price']),
      'discount': _offerText(
        variant == null
            ? menu['offer_percentage']
            : variant['offer_percentage'],
      ),
      'prescriptionRequired':
          detail['prescription_required'] == 1 ||
          detail['prescription_required'] == true,
      'description': description,
      'quantityAllowed': _positiveInt(variant?['quantity_allowed']),
      'stock': _positiveInt(variant?['stock']),
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
        'productId': _productId(item),
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
        'quantityAllowed': _quantityAllowed(item),
        'stock': _stockCount(item),
        'description': description.isNotEmpty ? description : subtitle,
      });
    }
    return items;
  }

  List<String> _itemImages(Map<String, dynamic> item) {
    final images = <String>[];
    void add(dynamic value) {
      if (value is List) {
        for (final entry in value) {
          add(entry);
        }
        return;
      }
      if (value is Map) {
        final map = asJsonMap(value);
        add(map?['url'] ?? map?['path'] ?? map?['image']);
        return;
      }
      final url = ApiConstants.mediaUrl(value?.toString());
      if (url != null && !images.contains(url)) images.add(url);
    }

    add(item['images']);
    add(item['image']);
    return images;
  }

  int? _positiveInt(dynamic value) {
    final number = _asInt(value);
    return number > 0 ? number : null;
  }

  int? _quantityAllowed(Map<String, dynamic> item) {
    final direct = _positiveInt(item['quantity_allowed']);
    if (direct != null) return direct;
    final variants = item['variants'];
    if (variants is! List) return null;
    for (final entry in variants) {
      final variant = asJsonMap(entry);
      final allowed = _positiveInt(variant?['quantity_allowed']);
      if (allowed != null) return allowed;
    }
    return null;
  }

  int? _stockCount(Map<String, dynamic> item) {
    final direct = _positiveInt(item['stock']);
    if (direct != null) return direct;
    final variants = item['variants'];
    if (variants is! List) return null;
    for (final entry in variants) {
      final variant = asJsonMap(entry);
      final stock = _positiveInt(variant?['stock']);
      if (stock != null) return stock;
    }
    return null;
  }

  int? _productId(Map<String, dynamic> item) {
    final direct = _asInt(item['product_id']);
    if (direct > 0) return direct;
    final variants = item['variants'];
    if (variants is! List) return null;
    for (final entry in variants) {
      final variant = asJsonMap(entry);
      if (variant == null) continue;
      final id = _asInt(variant['product_id'] ?? variant['item_id']);
      if (id > 0) return id;
    }
    return null;
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

  Map<String, dynamic> _nearbyCard(Map<String, dynamic> item, String language) {
    final name = _localized(item, 'name', language);
    final status = _localized(item, 'status_label', language);
    final points = item['points_label']?.toString().trim() ?? '';
    final offer = item['offer_text']?.toString().trim() ?? '';
    final isOpen = item['is_open'] == 1 || item['is_open'] == true;
    final isOpenAllDay =
        item['is_open_24h'] == 1 || item['is_open_24h'] == true;

    return {
      'id': '${item['pharmacy_id'] ?? item['id'] ?? item['store_id'] ?? ''}',
      'title': name.isEmpty ? 'Pharmacy' : name,
      'subtitle': item['address']?.toString() ?? '',
      'rating': '${item['rating'] ?? 0}',
      'time': '${item['delivery_time_text'] ?? item['estimated_time'] ?? ''}',
      'dist': _distanceLabel(item),
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

  String _distanceLabel(Map<String, dynamic> item) {
    final distance = item['distance']?.toString().trim() ?? '';
    if (distance.isNotEmpty && distance != 'null') {
      return distance.toLowerCase().contains('km') ? distance : '$distance Km';
    }
    return _distanceText(item['distance_km']);
  }

  Future<
    ({
      List<Map<String, dynamic>> pharmacies,
      List<Map<String, dynamic>> products,
      List<Map<String, dynamic>> filters,
    })
  >
  searchPharmaciesV2({
    required double latitude,
    required double longitude,
    required String language,
    String keyword = '',
    Map<String, String> filters = const {},
    int limit = 20,
  }) async {
    String field(String key) => filters[key]?.trim() ?? '';
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.pharmacySearchV2,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'keyword': keyword.trim(),
          'limit': '$limit',
          'products_limit': '$limit',
          'sort_by': field('sort_by'),
          'rating': field('rating'),
          'offers': field('offers'),
          'open_now': field('open_now'),
          'trusted': field('trusted'),
          'under_30': field('under_30'),
          'price_range': field('price_range'),
          'category_id': field('category_id'),
          'category_ids': field('category_ids'),
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final products = data['products'];
    return (
      pharmacies: _pharmacyCards(data['pharmacies'], language),
      products: _searchProducts(
        products is List && products.isNotEmpty ? products : data['items'],
        language,
      ),
      filters: _searchFilters(asJsonMap(data['filters'])?['quick'], language),
    );
  }

  List<Map<String, dynamic>> _searchFilters(dynamic raw, String language) {
    if (raw is! List) return const [];
    final filters = <Map<String, dynamic>>[];
    for (final entry in raw) {
      final filter = asJsonMap(entry);
      if (filter == null) continue;
      final param = filter['param']?.toString().trim() ?? '';
      final value = filter['value']?.toString().trim() ?? '';
      if (param.isEmpty || value.isEmpty) continue;
      final label = _localized(filter, 'label', language);
      filters.add({
        'param': param,
        'value': value,
        'label': label.isEmpty ? param : label,
      });
    }
    return filters;
  }

  List<Map<String, dynamic>> _searchProducts(dynamic raw, String language) {
    if (raw is! List) return const [];
    final products = <Map<String, dynamic>>[];
    for (final entry in raw) {
      final item = asJsonMap(entry);
      if (item == null) continue;
      final name = _localized(item, 'name', language);
      final pharmacyName = _localized(item, 'pharmacy_name', language);
      final selling = item['selling_price'] ?? item['discount_price'];
      products.add({
        'id': '${item['menu_id'] ?? ''}',
        'productId': _productId(item),
        'pharmacyId': '${item['pharmacy_id'] ?? ''}',
        'pharmacyName': pharmacyName,
        'pharmacyImage':
            ApiConstants.mediaUrl(item['pharmacy_image']?.toString()) ?? '',
        'title': name,
        'image': ApiConstants.mediaUrl(item['image']?.toString()) ?? '',
        'tag': _itemTag(item),
        'price': _moneyText(selling ?? item['price']),
        'prescriptionRequired':
            item['prescription_required'] == 1 ||
            item['prescription_required'] == true,
      });
    }
    return products;
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
