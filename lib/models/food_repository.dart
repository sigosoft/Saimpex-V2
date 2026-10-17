import 'package:dio/dio.dart';

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
    final raw = asJsonMap(data['restaurant']) ??
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
            ? '${raw['distance_km']} Km'
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
    final payload = <String, dynamic>{
      'restaurant_id': restaurantId.toString(),
      if (categoryId != null &&
          categoryId.toString().isNotEmpty &&
          categoryId.toString() != '0')
        'category_id': categoryId.toString(),
      if (limit != null && limit > 0) 'limit': limit.toString(),
      if (page != null && page > 0) 'page': page.toString(),
    };

    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.restaurantItems,
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );

    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    dynamic itemsRaw;
    if (data['data'] is List) {
      itemsRaw = data['data'];
    } else if (data['items'] is List) {
      itemsRaw = data['items'];
    } else if (data['menus'] is Map && data['menus']['data'] is List) {
      itemsRaw = data['menus']['data'];
    } else if (data['menus'] is List) {
      itemsRaw = data['menus'];
    } else if (data['products'] is List) {
      itemsRaw = data['products'];
    } else if (envelope.data is List) {
      itemsRaw = envelope.data;
    }

    return _parseRestaurantItems(itemsRaw, language);
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

      final img = ApiConstants.mediaUrl(
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

      final priceVal = m['price'];
      final priceNum = _asInt(priceVal);
      final origPriceVal = m['original_price'] ??
          m['originalPrice'] ??
          m['mrp'] ??
          m['strike_price'];
      final origPriceNum = _asInt(origPriceVal);

      final priceStr = m['price_text']?.toString() ??
          (priceVal != null && priceVal.toString().trim().isNotEmpty
              ? (priceVal.toString().contains('MRU')
                  ? priceVal.toString().trim()
                  : '$priceVal MRU')
              : (priceNum > 0 ? '$priceNum MRU' : '0 MRU'));

      final origPriceStr = m['original_price_text']?.toString() ??
          (origPriceVal != null && origPriceVal.toString().trim().isNotEmpty
              ? (origPriceVal.toString().contains('MRU')
                  ? origPriceVal.toString().trim()
                  : '$origPriceVal MRU')
              : (origPriceNum > priceNum ? '$origPriceNum MRU' : ''));

      final discountVal = m['discount'] ??
          m['offer_percentage'] ??
          m['discount_percentage'];
      final discountStr = m['discount_text']?.toString() ??
          (discountVal != null && _asInt(discountVal) > 0
              ? '${_asInt(discountVal)}% OFF'
              : (origPriceNum > priceNum && origPriceNum > 0
                  ? '${(((origPriceNum - priceNum) / origPriceNum) * 100).round()}% OFF'
                  : ''));

      final tag = _localized(m, 'category_name', language).isNotEmpty
          ? _localized(m, 'category_name', language)
          : (_localized(m, 'cuisine_name', language).isNotEmpty
              ? _localized(m, 'cuisine_name', language)
              : (m['tag'] ?? m['category'] ?? '').toString());

      final rating = (m['rating'] ?? '').toString();
      final reviews = m['reviews_count'] != null
          ? '${m['reviews_count']} reviews'
          : (m['reviews']?.toString() ?? '');

      final isVeg = m['is_veg'] == 1 ||
          m['is_veg'] == true ||
          m['is_veg'] == '1' ||
          m['isVeg'] == true ||
          m['veg'] == 1 ||
          m['veg'] == true;

      list.add({
        'id': (m['id'] ?? m['item_id'] ?? m['product_id'] ?? '').toString(),
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
      'category_id':
          (categoryId != null && categoryId != 0) ? categoryId.toString() : '',
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

  List<Map<String, dynamic>> _parseRestaurantList(dynamic raw, String language) {
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
        : '${raw['distance_km'] ?? 0} Km';

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
