import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

class GeneralRepository {
  GeneralRepository(this._client);

  final DioClient _client;

  Future<List<Map<String, dynamic>>> fetchSplash(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.splash),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final raw = data['splash'];
    if (raw is! List) return const [];

    final slides = <Map<String, dynamic>>[];
    for (final item in raw) {
      final slide = asJsonMap(item);
      if (slide == null) continue;
      slides.add({
        'id': slide['id'],
        'content_en': slide['content_en']?.toString() ?? '',
        'content_ar': slide['content_ar']?.toString() ?? '',
        'content_fr': slide['content_fr']?.toString() ?? '',
        'image': ApiConstants.mediaUrl(slide['image']?.toString()),
      });
    }
    return slides;
  }

  /// Stores and products across every category for a keyword (GET search):
  /// only stores that deliver to the given point, nearest first. Store rows
  /// carry `vertical` (food, grocery, pharmacy, water, local_store, …);
  /// product rows are food or grocery with their `store`.
  Future<
    ({List<Map<String, dynamic>> stores, List<Map<String, dynamic>> products})
  >
  search({
    required String query,
    required double latitude,
    required double longitude,
    required String language,
    int limit = 20,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.search,
        queryParameters: {
          'q': query.trim(),
          'latitude': latitude,
          'longitude': longitude,
          'limit': limit,
        },
      ),
      language,
    );
    return _searchResult(envelope.data);
  }

  /// Search by photo (image-recognition/analyze, without `type`): the server
  /// identifies the product and answers like [search]. Needs a session.
  Future<
    ({List<Map<String, dynamic>> stores, List<Map<String, dynamic>> products})
  >
  searchByImage({
    required String imagePath,
    required double latitude,
    required double longitude,
    required String language,
    int limit = 20,
  }) async {
    final envelope = await _send(
      () async => _client.dio.post(
        ApiConstants.imageSearch,
        data: FormData.fromMap({
          'image': await MultipartFile.fromFile(imagePath),
          'latitude': '$latitude',
          'longitude': '$longitude',
          'limit': '$limit',
        }),
      ),
      language,
    );
    return _searchResult(envelope.data);
  }

  ({List<Map<String, dynamic>> stores, List<Map<String, dynamic>> products})
  _searchResult(dynamic raw) {
    final data = asJsonMap(raw) ?? <String, dynamic>{};
    List<Map<String, dynamic>> rows(dynamic list) => list is List
        ? list.map(asJsonMap).whereType<Map<String, dynamic>>().toList()
        : const [];
    return (stores: rows(data['stores']), products: rows(data['products']));
  }

  Future<Map<String, dynamic>> fetchHome({
    required double latitude,
    required double longitude,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.homeHub,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'limit': '10',
          'recent_limit': '5',
          'city': '',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final location = asJsonMap(data['location']) ?? <String, dynamic>{};
    final sections = _sections(data['sections'], language);
    final trendingTitle = _localized(data, 'trending_title', language);
    if (trendingTitle.isNotEmpty) {
      sections['trending'] = {
        'title': trendingTitle,
        'seeAll': sections['trending']?['seeAll'] ?? 'food',
      };
    }
    return {
      'locationAddress': _cleanText(location['address']),
      'locationCity': _cleanText(location['city']),
      'locationLatitude': _asDoubleOrNull(
        location['latitude'] ?? location['lat'],
      ),
      'locationLongitude': _asDoubleOrNull(
        location['longitude'] ?? location['long'] ?? location['lng'],
      ),
      'profileImage': _profileImage(data['profile']),
      'walletBalance': data['wallet_balance']?.toString() ?? '',
      'walletCurrency': data['wallet_currency']?.toString() ?? '',
      'unreadNotifications': _asInt(data['unread_notifications']),
      'verticals': _verticals(data['verticals'], language),
      'sliders': _images(data['sliders']),
      'promos': _images(data['promos']),
      'trending': _vendors(data['trending'], language),
      'recentOrders': _orders(data['recent_orders'], language),
      'under30': _vendors(data['under_30_minutes'], language),
      'topGrocery': _vendors(data['top_grocery'], language),
      'trustedPharmacies': _vendors(data['trusted_pharmacies'], language),
      'topSuppliers': _vendors(data['top_rated_suppliers'], language),
      'banners': _banners(data['section_banners'], language),
      'sections': sections,
    };
  }

  Future<
    ({
      String subjectType,
      double averageRating,
      int totalReviews,
      Map<String, int> ratingBreakdown,
      List<Map<String, dynamic>> reviews,
      int currentPage,
      int totalPages,
    })
  >
  fetchReviews({
    required String type,
    required String language,
    int? vendorId,
    int? vendorType,
    int? productId,
    int? productType,
    String filter = '',
    int page = 1,
    int perPage = 10,
    int limit = 10,
  }) async {
    final query = <String, dynamic>{
      'type': type,
      'limit': limit,
      'page': page,
      'per_page': perPage,
    };
    if (vendorId != null) query['vendor_id'] = vendorId;
    if (vendorType != null) query['vendor_type'] = vendorType;
    if (productId != null) query['product_id'] = productId;
    if (productType != null) query['product_type'] = productType;
    final trimmedFilter = filter.trim();
    if (trimmedFilter.isNotEmpty) query['filter'] = trimmedFilter;

    final envelope = await _send(
      () => _client.dio.get(ApiConstants.reviews, queryParameters: query),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final breakdownRaw =
        asJsonMap(data['rating_breakdown']) ?? <String, dynamic>{};
    final breakdown = <String, int>{
      for (final key in ['5', '4', '3', '2', '1'])
        key: _asInt(breakdownRaw[key]),
    };
    final pagination = asJsonMap(data['pagination']) ?? <String, dynamic>{};
    final rawReviews = data['reviews'];
    final reviews = <Map<String, dynamic>>[];
    if (rawReviews is List) {
      for (final entry in rawReviews) {
        final review = asJsonMap(entry);
        if (review == null) continue;
        final user = asJsonMap(review['user']) ?? <String, dynamic>{};
        reviews.add({
          'id': _asInt(review['id']),
          'userName': _cleanText(user['name']),
          'userImage': ApiConstants.mediaUrl(user['image']?.toString()) ?? '',
          'rating': _asInt(review['rating']),
          'comment': _cleanText(review['comment']),
          'date': _cleanText(review['date']),
          'timeAgo': _cleanText(review['time_ago']),
        });
      }
    }
    final subject = asJsonMap(data['subject']) ?? <String, dynamic>{};
    return (
      subjectType: _cleanText(subject['type']),
      averageRating: _asNum(data['average_rating']),
      totalReviews: _asInt(data['total_reviews']),
      ratingBreakdown: breakdown,
      reviews: reviews,
      currentPage: _asInt(pagination['page']),
      totalPages: _asInt(pagination['total_pages']),
    );
  }

  List<Map<String, dynamic>> _verticals(dynamic raw, String language) {
    if (raw is! List) return const [];
    final verticals = <Map<String, dynamic>>[];
    for (final item in raw) {
      final vertical = asJsonMap(item);
      if (vertical == null) continue;
      final enabled = vertical['is_enabled'];
      if (enabled == false || enabled == 0 || enabled == '0') continue;
      final iconPath = vertical['icon']?.toString().trim();
      final hasIcon =
          iconPath != null &&
          iconPath.isNotEmpty &&
          iconPath.toLowerCase() != 'null';
      verticals.add({
        'id': _asInt(vertical['vertical_id']),
        'slug': vertical['slug']?.toString() ?? '',
        'label': _localized(vertical, 'name', language),
        'parentId': vertical['parent_vertical_id'] == null
            ? null
            : _asInt(vertical['parent_vertical_id']),
        'sort': _asInt(vertical['sort_order']),
        'icon': hasIcon ? ApiConstants.mediaUrl(iconPath) : null,
      });
    }
    verticals.sort((a, b) => (a['sort'] as int).compareTo(b['sort'] as int));
    return verticals;
  }

  List<Map<String, dynamic>> _vendors(dynamic raw, String language) {
    if (raw is! List) return const [];
    final cards = <Map<String, dynamic>>[];
    for (final item in raw) {
      final vendor = asJsonMap(item);
      if (vendor == null) continue;
      final name = _localized(vendor, 'name', language);
      final cuisine = _localized(vendor, 'cuisine_label', language);
      final category = _localized(vendor, 'category_label', language);
      final offerText = vendor['offer_text']?.toString().trim() ?? '';
      final offer = _asNum(
        vendor['offer_percentage'] ?? vendor['max_offer_percentage'],
      );
      final points = _asNum(vendor['user_points_available']);
      final open = vendor['is_open'];
      final isOpen = open == null || open == 1 || open == true || open == '1';
      final distance = vendor['distance_km'];
      final busyMode = _asInt(vendor['busy_mode']);
      final isFav =
          vendor['is_favourite'] == 1 ||
          vendor['is_favourite'] == true ||
          vendor['is_favourite'] == '1';
      cards.add({
        'id':
            '${vendor['id'] ?? vendor['vendor_id'] ?? vendor['pharmacy_id'] ?? ''}',
        'title': name,
        'subtitle': cuisine.isNotEmpty ? cuisine : category,
        'rating': vendor['rating']?.toString() ?? '',
        'time': vendor['delivery_time_text']?.toString() ?? '',
        'dist': distance == null ? '' : '$distance Km',
        'discount': offerText.isNotEmpty
            ? offerText
            : (offer > 0 ? '${_number(offer)}% OFF' : ''),
        'points': points > 0 ? '${_number(points)} Points Available' : '',
        'isClosed': !isOpen,
        'isTemporarilyClosed': busyMode > 1,
        'isFavourite': isFav,
        'image': ApiConstants.mediaUrl(vendor['image']?.toString()) ?? '',
      });
    }
    return cards;
  }

  List<Map<String, dynamic>> _orders(dynamic raw, String language) {
    if (raw is! List) return const [];
    final orders = <Map<String, dynamic>>[];
    for (final item in raw) {
      final order = asJsonMap(item);
      if (order == null) continue;
      final name = _localized(order, 'name', language);
      orders.add({
        'title': name.isNotEmpty
            ? name
            : (order['vendor_name'] ?? order['title'] ?? '').toString(),
        'rating': order['rating']?.toString() ?? '',
        'itemPrefix': (order['item_name'] ?? order['menu_name'] ?? '')
            .toString(),
        'qty': order['quantity'] == null ? '' : 'x${order['quantity']}',
        'itemSuffix': '',
        'date': (order['ordered_at'] ?? order['date'] ?? '').toString(),
        'itemsCount': order['items_count'] == null
            ? ''
            : '${order['items_count']} Items',
        'image': ApiConstants.mediaUrl(order['image']?.toString()) ?? '',
      });
    }
    return orders;
  }

  List<Map<String, dynamic>> _images(dynamic raw) {
    if (raw is! List) return const [];
    final images = <Map<String, dynamic>>[];
    for (final item in raw) {
      final slide = asJsonMap(item);
      if (slide == null) continue;
      final image = ApiConstants.mediaUrl(
        slide['image']?.toString() ?? slide['slider_image']?.toString(),
      );
      if (image == null || image.isEmpty) continue;
      images.add({'image': image});
    }
    return images;
  }

  List<Map<String, dynamic>> _banners(dynamic raw, String language) {
    if (raw is! List) return const [];
    final banners = <Map<String, dynamic>>[];
    for (final item in raw) {
      final banner = asJsonMap(item);
      if (banner == null) continue;
      banners.add({
        'section': banner['section']?.toString() ?? '',
        'title': _localized(banner, 'title', language),
        'subtitle': _localized(banner, 'subtitle', language),
        'cta': _localized(banner, 'cta_text', language),
        'image': ApiConstants.mediaUrl(banner['image']?.toString()),
        'link': banner['link_value']?.toString() ?? '',
      });
    }
    return banners;
  }

  Map<String, Map<String, String>> _sections(dynamic raw, String language) {
    final sections = <String, Map<String, String>>{};
    if (raw is! List) return sections;
    for (final item in raw) {
      final section = asJsonMap(item);
      if (section == null) continue;
      final key = section['key']?.toString() ?? '';
      if (key.isEmpty) continue;
      final title = _localized(section, 'title', language);
      sections[key] = {
        'title': title.isNotEmpty
            ? title
            : (section['title_en']?.toString().trim() ?? ''),
        'seeAll': section['see_all']?.toString() ?? '',
      };
    }
    return sections;
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

  String _profileImage(dynamic profile) {
    if (profile is String) return _cleanText(profile);
    final map = asJsonMap(profile);
    if (map == null) return '';
    final direct = _imagePath(map);
    if (direct.isNotEmpty) return direct;
    for (final key in ['user', 'customer', 'details']) {
      final nested = _imagePath(asJsonMap(map[key]));
      if (nested.isNotEmpty) return nested;
    }
    return '';
  }

  String _imagePath(Map<String, dynamic>? map) {
    if (map == null) return '';
    for (final key in ['image', 'profile_image', 'avatar', 'photo']) {
      final value = map[key];
      if (value is Map) {
        final nested = _cleanText(
          value['url'] ?? value['path'] ?? value['image'],
        );
        if (nested.isNotEmpty) return nested;
        continue;
      }
      final text = _cleanText(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _cleanText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  double? _asDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = _cleanText(value);
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  double _asNum(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String _number(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  Future<({String title, String content})> fetchAbout(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.getAbout),
      language,
    );
    final data = asJsonMap(envelope.data);
    final about = asJsonMap(data?['about']) ?? data ?? <String, dynamic>{};
    final title = _localized(about, 'title', language);
    final content = _localized(about, 'content', language);
    return (title: title.isEmpty ? 'About Us' : title, content: content);
  }

  Future<({String title, String content})> fetchPrivacyPolicy(
    String language,
  ) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.getPrivacyPolicy),
      language,
    );
    final data = asJsonMap(envelope.data);
    final policy =
        asJsonMap(data?['privacy_policy']) ?? data ?? <String, dynamic>{};
    final title = _localized(policy, 'title', language);
    final content = _localized(policy, 'content', language);
    return (title: title.isEmpty ? 'Privacy Policy' : title, content: content);
  }

  Future<({String title, String content})> fetchTermsAndConditions(
    String language,
  ) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.getTermsAndConditions),
      language,
    );
    final data = asJsonMap(envelope.data);
    final terms = asJsonMap(data?['terms']) ?? data ?? <String, dynamic>{};
    final title = _localized(terms, 'title', language);
    final content = _localized(terms, 'content', language);
    return (
      title: title.isEmpty ? 'Terms & Conditions' : title,
      content: content,
    );
  }

  Future<({String email, String phone})> fetchContact(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.getContact),
      language,
    );
    final data = asJsonMap(envelope.data);
    final contact = asJsonMap(data?['contact']) ?? data ?? <String, dynamic>{};
    final email = contact['email']?.toString().trim() ?? '';
    final mobile = contact['mobile']?.toString().trim() ?? '';
    final countryCode = contact['country_code']?.toString().trim() ?? '';
    final phone = (countryCode.isNotEmpty && mobile.isNotEmpty)
        ? '$countryCode $mobile'
        : (mobile.isNotEmpty ? mobile : countryCode);
    return (email: email, phone: phone);
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
