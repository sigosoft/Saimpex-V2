import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

class GroceryHomeResult {
  final List<Map<String, dynamic>> sliders;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> topStores;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> fastDeliveryStores;
  final List<Map<String, dynamic>> frequentlyBought;
  final Map<String, dynamic> meta;

  const GroceryHomeResult({
    this.sliders = const [],
    this.categories = const [],
    this.topStores = const [],
    this.recentOrders = const [],
    this.fastDeliveryStores = const [],
    this.frequentlyBought = const [],
    this.meta = const {},
  });
}

class GroceryRepository {
  GroceryRepository(this._client) : localStore = false;

  /// The same store, item and cart calls against the local store API, which
  /// mirrors grocery's with local_store paths and a local_store_id key.
  GroceryRepository.localStore(this._client) : localStore = true;

  /// Get tag of the local store instance.
  static const localStoreTag = 'localStore';

  final DioClient _client;
  final bool localStore;

  String get _idKey => localStore ? 'local_store_id' : 'grocery_id';

  static const _localStorePaths = {
    ApiConstants.groceryDetails: ApiConstants.localStoreDetails,
    ApiConstants.groceryStoreCategories: ApiConstants.localStoreCategories,
    ApiConstants.grocerySubCategories: ApiConstants.localStoreSubCategories,
    ApiConstants.groceryItems: ApiConstants.localStoreItems,
    ApiConstants.groceryItemsSearch: ApiConstants.localStoreItemsSearch,
    ApiConstants.groceryItemsBarcodeSearch:
        ApiConstants.localStoreItemsBarcodeSearch,
    ApiConstants.groceryItemDetail: ApiConstants.localStoreItemDetail,
    ApiConstants.groceryMenuVariants: ApiConstants.localStoreMenuVariants,
    ApiConstants.cartGroceryAdd: ApiConstants.cartLocalStoreAdd,
    ApiConstants.cartGroceryRemove: ApiConstants.cartLocalStoreRemove,
    ApiConstants.groceryOrders: ApiConstants.localStoreOrders,
  };

  String _path(String groceryPath) =>
      localStore ? (_localStorePaths[groceryPath] ?? groceryPath) : groceryPath;

  /// Local stores near a point, shaped like the grocery store cards.
  Future<List<Map<String, dynamic>>> fetchLocalStores({
    required double latitude,
    required double longitude,
    required String language,
    int limit = 30,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.localStoreHome,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'limit': limit,
        },
      );
      final envelope = ApiEnvelope.parse(
        response.data,
        language,
        statusCode: response.statusCode,
      );
      final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
      final rows = data['stores'] is List && (data['stores'] as List).isNotEmpty
          ? data['stores'] as List
          : (data['nearby_stores'] is List ? data['nearby_stores'] as List : []);
      return rows
          .map((entry) => asJsonMap(entry))
          .whereType<Map<String, dynamic>>()
          .map((raw) => {..._parseStore(raw, language), 'isLocalStore': true})
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }

  Future<GroceryHomeResult> fetchGroceryHomeV2({
    required double latitude,
    required double longitude,
    required String language,
    int? categoryId,
    List<int>? categoryIds,
    String? keyword,
    String? sortBy,
    String? rating,
    String? offers,
    String? priceRange,
    String? tags,
    int limit = 20,
    int fastLimit = 20,
    String city = '',
  }) async {
    final payload = <String, dynamic>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'limit': limit.toString(),
      'fast_limit': fastLimit.toString(),
      'city': city,
      'keyword': keyword ?? '',
      'sort_by': sortBy ?? '',
      'rating': rating ?? '',
      'offers': offers ?? '',
      'price_range': priceRange ?? '',
      'category_id': (categoryId != null && categoryId != 0)
          ? categoryId.toString()
          : '',
      'category_ids': (categoryIds != null && categoryIds.isNotEmpty)
          ? categoryIds.join(',')
          : '',
      'tags': tags ?? '',
    };

    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.groceryHomeV2,
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );

    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return _parseGroceryHome(data, language);
  }

  Future<List<Map<String, dynamic>>> fetchGroceryCategories({
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    try {
      final envelope = await _send(
        () => _client.dio.post(
          ApiConstants.groceryVendorCategories,
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
      final list = _parseCategories(
        data['categories'] ?? data['vendor_categories'],
        language,
      );
      if (list.isNotEmpty) return list;
    } catch (_) {}

    try {
      final envelope = await _send(
        () => _client.dio.post(
          ApiConstants.groceryHomeCategories,
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
      return _parseCategories(data['categories'], language);
    } catch (_) {
      return const [];
    }
  }

  GroceryHomeResult _parseGroceryHome(
    Map<String, dynamic> data,
    String language,
  ) {
    final slidersRaw = data['sliders'];
    final sliders = <Map<String, dynamic>>[];
    if (slidersRaw is List) {
      for (final s in slidersRaw) {
        final m = asJsonMap(s);
        if (m == null) continue;
        sliders.add({
          'id': _asInt(m['id']),
          'image': ApiConstants.mediaUrl(m['image']?.toString()) ?? '',
          'type': _asInt(m['type']),
          'status': _asInt(m['status']),
        });
      }
    }

    final categoriesRaw =
        data['categories'] ??
        data['subcategories'] ??
        data['grocery_categories'] ??
        data['vendor_categories'];
    final categories = _parseCategories(categoriesRaw, language);

    final topStoresRaw =
        data['top_stores'] ??
        data['top_grocery_stores'] ??
        data['top_grocery'] ??
        data['stores'] ??
        data['grocery_stores'] ??
        data['vendors'];
    final topStores = _parseStoreList(topStoresRaw, language);

    final recentOrdersRaw = data['recent_orders'] ?? data['orders'];
    final recentOrders = _parseOrderList(recentOrdersRaw, language);

    final fastStoresRaw =
        data['fast_delivery_stores'] ??
        data['fast_delivery'] ??
        data['under_15_minutes'] ??
        data['fast_stores'] ??
        data['fast_stores_list'];
    final fastStores = _parseStoreList(fastStoresRaw, language);

    final frequentlyRaw =
        data['frequently_bought'] ??
        data['frequently_bought_products'] ??
        data['popular_products'] ??
        data['products'];
    final frequentlyBought = _parseProductList(frequentlyRaw, language);

    final meta = asJsonMap(data['meta']) ?? <String, dynamic>{};

    return GroceryHomeResult(
      sliders: sliders,
      categories: categories,
      topStores: topStores,
      recentOrders: recentOrders,
      fastDeliveryStores: fastStores,
      frequentlyBought: frequentlyBought,
      meta: meta,
    );
  }

  List<Map<String, dynamic>> _parseCategories(dynamic raw, String language) {
    if (raw is! List) return const [];
    final list = <Map<String, dynamic>>[];
    for (final item in raw) {
      final m = asJsonMap(item);
      if (m == null) continue;
      final id = _asInt(m['id'] ?? m['category_id'] ?? m['sub_category_id']);
      final name = _localized(m, 'name', language);
      final label = name.isNotEmpty
          ? name
          : (m['label']?.toString() ?? (id == 0 ? 'All' : 'Category'));
      list.add({
        'id': id,
        'category_id': m['category_id'] ?? (id != 0 ? id : null),
        'sub_category_id':
            m['sub_category_id'] ?? m['subcategory_id'] ?? m['sub_cat_id'],
        'label': label,
        'isAll': id == 0 || m['isAll'] == true,
        'image': ApiConstants.mediaUrl(
          m['image']?.toString() ?? m['icon']?.toString(),
        ),
        'raw': m,
      });
    }
    return list;
  }

  List<Map<String, dynamic>> _parseStoreList(dynamic raw, String language) {
    if (raw is! List) return const [];
    final list = <Map<String, dynamic>>[];
    for (final item in raw) {
      final m = asJsonMap(item);
      if (m == null) continue;
      list.add(_parseStore(m, language));
    }
    return list;
  }

  Map<String, dynamic> _parseStore(Map<String, dynamic> raw, String language) {
    final title = _localized(raw, 'name', language);
    var category = _localized(raw, 'category_label', language);
    if (category.isEmpty) {
      category = _localized(raw, 'cuisine_label', language);
    }
    if (category.isEmpty) {
      category =
          raw['category']?.toString() ?? raw['address']?.toString() ?? '';
    }

    final time = raw['delivery_time_text']?.toString().trim().isNotEmpty == true
        ? raw['delivery_time_text'].toString().trim()
        : (raw['delivery_time_min'] != null
              ? '${raw['delivery_time_min']} min'
              : (raw['avg_preparation_minutes'] != null
                    ? '${raw['avg_preparation_minutes']} min'
                    : '30-35 min'));

    final dist = raw['distance']?.toString().trim().isNotEmpty == true
        ? raw['distance'].toString().trim()
        : '${raw['distance_km'] ?? 0} Km';

    final discount = raw['offer_text']?.toString().trim().isNotEmpty == true
        ? raw['offer_text'].toString().trim()
        : (raw['offer_percentage'] != null &&
                  _asInt(raw['offer_percentage']) > 0
              ? '${raw['offer_percentage']}% OFF'
              : (raw['max_offer_percentage'] != null &&
                        _asInt(raw['max_offer_percentage']) > 0
                    ? '${raw['max_offer_percentage']}% OFF'
                    : ''));

    final points = raw['points_text']?.toString().trim().isNotEmpty == true
        ? raw['points_text'].toString().trim()
        : (raw['user_points_available'] != null &&
                  _asInt(raw['user_points_available']) > 0
              ? '${raw['user_points_available']} Points Available'
              : '200 Points Available');

    final isOpen = _asInt(raw['is_open'], fallback: 1);
    final openStatus = raw['open_status']?.toString().toUpperCase() ?? '';
    final isClosed = isOpen == 0 || openStatus == 'CLOSED';
    final isTemporarilyClosed =
        openStatus == 'BUSY' || openStatus == 'TEMPORARILY_CLOSED';

    return {
      'id':
          (raw['grocery_id'] ??
                  raw['id'] ??
                  raw['vendor_id'] ??
                  raw['store_id'] ??
                  '')
              .toString(),
      'grocery_id': _asInt(raw['grocery_id'] ?? raw['local_store_id'] ?? raw['id'] ?? raw['vendor_id']),
      'name': title.isEmpty ? 'Store' : title,
      'title': title.isEmpty ? 'Store' : title,
      'category': category.isEmpty ? 'Hypermarket' : category,
      'rating': (raw['rating'] ?? '4.5').toString(),
      'time': time,
      'dist': dist,
      'discount': discount,
      'points': points,
      'isClosed': isClosed,
      'isTemporarilyClosed': isTemporarilyClosed,
      'image': ApiConstants.mediaUrl(raw['image']?.toString()) ?? '',
      'raw': raw,
    };
  }

  List<Map<String, dynamic>> _parseOrderList(dynamic raw, String language) {
    if (raw is! List) return const [];
    final list = <Map<String, dynamic>>[];
    for (final item in raw) {
      final m = asJsonMap(item);
      if (m == null) continue;
      final name = _localized(m, 'name', language);
      list.add({
        'id': (m['id'] ?? '').toString(),
        'name': name.isNotEmpty
            ? name
            : (m['vendor_name'] ?? m['title'] ?? 'Store').toString(),
        'rating': (m['rating'] ?? '4.5').toString(),
        'items': (m['items'] ?? m['item_name'] ?? m['menu_name'] ?? '')
            .toString(),
        'date': (m['date'] ?? m['ordered_at'] ?? 'Recently').toString(),
        'count': m['items_count'] != null
            ? '${m['items_count']} Items'
            : (m['count'] ?? '1 Item').toString(),
        'image': ApiConstants.mediaUrl(m['image']?.toString()) ?? '',
        'raw': m,
      });
    }
    return list;
  }

  List<Map<String, dynamic>> _parseProductList(dynamic raw, String language) {
    if (raw is! List) return const [];
    final list = <Map<String, dynamic>>[];
    for (final item in raw) {
      final m = asJsonMap(item);
      if (m == null) continue;
      final name = _localized(m, 'name', language);
      final storeName = _localized(m, 'store_name', language);
      final price =
          m['price_text']?.toString() ??
          (m['price'] != null ? '${m['price']} MRU' : '');
      list.add({
        'id': (m['id'] ?? m['product_id'] ?? '').toString(),
        'name': name.isNotEmpty ? name : (m['title'] ?? 'Product').toString(),
        'store': storeName.isNotEmpty
            ? storeName
            : (m['store'] ?? m['vendor_name'] ?? 'Supermarket').toString(),
        'rating': (m['rating'] ?? '4.5').toString(),
        'price': price.isNotEmpty ? price : '— MRU',
        'image': ApiConstants.mediaUrl(m['image']?.toString()) ?? '',
        'raw': m,
      });
    }
    return list;
  }

  Future<Map<String, dynamic>> fetchGroceryDetails({
    required int groceryId,
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        _path(ApiConstants.groceryDetails),
        queryParameters: {
          _idKey: groceryId.toString(),
          'lat': latitude.toString(),
          'long': longitude.toString(),
        },
      ),
      language,
    );

    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return _parseGroceryDetails(data, language);
  }

  /// Categories the store sells in (grocery/categories).
  Future<List<Map<String, dynamic>>> fetchGroceryStoreCategories({
    required int groceryId,
    String keyword = '',
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        _path(ApiConstants.groceryStoreCategories),
        queryParameters: {_idKey: '$groceryId', 'keyword': keyword},
      ),
      language,
    );
    return _parseCategories(envelope.data, language);
  }

  /// Subcategories of one store category (grocery/subCategories).
  Future<List<Map<String, dynamic>>> fetchGrocerySubCategories({
    required int groceryId,
    required int categoryId,
    String keyword = '',
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        _path(ApiConstants.grocerySubCategories),
        queryParameters: {
          _idKey: '$groceryId',
          'category_id': '$categoryId',
          'keyword': keyword,
        },
      ),
      language,
    );
    return _parseCategories(envelope.data, language);
  }

  /// Stores matching the keyword, quick filters and category (grocerySearchV2).
  Future<
    ({List<Map<String, dynamic>> stores, List<Map<String, dynamic>> filters})
  >
  searchGroceryStores({
    required double latitude,
    required double longitude,
    required String language,
    String keyword = '',
    Map<String, String> filters = const {},
    int? categoryId,
    int limit = 20,
  }) async {
    String field(String key) => filters[key]?.trim() ?? '';
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.grocerySearchV2,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'keyword': keyword.trim(),
          'limit': '$limit',
          'page': '1',
          'sort_by': field('sort_by'),
          'rating': field('rating'),
          'offers': field('offers'),
          'under_200': field('under_200'),
          'under_15': field('under_15'),
          'open_now': field('open_now'),
          'price_range': field('price_range'),
          'tags': field('tags'),
          'category_id': (categoryId != null && categoryId > 0)
              ? '$categoryId'
              : '',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );

    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final storesRaw = data['stores'] is List
        ? data['stores']
        : asJsonMap(data['groceries'])?['data'];
    return (
      stores: _parseStoreList(storesRaw, language),
      filters: _searchFilters(asJsonMap(data['filters'])?['quick'], language),
    );
  }

  /// Store items. Category alone uses items/search; category plus subcategory
  /// uses grocery/items, which needs both ids.
  Future<List<Map<String, dynamic>>> fetchGroceryItems({
    required int groceryId,
    int? categoryId,
    int? subCategoryId,
    String keyword = '',
    int limit = 20,
    String sortBy = 'relevance',
    String? priceRange,
    double? rating,
    List<int> tagIds = const [],
    required String language,
  }) async {
    final hasCategory = (categoryId ?? 0) > 0;
    final hasSubCategory = hasCategory && (subCategoryId ?? 0) > 0;

    final envelope = await _send(
      () => _client.dio.post(
        hasSubCategory
            ? _path(ApiConstants.groceryItems)
            : _path(ApiConstants.groceryItemsSearch),
        data: {
          _idKey: '$groceryId',
          'category_id': hasCategory ? '$categoryId' : '',
          'sub_category_id': hasSubCategory ? '$subCategoryId' : '',
          'keyword': keyword.trim(),
          'limit': '$limit',
          'sort_by': sortBy,
          'price_range': ?priceRange,
          if (rating != null) 'rating': '$rating',
          if (tagIds.isNotEmpty) 'tags': tagIds.map((id) => '$id').toList(),
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return _parseMenuRows(envelope.data, language);
  }

  /// Store items matched by barcode/search. Category ids go as arrays.
  Future<List<Map<String, dynamic>>> searchGroceryItemsByBarcode({
    required int groceryId,
    required List<int> categoryIds,
    List<int> subCategoryIds = const [],
    String keyword = '',
    int limit = 20,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        _path(ApiConstants.groceryItemsBarcodeSearch),
        data: {
          _idKey: '$groceryId',
          'category_id': categoryIds.map((id) => '$id').toList(),
          'sub_category_id': subCategoryIds.map((id) => '$id').toList(),
          'keyword': keyword.trim(),
          'limit': '$limit',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return _parseMenuRows(envelope.data, language);
  }

  /// Product lookup by barcode (groceryBarcodeSearch). No screen uses it yet.
  Future<List<Map<String, dynamic>>> searchGroceryByBarcode({
    required String barcode,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.groceryBarcodeSearch,
        data: {'barcode': barcode.trim()},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return _parseMenuRows(envelope.data, language);
  }

  /// One item's description, tags and variants (grocery/item/detail).
  Future<Map<String, dynamic>> fetchGroceryItemDetail({
    required int menuId,
    required int groceryId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        _path(ApiConstants.groceryItemDetail),
        queryParameters: {'menu_id': '$menuId', _idKey: '$groceryId'},
      ),
      language,
    );

    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final menu = asJsonMap(data['menu']) ?? <String, dynamic>{};
    return {
      'menuId': _asInt(menu['menu_id'] ?? menuId),
      'title': _localized(menu, 'name', language),
      'description': _localized(menu, 'description', language),
      'image': ApiConstants.mediaUrl(menu['image']?.toString()) ?? '',
      'tags': _tagNames(menu['tags'], language),
      'variants': _parseVariants(data['variants'], language),
    };
  }

  /// Variants with price and stock for one item (grocery/getMenuItemVariants).
  /// Read raw: this endpoint returns variants at the top level, not under `data`.
  Future<List<Map<String, dynamic>>> fetchGroceryMenuVariants({
    required int menuId,
    required int groceryId,
    required String language,
  }) async {
    try {
      final response = await _client.dio.get(
        _path(ApiConstants.groceryMenuVariants),
        queryParameters: {'menu_id': '$menuId', _idKey: '$groceryId'},
      );
      final body = asJsonMap(response.data) ?? <String, dynamic>{};
      return _parseVariants(body['variants'], language);
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }

  /// Tags on one item (getGroceryMenuTags). Read raw: status comes back as a string.
  Future<List<String>> fetchGroceryMenuTags({
    required int menuId,
    required String language,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.groceryMenuTags,
        queryParameters: {'menu_id': '$menuId'},
      );
      return _tagNames(asJsonMap(response.data)?['data'], language);
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }

  /// All grocery tags (getGroceryTags). Read raw: status comes back as a string.
  Future<List<String>> fetchGroceryTags({required String language}) async {
    try {
      final response = await _client.dio.get(ApiConstants.groceryTags);
      return _tagNames(asJsonMap(response.data)?['data'], language);
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }

  /// Grocery tags with their ids, for the filter sheet (getGroceryTags).
  Future<List<({int id, String label})>> fetchGroceryTagChoices({
    required String language,
  }) async {
    try {
      final response = await _client.dio.get(ApiConstants.groceryTags);
      final raw = asJsonMap(response.data)?['data'];
      final rows = raw is List
          ? raw.map(asJsonMap).whereType<Map<String, dynamic>>()
          : const <Map<String, dynamic>>[];
      return [
        for (final tag in rows)
          if (_asInt(tag['id']) > 0 &&
              _localized(tag, 'name', language).isNotEmpty)
            (id: _asInt(tag['id']), label: _localized(tag, 'name', language)),
      ];
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }

  /// Adds one variant to the server grocery cart (cart/grocery/add).
  Future<String> addGroceryCartItem({
    required int groceryId,
    required int productId,
    int? attributeId,
    required double unitPrice,
    required String language,
    int quantity = 1,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        _path(ApiConstants.cartGroceryAdd),
        data: {
          _idKey: '$groceryId',
          'product_id': '$productId',
          'quantity': '$quantity',
          'unit_price': unitPrice.toString(),
          if (attributeId != null) 'grocery_attribute_id': '$attributeId',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  /// Removes one variant from the server grocery cart (cart/grocery/remove).
  Future<String> removeGroceryCartItem({
    required int groceryId,
    required int productId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        _path(ApiConstants.cartGroceryRemove),
        data: {_idKey: '$groceryId', 'product_id': '$productId'},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  /// Grocery orders for My Orders, mapped to the same keys as the restaurant card.
  Future<({List<Map<String, dynamic>> orders, int currentPage, int lastPage})>
  fetchGroceryOrders({required String language, int page = 1}) async {
    final envelope = await _send(
      () => _client.dio.get(
        _path(ApiConstants.groceryOrders),
        queryParameters: {'limit': 20, 'page': page},
      ),
      language,
    );
    // envelope.data is already the paginator (current_page, data, last_page).
    final paged = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final raw = paged['data'];
    final orders = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final entry in raw) {
        final item = asJsonMap(entry);
        if (item != null) orders.add(_groceryOrderCard(item));
      }
    }
    return (
      orders: orders,
      currentPage: _asInt(paged['current_page'], fallback: page),
      lastPage: _asInt(paged['last_page'], fallback: page),
    );
  }

  Map<String, dynamic> _groceryOrderCard(Map<String, dynamic> item) {
    final name = [item['vendor_name'], item['grocery_name'], item['name']]
        .map((v) => v?.toString().trim() ?? '')
        .firstWhere(
          (v) => v.isNotEmpty && v != 'null',
          orElse: () => 'Grocery',
        );
    final statusText = (item['status_text'] ?? item['status'] ?? '')
        .toString()
        .trim();
    final lower = statusText.toLowerCase();
    final code = item['order_code']?.toString().trim() ?? '';
    final orderId = code.isNotEmpty
        ? code
        : (item['order_id'] == null ? '' : '#${item['order_id']}');
    final total = item['item_total'] ?? item['total'];
    final products = item['products'] is List
        ? (item['products'] as List)
              .map(asJsonMap)
              .whereType<Map<String, dynamic>>()
              .map(_groceryProductLine)
              .toList()
        : <Map<String, dynamic>>[];
    return {
      'channel': 'grocery',
      'restaurantName': name,
      'vendorImage': ApiConstants.mediaUrl(item['vendor_image']?.toString()),
      'statusText': statusText.isEmpty ? 'Order' : statusText,
      'isCancelled': lower.contains('cancel'),
      'isDelivered': lower.contains('deliver'),
      'isSelfPickup':
          item['is_self_pickup'] == 1 || item['is_self_pickup'] == true,
      'orderId': orderId,
      'numericOrderId': _asInt(item['order_id'] ?? item['id']),
      'totalText': total == null ? '' : '$total MRU',
      'itemsCount': item['items_count'] != null
          ? _asInt(item['items_count'])
          : products.length,
      'orderedAt': item['ordered_at']?.toString() ?? '',
      'products': products,
    };
  }

  /// One product line of a grocery order: name, quantity, and selling price.
  Map<String, dynamic> _groceryProductLine(Map<String, dynamic> product) {
    final quantity = _asInt(product['quantity'], fallback: 1);
    final discount = _amount(product['discount_price']);
    final price = _amount(product['price']);
    final selling = discount > 0 ? discount : price;
    return {
      'name': product['name']?.toString().trim() ?? '',
      'image': ApiConstants.mediaUrl(product['image']?.toString()) ?? '',
      'quantity': quantity,
      'unitText': '${selling.round()} MRU',
      'lineText': '${(selling * quantity).round()} MRU',
      'originalText': discount > 0 && price > discount
          ? '${price.round()} MRU'
          : '',
    };
  }

  Map<String, dynamic> _parseGroceryDetails(
    Map<String, dynamic> data,
    String language,
  ) {
    final store = _parseStore(data, language);
    return {
      ...store,
      'grocery_id': _asInt(
        data['grocery_id'] ?? data['local_store_id'] ?? data['id'] ?? data['vendor_id'],
      ),
      'address': data['address']?.toString() ?? '',
      'rating_count': _asInt(data['rating_count']),
      'delivery_radius_km': data['delivery_radius_km'],
      'raw': data,
    };
  }

  List<Map<String, dynamic>> _parseDetailsMenuItems(
    dynamic raw,
    String language,
  ) {
    if (raw is! List) return const [];
    final list = <Map<String, dynamic>>[];
    for (final item in raw) {
      final m = asJsonMap(item);
      if (m == null) continue;
      final title = _localized(m, 'name', language).isNotEmpty
          ? _localized(m, 'name', language)
          : (m['title'] ?? 'Product').toString();

      final img = ApiConstants.mediaUrl(m['image']?.toString()) ?? '';
      final images = <String>[];
      if (img.isNotEmpty) images.add(img);
      if (m['images'] is List) {
        for (final im in m['images']) {
          final u = ApiConstants.mediaUrl(im?.toString());
          if (u != null && !images.contains(u)) images.add(u);
        }
      }

      final variants = _parseVariants(m['items'] ?? m['variants'], language);

      // The row price is the base price; a discount below it is what the customer pays.
      final price = _amount(m['price']);
      final discount = _amount(m['discount_price']);
      final selling = discount > 0 && discount < price ? discount : price;
      final offer = _asInt(m['offer_percentage']);

      final hasStock = m['has_stock'];
      final inStock = hasStock == null
          ? variants.any((v) => v['inStock'] == true)
          : (hasStock == true || hasStock == 1);

      final tag = _firstTagName(m['tags'], language);
      final category = _localized(m, 'category_name', language);

      final ratingValue = _amount(m['rating']);
      final reviewCount = _asInt(m['rating_count']);

      list.add({
        'id': (m['menu_id'] ?? m['id'] ?? m['product_id'] ?? '').toString(),
        'menuId': _asInt(m['menu_id'] ?? m['id']),
        'title': title,
        'image': img,
        'images': images,
        'isVeg': m['is_veg'] == 1 || m['is_veg'] == true || m['isVeg'] == true,
        'tag': tag.isNotEmpty
            ? tag
            : (category.isNotEmpty ? category : 'Grocery'),
        'rating': ratingValue.toStringAsFixed(1),
        'reviews': '$reviewCount reviews',
        'price': _moneyText(selling),
        'sellingPrice': selling,
        'originalPrice': price > selling ? _moneyText(price) : '',
        'discount': offer > 0 ? '$offer% OFF' : '',
        'inStock': inStock,
        'variants': variants,
        'raw': m,
      });
    }
    return list;
  }

  /// Rows from items/search, grocery/items, or barcode/search (all use menus.data).
  List<Map<String, dynamic>> _parseMenuRows(dynamic raw, String language) {
    if (raw is! Map) return _parseDetailsMenuItems(raw, language);
    final menus = raw['menus'];
    final rows = menus is Map ? menus['data'] : menus;
    return _parseDetailsMenuItems(
      rows ?? raw['items'] ?? raw['data'],
      language,
    );
  }

  /// Sellable variants. [label] is the attribute name, then the variant name.
  List<Map<String, dynamic>> _parseVariants(dynamic raw, String language) {
    if (raw is! List) return const [];
    final list = <Map<String, dynamic>>[];
    for (final item in raw) {
      final m = asJsonMap(item);
      if (m == null) continue;
      final price = _amount(m['price']);
      final discount = _amount(m['discount_price']);
      final selling = discount > 0 && discount < price ? discount : price;
      final stock = _asInt(m['stock']);

      var label = _localized(m, 'attribute_name', language);
      if (label.isEmpty) label = _localized(m, 'variant_name', language);
      if (label.isEmpty) label = m['attribute_value']?.toString() ?? '';

      list.add({
        'productId': _asInt(m['product_id'] ?? m['item_id']),
        'attributeId': (m['grocery_attribute_id'] ?? m['local_store_attribute_id']) == null
            ? null
            : _asInt(m['grocery_attribute_id'] ?? m['local_store_attribute_id']),
        'label': label,
        'price': _moneyText(selling),
        'sellingPrice': selling,
        'originalPrice': price > selling ? _moneyText(price) : '',
        'stock': stock,
        'inStock': stock > 0,
        'raw': m,
      });
    }
    return list;
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

  List<String> _tagNames(dynamic raw, String language) {
    if (raw is! List) return const [];
    return raw
        .map((tag) => asJsonMap(tag))
        .whereType<Map<String, dynamic>>()
        .map((tag) => _localized(tag, 'name', language))
        .where((name) => name.isNotEmpty)
        .toList();
  }

  String _firstTagName(dynamic raw, String language) {
    final names = _tagNames(raw, language);
    return names.isEmpty ? '' : names.first;
  }

  double _amount(dynamic value) => double.tryParse('${value ?? ''}') ?? 0;

  /// "20.00" becomes "20 MRU"; a missing or zero price shows "— MRU".
  String _moneyText(double value) {
    if (value <= 0) return '— MRU';
    return value == value.roundToDouble()
        ? '${value.toInt()} MRU'
        : '${value.toStringAsFixed(2)} MRU';
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
  }

  String _localized(Map<String, dynamic> item, String key, String language) {
    for (final code in [language, 'en', 'fr', 'ar']) {
      final value = item['${key}_$code']?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    final plain = item[key]?.toString().trim() ?? '';
    if (plain.isEmpty || plain.toLowerCase() == 'null') return '';
    return plain;
  }

  Future<ApiEnvelope> _send(
    Future<Response<dynamic>> Function() call,
    String language,
  ) async {
    try {
      final response = await call();
      return ApiEnvelope.parse(
        response.data,
        language,
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }
}
