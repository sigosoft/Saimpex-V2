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
  GroceryRepository(this._client);

  final DioClient _client;

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
      'category_id':
          (categoryId != null && categoryId != 0) ? categoryId.toString() : '',
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

    final categoriesRaw = data['categories'] ??
        data['subcategories'] ??
        data['grocery_categories'] ??
        data['vendor_categories'];
    final categories = _parseCategories(categoriesRaw, language);

    final topStoresRaw = data['top_stores'] ??
        data['top_grocery_stores'] ??
        data['top_grocery'] ??
        data['stores'] ??
        data['grocery_stores'] ??
        data['vendors'];
    final topStores = _parseStoreList(topStoresRaw, language);

    final recentOrdersRaw = data['recent_orders'] ?? data['orders'];
    final recentOrders = _parseOrderList(recentOrdersRaw, language);

    final fastStoresRaw = data['fast_delivery_stores'] ??
        data['fast_delivery'] ??
        data['under_15_minutes'] ??
        data['fast_stores'] ??
        data['fast_stores_list'];
    final fastStores = _parseStoreList(fastStoresRaw, language);

    final frequentlyRaw = data['frequently_bought'] ??
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
      final id = _asInt(m['id'] ?? m['category_id']);
      final name = _localized(m, 'name', language);
      final label = name.isNotEmpty
          ? name
          : (m['label']?.toString() ?? (id == 0 ? 'All' : 'Category'));
      list.add({
        'id': id,
        'category_id': m['category_id'] ?? (id != 0 ? id : null),
        'sub_category_id': m['sub_category_id'] ??
            m['subcategory_id'] ??
            m['sub_cat_id'],
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
      category = raw['category']?.toString() ?? raw['address']?.toString() ?? '';
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
        : (raw['offer_percentage'] != null && _asInt(raw['offer_percentage']) > 0
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
      'id': (raw['id'] ?? raw['vendor_id'] ?? raw['store_id'] ?? '').toString(),
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
        'items': (m['items'] ?? m['item_name'] ?? m['menu_name'] ?? '').toString(),
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
      final price = m['price_text']?.toString() ??
          (m['price'] != null ? '${m['price']} MRU' : '');
      list.add({
        'id': (m['id'] ?? m['product_id'] ?? '').toString(),
        'name': name.isNotEmpty ? name : (m['title'] ?? 'Product').toString(),
        'store': storeName.isNotEmpty
            ? storeName
            : (m['store'] ?? m['vendor_name'] ?? 'Supermarket').toString(),
        'rating': (m['rating'] ?? '4.5').toString(),
        'price': price.isNotEmpty ? price : '0 MRU',
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
        ApiConstants.groceryDetails,
        queryParameters: {
          'grocery_id': groceryId.toString(),
          'lat': latitude.toString(),
          'long': longitude.toString(),
        },
      ),
      language,
    );

    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return _parseGroceryDetails(data, language);
  }

  Future<List<Map<String, dynamic>>> fetchGroceryItems({
    required int groceryId,
    dynamic categoryId,
    dynamic subCategoryId,
    int limit = 20,
    required String language,
  }) async {
    final payload = <String, dynamic>{
      'grocery_id': groceryId.toString(),
      'category_id': (categoryId != null && categoryId.toString().isNotEmpty)
          ? categoryId.toString()
          : '',
      'sub_category_id':
          (subCategoryId != null && subCategoryId.toString().isNotEmpty)
              ? subCategoryId.toString()
              : '',
      'limit': limit.toString(),
    };

    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.groceryItems,
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );

    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    dynamic itemsRaw;
    if (data['menus'] is Map && data['menus']['data'] is List) {
      itemsRaw = data['menus']['data'];
    } else if (data['menus'] is List) {
      itemsRaw = data['menus'];
    } else if (data['items'] is List) {
      itemsRaw = data['items'];
    } else if (data['data'] is List) {
      itemsRaw = data['data'];
    } else if (data['products'] is List) {
      itemsRaw = data['products'];
    } else if (envelope.data is List) {
      itemsRaw = envelope.data;
    }

    return _parseDetailsMenuItems(itemsRaw, language);
  }

  Map<String, dynamic> _parseGroceryDetails(
    Map<String, dynamic> data,
    String language,
  ) {
    final name = _localized(data, 'name', language);
    var category = _localized(data, 'category_label', language);
    if (category.isEmpty) {
      category = _localized(data, 'category', language);
    }
    if (category.isEmpty) {
      category = _localized(data, 'cuisine_label', language);
    }
    if (category.isEmpty) {
      category = data['address']?.toString() ?? 'Grocery';
    }

    final prepTime = _asInt(
      data['preparation_time'] ?? data['avg_preparation_minutes'],
    );
    final time = data['delivery_time_text']?.toString().trim().isNotEmpty == true
        ? data['delivery_time_text'].toString().trim()
        : (prepTime > 0
            ? '$prepTime min'
            : (data['delivery_time_min'] != null
                ? '${data['delivery_time_min']} min'
                : '30-35 min'));

    final dist = data['distance']?.toString().trim().isNotEmpty == true
        ? data['distance'].toString().trim()
        : (data['distance_km'] != null ? '${data['distance_km']} Km' : '10 Km');

    final offerPerc = _asInt(
      data['offer_percentage'] ?? data['max_offer_percentage'],
    );
    final discount = data['offer_text']?.toString().trim().isNotEmpty == true
        ? data['offer_text'].toString().trim()
        : (offerPerc > 0 ? '$offerPerc% OFF' : '');

    final points = data['points_text']?.toString().trim().isNotEmpty == true
        ? data['points_text'].toString().trim()
        : (data['user_points_available'] != null
            ? '${data['user_points_available']} Points Available'
            : '200 Points Available');

    final isOpen = _asInt(data['is_open'], fallback: 1);
    final openStatus = data['open_status']?.toString().toUpperCase() ?? '';
    final isClosed = isOpen == 0 || openStatus == 'CLOSED';
    final isTemporarilyClosed =
        openStatus == 'BUSY' || openStatus == 'TEMPORARILY_CLOSED';

    final image = ApiConstants.mediaUrl(
          data['image']?.toString() ??
              data['banner']?.toString() ??
              data['logo']?.toString() ??
              data['cover_image']?.toString(),
        ) ??
        '';

    final categoriesRaw = data['categories'] ??
        data['subcategories'] ??
        data['vendor_categories'] ??
        data['grocery_categories'];
    final categories = _parseCategories(categoriesRaw, language);

    final itemsRaw = data['items'] ??
        data['products'] ??
        data['menu_items'] ??
        data['menu'] ??
        data['grocery_items'];
    final menuItems = _parseDetailsMenuItems(itemsRaw, language);

    final smartBundleRaw = data['smart_bundle'] ??
        data['bundle'] ??
        data['special_bundle'] ??
        data['smart_bundles'];
    final smartBundle = _parseSmartBundle(smartBundleRaw, language);

    return {
      'grocery_id':
          _asInt(data['grocery_id'] ?? data['id'] ?? data['vendor_id']),
      'id': (data['grocery_id'] ?? data['id'] ?? data['vendor_id'] ?? '')
          .toString(),
      'name': name.isEmpty ? 'Store' : name,
      'title': name.isEmpty ? 'Store' : name,
      'address': data['address']?.toString() ?? '',
      'rating': (data['rating'] ?? '4.6').toString(),
      'rating_count': _asInt(data['rating_count']),
      'category': category.isEmpty ? 'Grocery' : category,
      'time': time,
      'dist': dist,
      'discount': discount,
      'points': points,
      'isClosed': isClosed,
      'isTemporarilyClosed': isTemporarilyClosed,
      'image': image,
      'categories': categories,
      'menuItems': menuItems,
      'smartBundle': smartBundle,
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
      if (images.isEmpty && img.isNotEmpty) images.add(img);

      final priceNum = _asInt(m['price']);
      final origPriceNum =
          _asInt(m['original_price'] ?? m['originalPrice'] ?? m['mrp']);
      final priceStr = m['price_text']?.toString() ?? '$priceNum MRU';
      final origPriceStr = origPriceNum > priceNum
          ? (m['original_price_text']?.toString() ?? '$origPriceNum MRU')
          : (priceNum > 0 ? '${priceNum * 2} MRU' : '0 MRU');

      final discount = m['discount_text']?.toString() ??
          (m['discount'] != null
              ? '${m['discount']}% OFF'
              : (origPriceNum > priceNum
                  ? '${(((origPriceNum - priceNum) / origPriceNum) * 100).round()}% OFF'
                  : '50% OFF'));

      final tag = _localized(m, 'category_name', language).isNotEmpty
          ? _localized(m, 'category_name', language)
          : (m['tag'] ?? m['category'] ?? 'Grocery').toString();

      final rating = (m['rating'] ?? '4.6').toString();
      final reviews = m['reviews_count'] != null
          ? '${m['reviews_count']} reviews'
          : (m['reviews'] ?? '10k + reviews').toString();

      list.add({
        'id': (m['id'] ?? m['product_id'] ?? '').toString(),
        'title': title,
        'image': img,
        'images': images,
        'isVeg':
            m['is_veg'] == 1 || m['is_veg'] == true || m['isVeg'] == true,
        'tag': tag,
        'rating': rating,
        'reviews': reviews,
        'price': priceStr,
        'originalPrice': origPriceStr,
        'discount': discount,
        'raw': m,
      });
    }
    return list;
  }

  Map<String, dynamic>? _parseSmartBundle(dynamic raw, String language) {
    Map<String, dynamic>? m;
    if (raw is List && raw.isNotEmpty) {
      m = asJsonMap(raw.first);
    } else if (raw is Map) {
      m = asJsonMap(raw);
    }
    if (m == null) return null;

    final title = _localized(m, 'name', language).isNotEmpty
        ? _localized(m, 'name', language)
        : (m['title'] ?? 'Special Bundle').toString();
    final itemsDesc = _localized(m, 'description', language).isNotEmpty
        ? _localized(m, 'description', language)
        : (m['items_text'] ?? m['subtitle'] ?? 'Bundle').toString();

    final price = m['price_text']?.toString() ??
        (m['price'] != null ? '${m['price']} MRU' : '750 MRU');
    final origPrice = m['original_price_text']?.toString() ??
        (m['original_price'] != null ? '${m['original_price']} MRU' : '1500 MRU');

    return {
      'title': title,
      'items': itemsDesc,
      'price': price,
      'originalPrice': origPrice,
      'raw': m,
    };
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
