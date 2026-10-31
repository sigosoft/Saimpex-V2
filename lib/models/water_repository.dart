import 'package:dio/dio.dart';
import 'package:get/get.dart' show Trans;

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

/// Water vertical: home sections, search, plans and subscriptions.
class WaterRepository {
  WaterRepository(this._client);

  final DioClient _client;

  /// Home sections from waterHome. Each list uses the keys the water cards read.
  Future<
    ({
      List<String> sliders,
      List<Map<String, dynamic>> categories,
      List<Map<String, dynamic>> topRatedSuppliers,
      List<Map<String, dynamic>> popularProducts,
      List<Map<String, dynamic>> nearbySuppliers,
    })
  >
  fetchHome({
    required double latitude,
    required double longitude,
    required String language,
    int limit = 10,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.waterHome,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'limit': '$limit',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return (
      sliders: _list(data['sliders'])
          .map((s) => ApiConstants.mediaUrl(s['image']?.toString()) ?? '')
          .where((url) => url.isNotEmpty)
          .toList(),
      categories: _list(data['categories']).map(_category).toList(),
      topRatedSuppliers: _list(
        data['top_rated_suppliers'],
      ).map(_supplier).toList(),
      popularProducts: _list(data['popular_products']).map(_product).toList(),
      nearbySuppliers: _list(data['nearby_suppliers']).map(_supplier).toList(),
    );
  }

  /// Search across water suppliers and products (waterSearchV2).
  /// Pass [categoryId] to list the products of one water category.
  Future<
    ({
      List<Map<String, dynamic>> suppliers,
      List<Map<String, dynamic>> products,
    })
  >
  search({
    required double latitude,
    required double longitude,
    required String language,
    String keyword = '',
    int? categoryId,
    int limit = 20,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.waterSearchV2,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'keyword': keyword.trim(),
          if (categoryId != null && categoryId > 0)
            'category_id': '$categoryId',
          'limit': '$limit',
          'products_limit': '$limit',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final suppliers = data['suppliers'] is List
        ? data['suppliers']
        : data['stores'];
    return (
      suppliers: _list(suppliers).map(_supplier).toList(),
      products: _list(data['products']).map(_product).toList(),
    );
  }

  /// Subscription plans offered by a water supplier (water/plans).
  Future<List<Map<String, dynamic>>> fetchPlans({
    required int waterVendorId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.waterPlans,
        queryParameters: {'water_vendor_id': waterVendorId},
      ),
      language,
    );
    return _list(envelope.data).map(_plan).toList();
  }

  /// Every product a supplier sells: its categories (water/categories), then
  /// the items of each category (water/items). Shaped for the supplier screens.
  Future<List<Map<String, dynamic>>> fetchSupplierProducts({
    required int waterVendorId,
    required String language,
  }) async {
    final categoriesEnvelope = await _send(
      () => _client.dio.get(
        ApiConstants.waterCategories,
        queryParameters: {'water_vendor_id': waterVendorId},
      ),
      language,
    );
    final categoryIds = _list(categoriesEnvelope.data)
        .map((category) => _asInt(category['category_id'] ?? category['id']))
        .where((id) => id > 0);

    final products = <Map<String, dynamic>>[];
    for (final categoryId in categoryIds) {
      final envelope = await _send(
        () => _client.dio.post(
          ApiConstants.waterItems,
          data: {
            'water_vendor_id': '$waterVendorId',
            'category_id': '$categoryId',
            'limit': '50',
          },
          options: Options(contentType: Headers.jsonContentType),
        ),
        language,
      );
      final page = asJsonMap(envelope.data) ?? <String, dynamic>{};
      products.addAll(
        _list(page['data']).map(
          (item) => _supplierProduct(
            item,
            vendorId: waterVendorId,
            categoryId: categoryId,
          ),
        ),
      );
    }
    return products;
  }

  /// The customer's water orders (orders/water), one page at a time. Needs a session.
  Future<({List<Map<String, dynamic>> orders, int currentPage, int lastPage})>
  fetchOrders({required String language, int limit = 10, int page = 1}) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.waterOrders,
        queryParameters: {'limit': limit, 'page': page},
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return (
      orders: _list(data['data']).map(_waterOrder).toList(),
      currentPage: _asInt(data['current_page']),
      lastPage: _asInt(data['last_page']),
    );
  }

  /// Adds a water product to the customer's cart (cart/water/add). Needs a session.
  Future<String> addToCart({
    required int waterVendorId,
    required int productId,
    required String language,
    int quantity = 1,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.cartWaterAdd,
        data: {
          'water_vendor_id': '$waterVendorId',
          'product_id': '$productId',
          'quantity': '$quantity',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  /// Buys a subscription to a supplier's plan (water/subscribe); amount =
  /// plan price × [quantity]. [paymentType] 1 cash on the first delivery,
  /// 2 online (status pending_payment; returns `payment_url`), 3 wallet (paid
  /// now; 422 if short). Returns the server message and the response data.
  /// Needs a session.
  Future<({String message, Map<String, dynamic> data})> subscribe({
    required int planId,
    required int quantity,
    required DateTime startDate,
    required DateTime endDate,
    required String deliverySlot,
    required String address,
    required double latitude,
    required double longitude,
    required String paymentType,
    required String language,
  }) async {
    String day(DateTime date) =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.waterSubscribe,
        data: {
          'plan_id': planId,
          'quantity': quantity,
          'start_date': day(startDate),
          'end_date': day(endDate),
          'delivery_slot': deliverySlot,
          'address_line1': address,
          'latitude': latitude,
          'longitude': longitude,
          'payment_type': paymentType,
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return (
      message: envelope.message,
      data: asJsonMap(envelope.data) ?? <String, dynamic>{},
    );
  }

  /// The customer's water subscriptions (water/subscriptions). Needs a session.
  Future<List<Map<String, dynamic>>> fetchSubscriptions({
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.waterSubscriptions),
      language,
    );
    final data = envelope.data;
    final raw = data is Map ? (data['data'] ?? data['subscriptions']) : data;
    return _list(raw).map(_subscription).toList();
  }

  Future<String> pauseSubscription({
    required int subscriptionId,
    required String language,
  }) => _changeSubscription(
    ApiConstants.waterSubscriptionPause,
    subscriptionId,
    language,
  );

  Future<String> resumeSubscription({
    required int subscriptionId,
    required String language,
  }) => _changeSubscription(
    ApiConstants.waterSubscriptionResume,
    subscriptionId,
    language,
  );

  Future<String> cancelSubscription({
    required int subscriptionId,
    required String language,
  }) => _changeSubscription(
    ApiConstants.waterSubscriptionCancel,
    subscriptionId,
    language,
  );

  Future<String> _changeSubscription(
    String path,
    int subscriptionId,
    String language,
  ) async {
    final envelope = await _send(
      () => _client.dio.post(
        path,
        data: {'subscription_id': subscriptionId},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  /// A subscription shaped for the My Subscriptions cards.
  Map<String, dynamic> _subscription(Map<String, dynamic> item) {
    final status = '${item['status'] ?? ''}'.toLowerCase();
    final bottles = _asInt(item['bottles_per_delivery']);
    final slot = '${item['delivery_slot'] ?? ''}'.trim();
    final frequency = '${item['frequency_label'] ?? ''}'.trim();
    String text(dynamic value) => '${value ?? ''}'.trim();
    return {
      'id': _asInt(item['subscription_id']),
      'state': status,
      'title': text(item['vendor_name']).isEmpty
          ? 'core_water_supplier'.tr
          : text(item['vendor_name']),
      'subtitle': _localized(item, 'product_name', fallback: ''),
      'size': text(item['package_label']),
      'qty': bottles > 0 ? 'x$bottles' : '',
      'status': text(item['status_label']),
      'imageUrl':
          ApiConstants.mediaUrl(item['product_image']?.toString()) ?? '',
      'frequency': slot.isEmpty ? frequency : '$frequency ($slot)',
      'nextDelivery': text(item['next_delivery_at']).split(' ').first,
      'startDate': text(item['start_date']),
      'endDate': text(item['end_date']),
      'pauseUntil': text(item['pause_until']).split(' ').first,
    };
  }

  Map<String, dynamic> _supplier(Map<String, dynamic> item) {
    final name = _localized(item, 'name', fallback: 'Supplier');
    final closed = item['is_open'] == 0 || item['is_open'] == false;
    final busy = item['busy_mode'] == 2;
    final distance = double.tryParse('${item['distance_km'] ?? ''}');
    return {
      'id': '${item['id'] ?? item['vendor_id'] ?? ''}',
      'vendorId': _asInt(item['id'] ?? item['vendor_id']),
      'name': name,
      'subtitle': _localized(item, 'address', fallback: ''),
      'rating': _ratingText(item['rating']),
      'time': item['delivery_time_text']?.toString() ?? '',
      'dist': distance == null ? '' : '${distance.toStringAsFixed(1)} Km',
      'discount':
          item['offer_percentage'] != null &&
              '${item['offer_percentage']}' != '0'
          ? '${item['offer_percentage']}% OFF'
          : '',
      'points': '',
      'image': ApiConstants.mediaUrl(item['image']?.toString()) ?? '',
      'isFavorite': item['is_favorite'] == true,
      'isClosed': closed,
      'isTemporarilyClosed': busy,
      'opensAt': item['opening_time']?.toString() ?? '',
    };
  }

  Map<String, dynamic> _product(Map<String, dynamic> item) {
    final selling = _amount(
      item['selling_price'] ?? item['discount_price'] ?? item['price'],
    );
    return {
      'id': '${item['menu_id'] ?? item['id'] ?? ''}',
      'productId': _cartProductId(item),
      'vendorId': _asInt(item['water_vendor_id'] ?? item['vendor_id']),
      'title': _localized(item, 'name', fallback: 'Product'),
      'supplier': _localized(item, 'vendor_name', fallback: '').isNotEmpty
          ? _localized(item, 'vendor_name', fallback: '')
          : _localized(item, 'pharmacy_name', fallback: ''),
      'rating': _ratingText(item['rating']),
      'price': selling > 0 ? '${selling.round()} MRU' : '— MRU',
      'image': ApiConstants.mediaUrl(item['image']?.toString()) ?? '',
    };
  }

  /// A supplier product shaped for the product cards and details sheet.
  Map<String, dynamic> _supplierProduct(
    Map<String, dynamic> item, {
    required int vendorId,
    required int categoryId,
  }) {
    final variants = _list(item['items']);
    final first = variants.isEmpty ? <String, dynamic>{} : variants.first;
    final selling = _amount(
      item['selling_price'] ??
          first['selling_price'] ??
          item['discount_price'] ??
          item['price'],
    );
    final original = _amount(first['mrp_amount'] ?? item['price']);
    final offer = _amount(item['offer_percentage']).round();
    final size = '${item['size_label'] ?? first['size_label'] ?? ''}';
    final package = '${item['package_label'] ?? first['package_label'] ?? ''}';
    final images = _list(item['image_items'])
        .map((image) => ApiConstants.mediaUrl(image['image']?.toString()) ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
    final image = ApiConstants.mediaUrl(item['image']?.toString()) ?? '';
    if (images.isEmpty && image.isNotEmpty) images.add(image);

    return {
      'id': '${item['menu_id'] ?? ''}',
      'productId': _cartProductId(item),
      'vendorId': vendorId,
      'categoryId': categoryId,
      'title': _localized(item, 'name', fallback: 'Product'),
      'image': image.isEmpty && images.isNotEmpty ? images.first : image,
      'images': images,
      'size': size,
      'sizeTag': size,
      'bottleTag': package,
      'quantity': package,
      'rating': _ratingText(item['rating']),
      'reviews': '${_asInt(item['rating_count'])} reviews',
      'price': selling > 0 ? '${selling.round()} MRU' : '— MRU',
      'originalPrice': original > selling ? '${original.round()} MRU' : '',
      'discount': offer > 0 ? '$offer% OFF' : '',
      'description': _localized(item, 'description', fallback: ''),
    };
  }

  Map<String, dynamic> _category(Map<String, dynamic> item) {
    return {
      'id': _asInt(item['category_id'] ?? item['id']),
      'label': _localized(item, 'name', fallback: 'Category'),
      'image': ApiConstants.mediaUrl(item['image']?.toString()) ?? '',
    };
  }

  Map<String, dynamic> _plan(Map<String, dynamic> item) {
    return {
      'id': _asInt(item['id'] ?? item['plan_id']),
      'title': _localized(item, 'name', fallback: 'Plan'),
      'price': _amount(item['price']) > 0
          ? '${_amount(item['price']).round()} MRU'
          : '— MRU',
      'priceValue': _amount(item['price']),
      'productId': _asInt(item['product_id']),
      'frequencyKey': '${item['frequency_key'] ?? ''}',
      'frequencyLabel': '${item['frequency_label'] ?? ''}',
      'bottlesPerDelivery': _asInt(item['bottles_per_delivery']),
      'status':
          item['status_text']?.toString() ?? item['status']?.toString() ?? '',
    };
  }

  Map<String, dynamic> _waterOrder(Map<String, dynamic> item) {
    final code = item['order_code']?.toString().trim() ?? '';
    final status = item['status_text']?.toString().trim() ?? '';
    final total = _amount(item['total']);
    return {
      'orderId': code.isEmpty ? '${item['order_id'] ?? ''}' : code,
      'numericOrderId': _asInt(item['order_id']),
      'vendorName': item['vendor_name']?.toString().trim().isNotEmpty == true
          ? item['vendor_name'].toString().trim()
          : 'core_water_supplier'.tr,
      'statusText': status,
      'isCancelled': status.toLowerCase().contains('cancel'),
      'isDelivered': status.toLowerCase().contains('deliver'),
      'total': '${total.round()} MRU',
      'itemsCount': _asInt(item['items_count']),
    };
  }

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((entry) => asJsonMap(entry))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Name in the chosen language, falling back to English, then [fallback].
  String _localized(
    Map<String, dynamic> item,
    String key, {
    required String fallback,
  }) {
    for (final code in ['en', 'fr', 'ar']) {
      final value = item['${key}_$code']?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    final plain = item[key]?.toString().trim() ?? '';
    return plain.isEmpty || plain == 'null' ? fallback : plain;
  }

  String _ratingText(dynamic value) {
    final number = double.tryParse('${value ?? ''}') ?? 0;
    return number.toStringAsFixed(1);
  }

  double _amount(dynamic value) => double.tryParse('${value ?? ''}') ?? 0;

  int _asInt(dynamic value) => int.tryParse('${value ?? ''}') ?? 0;

  /// The id the cart expects: the product (variant) id, not the menu id.
  /// Falls back to the menu id when the response has no variant list.
  int _cartProductId(Map<String, dynamic> item) {
    final direct = _asInt(item['product_id']);
    if (direct > 0) return direct;
    final variants = item['variants'] ?? item['items'];
    if (variants is List && variants.isNotEmpty) {
      final first = asJsonMap(variants.first);
      final id = _asInt(first?['product_id'] ?? first?['item_id']);
      if (id > 0) return id;
    }
    return _asInt(item['menu_id'] ?? item['id']);
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
