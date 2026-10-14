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
          'city': '',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final location = asJsonMap(data['location']) ?? <String, dynamic>{};
    final sections = _sections(data['sections']);
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

  List<Map<String, dynamic>> _verticals(dynamic raw, String language) {
    if (raw is! List) return const [];
    final verticals = <Map<String, dynamic>>[];
    for (final item in raw) {
      final vertical = asJsonMap(item);
      if (vertical == null) continue;
      final enabled = vertical['is_enabled'];
      if (enabled == false || enabled == 0 || enabled == '0') continue;
      verticals.add({
        'id': _asInt(vertical['vertical_id']),
        'slug': vertical['slug']?.toString() ?? '',
        'label': _localized(vertical, 'name', language),
        'parentId': vertical['parent_vertical_id'] == null
            ? null
            : _asInt(vertical['parent_vertical_id']),
        'sort': _asInt(vertical['sort_order']),
        'icon': ApiConstants.mediaUrl(vertical['icon']?.toString()),
      });
    }
    verticals.sort(
      (a, b) => (a['sort'] as int).compareTo(b['sort'] as int),
    );
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
      cards.add({
        'id': '${vendor['id'] ?? vendor['vendor_id'] ?? vendor['pharmacy_id'] ?? ''}',
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
        'isTemporarilyClosed': false,
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
        'itemPrefix': (order['item_name'] ?? order['menu_name'] ?? '').toString(),
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

  Map<String, Map<String, String>> _sections(dynamic raw) {
    final sections = <String, Map<String, String>>{};
    if (raw is! List) return sections;
    for (final item in raw) {
      final section = asJsonMap(item);
      if (section == null) continue;
      final key = section['key']?.toString() ?? '';
      if (key.isEmpty) continue;
      sections[key] = {
        'title': section['title_en']?.toString().trim() ?? '',
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
        final nested = _cleanText(value['url'] ?? value['path'] ?? value['image']);
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
