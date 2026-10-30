import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

/// Courier vertical: delivery quote and booking.
class CourierRepository {
  CourierRepository(this._client);

  final DioClient _client;

  /// Price and distance for a route. No login needed. Standard when [isExpress] is false.
  Future<({double deliveryFee, double distanceKm, bool isExpress})> quote({
    required CourierStop pickup,
    required CourierStop dropoff,
    required bool isExpress,
    required String language,
    String packageSize = '',
    String packageDescription = '',
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.courierQuote,
        data: {
          'package_size': packageSize,
          'package_description': packageDescription,
          'is_express': isExpress,
          'pickup': pickup.toJson(),
          'dropoff': dropoff.toJson(),
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return (
      deliveryFee: _asDouble(data['delivery_fee']),
      distanceKm: _asDouble(data['distance_km']),
      isExpress: data['is_express'] == true || data['is_express'] == 1,
    );
  }

  /// Books a courier delivery. Needs a session. Returns the server message and the order id if sent.
  Future<({String message, int? orderId})> create({
    required CourierStop pickup,
    required CourierStop dropoff,
    required bool isExpress,
    required String paymentType,
    required String language,
    String packageSize = '',
    String packageDescription = '',
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.courierCreate,
        data: {
          'package_size': packageSize,
          'package_description': packageDescription,
          'is_express': isExpress,
          'payment_type': paymentType,
          'pickup': pickup.toJson(),
          'dropoff': dropoff.toJson(),
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final id = data['order_id'] ?? data['id'];
    return (message: envelope.message, orderId: id is num ? id.toInt() : null);
  }

  /// The customer's courier orders, newest first, one page at a time.
  Future<({List<Map<String, dynamic>> orders, int currentPage, int lastPage})>
  fetchOrders({required String language, int page = 1, int limit = 20}) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.courierOrders,
        queryParameters: {'page': page, 'limit': limit},
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final raw = data['data'] is List ? data['data'] as List : const [];
    final orders = raw
        .map((entry) => asJsonMap(entry))
        .whereType<Map<String, dynamic>>()
        .map(_courierOrder)
        .toList();
    return (
      orders: orders,
      currentPage: _asInt(data['current_page']) ?? page,
      lastPage: _asInt(data['last_page']) ?? page,
    );
  }

  // Order status codes used by the backend order lists.
  static const _statusText = {
    1: 'Placed',
    2: 'Accepted',
    3: 'Preparing',
    4: 'Ready',
    5: 'Assigned',
    6: 'Arrived',
    7: 'Picked Up',
    8: 'On the way',
    9: 'Delivered',
    10: 'Cancelled',
  };

  Map<String, dynamic> _courierOrder(Map<String, dynamic> item) {
    final status = _asInt(item['status']) ?? 0;
    final code = item['order_code']?.toString().trim() ?? '';
    return {
      'orderId': code.isEmpty ? '${item['order_id'] ?? ''}' : code,
      'numericOrderId': _asInt(item['order_id']),
      'statusText': _statusText[status] ?? '',
      'isCancelled': status == 10,
      'isDelivered': status == 9,
      'isExpress': item['is_express'] == true || item['is_express'] == 1,
      'total': '${_asDouble(item['total']).round()} MRU',
      'pickupAddress': item['pickup_address']?.toString() ?? '',
      'dropoffAddress': item['dropoff_address']?.toString() ?? '',
    };
  }

  int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('${value ?? ''}');

  double _asDouble(dynamic value) => double.tryParse('${value ?? ''}') ?? 0;

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

/// A pickup or drop-off point as the courier API expects it.
class CourierStop {
  const CourierStop({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.contactName,
    this.contactPhone,
  });

  final String address;
  final double latitude;
  final double longitude;
  final String? contactName;
  final String? contactPhone;

  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude.toString(),
    'longitude': longitude.toString(),
    if (contactName != null && contactName!.isNotEmpty)
      'contact_name': contactName,
    if (contactPhone != null && contactPhone!.isNotEmpty)
      'contact_phone': contactPhone,
  };
}
