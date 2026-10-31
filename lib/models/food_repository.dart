import 'package:dio/dio.dart';
import 'package:get/get.dart' show Trans;

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

class RestaurantHomeResult {
  final List<Map<String, dynamic>> sliders;
  final List<Map<String, dynamic>> under30Minutes;
  final List<Map<String, dynamic>> trending;
  final List<Map<String, dynamic>> restaurants;
  final List<Map<String, dynamic>> mapStores;
  final String trendingTitle;
  final String trendingCity;
  final Map<String, dynamic> meta;

  const RestaurantHomeResult({
    this.sliders = const [],
    this.under30Minutes = const [],
    this.trending = const [],
    this.restaurants = const [],
    this.mapStores = const [],
    this.trendingTitle = '',
    this.trendingCity = '',
    this.meta = const {},
  });
}

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

  Future<Map<String, dynamic>> fetchRestaurantDetails({
    required int restaurantId,
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.restaurantDetails,
        queryParameters: {
          'restaurant_id': restaurantId.toString(),
          'lat': latitude.toString(),
          'long': longitude.toString(),
        },
      ),
      language,
    );

    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return _parseRestaurantDetails(data, language);
  }

  Map<String, dynamic> _parseRestaurantDetails(
    Map<String, dynamic> data,
    String language,
  ) {
    final raw =
        asJsonMap(data['restaurant']) ??
        asJsonMap(data['details']) ??
        asJsonMap(data['item']) ??
        data;

    final title = _localized(raw, 'name', language);
    var subtitle = _localized(raw, 'cuisine_label', language);
    if (subtitle.isEmpty && raw['cuisine_tags'] is List) {
      final tags = (raw['cuisine_tags'] as List)
          .map((t) => _localized(asJsonMap(t) ?? {}, 'name', language))
          .where((s) => s.isNotEmpty)
          .toList();
      if (tags.isNotEmpty) {
        subtitle = tags.join(' • ');
      }
    }
    if (subtitle.isEmpty) {
      subtitle = raw['address']?.toString() ?? '';
    }

    final time = raw['delivery_time_text']?.toString().trim().isNotEmpty == true
        ? raw['delivery_time_text'].toString().trim()
        : (raw['delivery_time_min'] != null
              ? '${raw['delivery_time_min']} min'
              : (raw['avg_preparation_minutes'] != null
                    ? '${raw['avg_preparation_minutes']} min'
                    : (raw['preparation_time'] != null
                          ? '${raw['preparation_time']} min'
                          : '')));

    final dist = raw['distance']?.toString().trim().isNotEmpty == true
        ? raw['distance'].toString().trim()
        : (raw['distance_km'] != null
              ? '${_kmText(raw['distance_km'])} Km'
              : '');

    final discount = raw['offer_text']?.toString().trim().isNotEmpty == true
        ? raw['offer_text'].toString().trim()
        : (raw['offer_percentage'] != null &&
                  _asInt(raw['offer_percentage']) > 0
              ? '${raw['offer_percentage']}% OFF'
              : '');

    final points = raw['points_text']?.toString().trim().isNotEmpty == true
        ? raw['points_text'].toString().trim()
        : (raw['user_points_available'] != null &&
                  _asInt(raw['user_points_available']) > 0
              ? '${raw['user_points_available']} Points Available'
              : '');

    final rating = raw['rating'] != null ? raw['rating'].toString() : '';

    final image = ApiConstants.mediaUrl(
      raw['image']?.toString() ?? raw['banner_image']?.toString(),
    );

    return {
      'id': (raw['id'] ?? raw['restaurant_id'] ?? '').toString(),
      'restaurant_id': _asInt(raw['restaurant_id'] ?? raw['id']),
      'title': title,
      'name': title,
      'subtitle': subtitle,
      'address': raw['address']?.toString() ?? '',
      'image': image ?? '',
      'rating': rating,
      'rating_count': _asInt(raw['rating_count']),
      'time': time,
      'dist': dist,
      'discount': discount,
      'points': points,
      'latitude': raw['latitude']?.toString() ?? '',
      'longitude': raw['longitude']?.toString() ?? '',
      'delivery_radius_km': raw['delivery_radius_km'],
      'raw': raw,
    };
  }

  Future<List<Map<String, dynamic>>> fetchRestaurantItems({
    required int restaurantId,
    dynamic categoryId,
    int? limit,
    int? page,
    required String language,
  }) async {
    // The API requires a real category_id (0 / "All" is rejected) and pages
    // results 20 at a time, so walk every page unless a page was requested.
    final payload = <String, dynamic>{
      'restaurant_id': restaurantId.toString(),
      if (categoryId != null &&
          categoryId.toString().isNotEmpty &&
          categoryId.toString() != '0')
        'category_id': categoryId.toString(),
      if (limit != null && limit > 0) 'limit': limit.toString(),
    };

    final items = <Map<String, dynamic>>[];
    var currentPage = page != null && page > 0 ? page : 1;
    while (true) {
      payload['page'] = currentPage.toString();
      final envelope = await _send(
        () => _client.dio.post(
          ApiConstants.restaurantItems,
          data: payload,
          options: Options(contentType: Headers.jsonContentType),
        ),
        language,
      );

      final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
      final pageRaw = _restaurantItemsList(data, envelope.data);
      final pageItems = _parseRestaurantItems(pageRaw, language);
      items.addAll(pageItems);

      final paginator = data['data'] is Map ? asJsonMap(data['data']) : null;
      final lastPage = _asInt(paginator?['last_page'], fallback: currentPage);
      if (page != null ||
          pageItems.isEmpty ||
          currentPage >= lastPage ||
          currentPage >= 50) {
        break;
      }
      currentPage++;
    }
    return items;
  }

  Future<({List<Map<String, dynamic>> orders, int currentPage, int lastPage})>
  fetchRestaurantOrders({required String language, int page = 1}) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.restaurantOrders,
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
        if (item != null) orders.add(_restaurantOrderCard(item));
      }
    }
    return (
      orders: orders,
      currentPage: _asInt(paged['current_page'], fallback: page),
      lastPage: _asInt(paged['last_page'], fallback: page),
    );
  }

  Map<String, dynamic> _restaurantOrderCard(Map<String, dynamic> item) {
    final name = [item['restaurant_name'], item['vendor_name'], item['name']]
        .map((v) => v?.toString().trim() ?? '')
        .firstWhere((v) => v.isNotEmpty, orElse: () => 'Restaurant');
    final statusText = (item['status_text'] ?? item['status'] ?? '')
        .toString()
        .trim();
    final lower = statusText.toLowerCase();
    // Shown as the order code (e.g. ORD-001307); the numeric id stays in numericOrderId.
    final code = item['order_code']?.toString().trim() ?? '';
    final orderId = code.isNotEmpty
        ? code
        : item['order_id'] == null
        ? ''
        : '#${item['order_id']}';
    final total = item['item_total'] ?? item['total'];
    final totalValue = double.tryParse('${total ?? ''}') ?? 0;
    final items = item['items'];
    return {
      'restaurantName': name,
      'statusText': statusText.isEmpty ? 'Order' : statusText,
      'isCancelled': lower.contains('cancel'),
      'isDelivered': lower.contains('deliver'),
      'isSelfPickup':
          item['is_self_pickup'] == 1 || item['is_self_pickup'] == true,
      'orderId': orderId,
      'numericOrderId': _asInt(item['order_id'] ?? item['id']),
      'totalText': totalValue <= 0 ? '' : '${totalValue.round()} MRU',
      'itemsCount': item['items_count'] != null
          ? _asInt(item['items_count'])
          : (items is List ? items.length : 0),
    };
  }

  /// Items sit in `data` directly, or in `data.data` for a Laravel paginator.
  dynamic _restaurantItemsList(Map<String, dynamic> data, dynamic body) {
    dynamic raw = data['data'];
    if (raw is Map) raw = raw['data'];
    if (raw is List) return raw;
    if (data['items'] is List) return data['items'];
    if (data['menus'] is Map && data['menus']['data'] is List) {
      return data['menus']['data'];
    }
    if (data['menus'] is List) return data['menus'];
    if (data['products'] is List) return data['products'];
    if (body is List) return body;
    return null;
  }

  List<Map<String, dynamic>> _parseRestaurantItems(
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
          : (m['title'] ?? m['name'] ?? 'Item').toString();

      final img =
          ApiConstants.mediaUrl(
            m['image']?.toString() ??
                m['photo']?.toString() ??
                m['thumb']?.toString(),
          ) ??
          '';
      final images = <String>[];
      if (img.isNotEmpty) images.add(img);
      if (m['images'] is List) {
        for (final im in m['images']) {
          final u = ApiConstants.mediaUrl(im?.toString());
          if (u != null && !images.contains(u)) images.add(u);
        }
      }
      if (images.isEmpty && img.isNotEmpty) images.add(img);

      // discount_price is the selling price; price is the list price when it's lower
      final listPrice = _moneyOf(m['price']);
      final sellingPrice = _moneyOf(m['discount_price']);
      final hasSale = sellingPrice > 0 && sellingPrice < listPrice;
      final priceNum = hasSale ? sellingPrice : listPrice;
      final origPriceNum = hasSale
          ? listPrice
          : _moneyOf(
              m['original_price'] ??
                  m['originalPrice'] ??
                  m['mrp'] ??
                  m['strike_price'],
            );

      final priceStr =
          m['price_text']?.toString() ??
          (priceNum > 0 ? '$priceNum MRU' : '— MRU');

      final origPriceStr =
          m['original_price_text']?.toString() ??
          (origPriceNum > priceNum ? '$origPriceNum MRU' : '');

      final discountVal =
          m['discount'] ?? m['offer_percentage'] ?? m['discount_percentage'];
      final discountStr =
          m['discount_text']?.toString() ??
          (discountVal != null && _asInt(discountVal) > 0
              ? '${_asInt(discountVal)}% OFF'
              : (origPriceNum > priceNum && origPriceNum > 0
                    ? '${(((origPriceNum - priceNum) / origPriceNum) * 100).round()}% OFF'
                    : ''));

      final tag = _localized(m, 'category_name', language).isNotEmpty
          ? _localized(m, 'category_name', language)
          : (_localized(m, 'cuisine_name', language).isNotEmpty
                ? _localized(m, 'cuisine_name', language)
                : (m['tag'] ?? m['category'] ?? _firstTagName(m, language))
                      .toString());

      final rating = (m['rating'] ?? '').toString();
      final reviews = m['reviews_count'] != null
          ? '${m['reviews_count']} reviews'
          : (m['reviews']?.toString() ?? '');

      final isVeg =
          m['is_veg'] == 1 ||
          m['is_veg'] == true ||
          m['is_veg'] == '1' ||
          m['isVeg'] == true ||
          m['veg'] == 1 ||
          m['veg'] == true;

      list.add({
        // Restaurant items are keyed by menu_id; the top-level item has no id
        'id': (m['id'] ?? m['menu_id'] ?? m['item_id'] ?? m['product_id'] ?? '')
            .toString(),
        'item_id': _asInt(m['item_id'] ?? m['id'] ?? m['product_id']),
        'title': title,
        'name': title,
        'image': img,
        'images': images,
        'isVeg': isVeg,
        'tag': tag,
        'rating': rating,
        'reviews': reviews,
        'price': priceStr,
        'originalPrice': origPriceStr,
        'discount': discountStr,
        'description': _localized(m, 'description', language),
        'ingredients': m['ingredients'],
        'portions': m['portions'] ?? m['item_portions'] ?? m['sizes'],
        // An item is sellable while any of its variants has stock
        'inStock': itemInStock(m),
        'raw': m,
      });
    }
    return list;
  }

  Future<RestaurantHomeResult> fetchRestaurantHomeV2({
    required double latitude,
    required double longitude,
    required String language,
    int? categoryId,
    List<int>? categoryIds,
    String? keyword,
    String? sortBy,
    String? rating,
    String? offers,
    String? veg,
    String? nonVeg,
    String? priceRange,
    String? tags,
    int limit = 20,
    int under30Limit = 20,
    String city = '',
  }) async {
    final payload = <String, dynamic>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'limit': limit.toString(),
      'under_30_limit': under30Limit.toString(),
      'city': city,
      'keyword': keyword ?? '',
      'sort_by': sortBy ?? '',
      'rating': rating ?? '',
      'offers': offers ?? '',
      'veg': veg ?? '',
      'non_veg': nonVeg ?? '',
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
        ApiConstants.restaurantHomeV2,
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return _parseRestaurantHome(data, language);
  }

  /// Restaurant search: keyword, the quick filters, and the filter chips the API offers.
  Future<
    ({
      List<Map<String, dynamic>> restaurants,
      List<Map<String, dynamic>> filters,
    })
  >
  searchRestaurants({
    required double latitude,
    required double longitude,
    required String language,
    String keyword = '',
    Map<String, String> filters = const {},
    int? categoryId,
  }) async {
    String field(String key) => filters[key]?.trim() ?? '';
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.restaurantSearchV2,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'keyword': keyword.trim(),
          'limit': '20',
          'page': '1',
          'veg': field('veg'),
          'offers': field('offers'),
          'rating': field('rating'),
          'under_30': field('under_30'),
          'open_now': field('open_now'),
          if (categoryId != null && categoryId > 0)
            'category_id': '$categoryId',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final quickList = asJsonMap(data['filters'])?['quick'];
    final chips = <Map<String, dynamic>>[];
    if (quickList is List) {
      for (final entry in quickList) {
        final chip = asJsonMap(entry);
        if (chip == null) continue;
        final param = chip['param']?.toString().trim() ?? '';
        final value = chip['value']?.toString().trim() ?? '';
        if (param.isEmpty || value.isEmpty) continue;
        final label = _localized(chip, 'label', language);
        chips.add({
          'param': param,
          'value': value,
          'label': label.isEmpty ? param : label,
        });
      }
    }
    return (
      restaurants: _parseRestaurantList(data['restaurants'], language),
      filters: chips,
    );
  }

  RestaurantHomeResult _parseRestaurantHome(
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

    final under30Raw = data['under_30_minutes'];
    final under30 = _parseRestaurantList(under30Raw, language);

    final trendingRaw = data['trending'];
    final trending = _parseRestaurantList(trendingRaw, language);

    final restaurantsRaw = data['restaurants'];
    final restaurants = _parseRestaurantList(restaurantsRaw, language);

    final mapStoresRaw = data['map_stores'];
    final mapStores = <Map<String, dynamic>>[];
    if (mapStoresRaw is List) {
      for (final ms in mapStoresRaw) {
        final m = asJsonMap(ms);
        if (m == null) continue;
        mapStores.add({
          'id': _asInt(m['id'] ?? m['restaurant_id']),
          'restaurant_id': _asInt(m['restaurant_id'] ?? m['id']),
          'title': _localized(m, 'name', language),
          'name': _localized(m, 'name', language),
          'image': ApiConstants.mediaUrl(m['image']?.toString()) ?? '',
          'latitude': m['latitude']?.toString() ?? '',
          'longitude': m['longitude']?.toString() ?? '',
          'distance_km': m['distance_km'] ?? 0,
          'rating': m['rating'] ?? 0,
          'is_open': _asInt(m['is_open'], fallback: 1),
        });
      }
    }

    var trendingTitle = _localized(data, 'trending_title', language);
    final trendingCity = data['trending_city']?.toString().trim() ?? '';
    if (trendingTitle.isEmpty && trendingCity.isNotEmpty) {
      trendingTitle = 'Trending in $trendingCity';
    }

    final meta = asJsonMap(data['meta']) ?? <String, dynamic>{};

    return RestaurantHomeResult(
      sliders: sliders,
      under30Minutes: under30,
      trending: trending,
      restaurants: restaurants,
      mapStores: mapStores,
      trendingTitle: trendingTitle,
      trendingCity: trendingCity,
      meta: meta,
    );
  }

  List<Map<String, dynamic>> _parseRestaurantList(
    dynamic raw,
    String language,
  ) {
    if (raw is! List) return const [];
    final list = <Map<String, dynamic>>[];
    for (final item in raw) {
      final m = asJsonMap(item);
      if (m == null) continue;
      list.add(_parseRestaurant(m, language));
    }
    return list;
  }

  Map<String, dynamic> _parseRestaurant(
    Map<String, dynamic> raw,
    String language,
  ) {
    final title = _localized(raw, 'name', language);
    var subtitle = _localized(raw, 'cuisine_label', language);
    if (subtitle.isEmpty && raw['cuisine_tags'] is List) {
      final tags = (raw['cuisine_tags'] as List)
          .map((t) => _localized(asJsonMap(t) ?? {}, 'name', language))
          .where((s) => s.isNotEmpty)
          .toList();
      if (tags.isNotEmpty) {
        subtitle = tags.join(' • ');
      }
    }
    if (subtitle.isEmpty) {
      subtitle = raw['address']?.toString() ?? '';
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
        : '${_kmText(raw['distance_km'])} Km';

    final discount = raw['offer_text']?.toString().trim().isNotEmpty == true
        ? raw['offer_text'].toString().trim()
        : (raw['offer_percentage'] != null &&
                  _asInt(raw['offer_percentage']) > 0
              ? '${raw['offer_percentage']}% OFF'
              : '');

    final points = raw['points_text']?.toString().trim().isNotEmpty == true
        ? raw['points_text'].toString().trim()
        : '${raw['user_points_available'] ?? 0} Points Available';

    final isOpen = _asInt(raw['is_open'], fallback: 1);
    final openStatus = raw['open_status']?.toString().toUpperCase() ?? '';
    final isClosed = isOpen == 0 || openStatus == 'CLOSED';
    final isTemporarilyClosed =
        openStatus == 'BUSY' || openStatus == 'TEMPORARILY_CLOSED';

    return {
      'id': (raw['id'] ?? raw['restaurant_id'] ?? '').toString(),
      'restaurant_id': _asInt(raw['restaurant_id'] ?? raw['id']),
      'title': title.isEmpty ? 'Restaurant' : title,
      'name': title.isEmpty ? 'Restaurant' : title,
      'subtitle': subtitle,
      'image': ApiConstants.mediaUrl(raw['image']?.toString()) ?? '',
      'rating': (raw['rating'] ?? 0).toString(),
      'rating_count': _asInt(raw['rating_count']),
      'time': time,
      'dist': dist,
      'discount': discount,
      'points': points,
      'isClosed': isClosed,
      'isTemporarilyClosed': isTemporarilyClosed,
      'opensAt': raw['opens_at']?.toString() ?? '10 AM',
      'isFavourite': _asInt(raw['is_favorite']) == 1,
      'address': raw['address']?.toString() ?? '',
      'latitude': raw['latitude']?.toString() ?? '',
      'longitude': raw['longitude']?.toString() ?? '',
      'raw': raw,
    };
  }

  List<Map<String, dynamic>> _categories(dynamic raw, String language) {
    if (raw is! List) return const [];
    final categories = <Map<String, dynamic>>[];
    for (final item in raw) {
      final category = asJsonMap(item);
      if (category == null) continue;
      final id = _asInt(category['category_id']);
      final name = _localized(category, 'name', language);
      // Merged categories list every underlying id; items may sit under any of them
      final mergedIds = category['category_ids'] is List
          ? (category['category_ids'] as List)
                .map((e) => _asInt(e))
                .where((e) => e > 0)
                .toList()
          : <int>[];
      categories.add({
        'id': id,
        'category_ids': mergedIds.isEmpty && id > 0 ? [id] : mergedIds,
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

  /// Item-level stock: `has_stock` when the API sends it, else `stock`.
  /// Items without either are treated as available.
  static bool itemInStock(Map<String, dynamic> item) {
    final hasStock = item['has_stock'];
    if (hasStock != null) {
      return hasStock == true || '$hasStock' == '1' || '$hasStock' == 'true';
    }
    final stock = item['stock'];
    if (stock != null) return (int.tryParse('$stock') ?? 0) > 0;
    return true;
  }

  /// Restaurant items matching a keyword and filters, searched on the server.
  Future<List<Map<String, dynamic>>> searchRestaurantItems({
    required int restaurantId,
    required String language,
    dynamic categoryId,
    String keyword = '',
    String veg = '',
    String offers = '',
    String rating = '',
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.restaurantItemsSearch,
        data: {
          'restaurant_id': '$restaurantId',
          if (categoryId != null) 'category_id': '$categoryId',
          'keyword': keyword.trim(),
          'veg': veg,
          'offers': offers,
          'rating': rating,
          'limit': '20',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return _menuItemsOf(envelope.data, language);
  }

  /// Restaurant items found by barcode within the given categories.
  Future<List<Map<String, dynamic>>> searchRestaurantItemsByBarcode({
    required int restaurantId,
    required List<int> categoryIds,
    required String barcode,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.restaurantItemsBarcodeSearch,
        data: {
          'restaurant_id': '$restaurantId',
          'category_id': categoryIds.map((id) => '$id').toList(),
          'barcode': barcode.trim(),
          'limit': '20',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return _menuItemsOf(envelope.data, language);
  }

  List<Map<String, dynamic>> _menuItemsOf(dynamic data, String language) {
    final body = asJsonMap(data) ?? <String, dynamic>{};
    final menus = asJsonMap(body['menus']) ?? <String, dynamic>{};
    return _parseRestaurantItems(menus['data'], language);
  }

  /// Categories a single restaurant actually sells.
  Future<List<Map<String, dynamic>>> fetchRestaurantCategories({
    required int restaurantId,
    required String language,
    String keyword = '',
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.restaurantCategories,
        queryParameters: {
          'restaurant_id': restaurantId,
          'keyword': keyword.trim(),
        },
      ),
      language,
    );
    return _categories(envelope.data, language);
  }

  /// Variants and option groups for one menu item (read without the envelope:
  /// this endpoint has no `data` key).
  Future<
    ({
      List<Map<String, dynamic>> variants,
      List<Map<String, dynamic>> optionGroups,
      Map<String, dynamic> extras,
    })
  >
  fetchRestaurantMenuVariants({
    required int menuId,
    required int restaurantId,
  }) async {
    final response = await _client.dio.get(
      ApiConstants.restaurantMenuVariants,
      queryParameters: {'menu_id': menuId, 'restaurant_id': restaurantId},
    );
    final body = asJsonMap(response.data) ?? <String, dynamic>{};
    return (
      variants: _mapsOfList(body['variants']),
      optionGroups: _mapsOfList(body['option_groups']),
      extras: asJsonMap(body['extras']) ?? <String, dynamic>{},
    );
  }

  /// Full detail for one menu item.
  Future<Map<String, dynamic>> fetchRestaurantItemDetail({
    required int menuId,
    required int restaurantId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.restaurantItemDetail,
        queryParameters: {'menu_id': menuId, 'restaurant_id': restaurantId},
      ),
      language,
    );
    return asJsonMap(envelope.data) ?? <String, dynamic>{};
  }

  /// Tags on one menu item. Read raw: this endpoint returns status as a string.
  Future<List<String>> fetchRestaurantMenuTags({
    required int menuId,
    required String language,
  }) async {
    final response = await _client.dio.get(
      ApiConstants.restaurantMenuTags,
      queryParameters: {'menu_id': menuId},
    );
    return _tagNames(response.data, language);
  }

  /// All restaurant tags. Read raw: this endpoint returns status as a string.
  Future<List<String>> fetchRestaurantTags({required String language}) async {
    final response = await _client.dio.get(ApiConstants.restaurantTags);
    return _tagNames(response.data, language);
  }

  List<String> _tagNames(dynamic raw, String language) {
    final body = asJsonMap(raw) ?? <String, dynamic>{};
    return _mapsOfList(body['data'])
        .map((tag) => _localized(tag, 'name', language))
        .where((name) => name.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _mapsOfList(dynamic raw) => raw is List
      ? raw.map(asJsonMap).whereType<Map<String, dynamic>>().toList()
      : <Map<String, dynamic>>[];

  /// Name of the first tag on an item, e.g. tags: [{name_en: "Spicy"}].
  String _firstTagName(Map<String, dynamic> item, String language) {
    final tags = item['tags'];
    if (tags is! List || tags.isEmpty) return '';
    final first = asJsonMap(tags.first);
    return first == null ? '' : _localized(first, 'name', language);
  }

  /// Distance with one decimal, e.g. 3369.52 -> "3369.5".
  String _kmText(dynamic value) {
    final km = double.tryParse('${value ?? ''}');
    return km == null ? '0' : km.toStringAsFixed(1);
  }

  /// Whole-number amount from "400.00", 400 or "400.00 MRU".
  int _moneyOf(dynamic value) {
    final match = RegExp(r'\d+(\.\d+)?').firstMatch('${value ?? ''}');
    return match == null ? 0 : double.parse(match.group(0)!).round();
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
          error.message.isEmpty ? 'core_request_failed'.tr : error.message,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }
}
