import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

class OrderRepository {
  OrderRepository(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> checkoutSummary({
    required bool selfPickup,
    required double latitude,
    required double longitude,
    required String location,
    required bool usePoints,
    required String language,
    String couponCode = '',
    bool version2 = false,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        version2 ? ApiConstants.checkoutSummaryV2 : ApiConstants.checkoutSummary,
        data: {
          'is_self_pickup': selfPickup ? '1' : '0',
          'lat': latitude.toString(),
          'long': longitude.toString(),
          'location': location,
          'coupon_code': couponCode.trim(),
          'use_points': usePoints ? '1' : '0',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    data['message'] = envelope.message;
    return data;
  }

  Future<Map<String, dynamic>> checkout({
    required bool selfPickup,
    required double latitude,
    required double longitude,
    required String location,
    required String paymentType,
    required String language,
    int? cartId,
    String couponCode = '',
    String redeemAmount = '0',
    String note = '',
    bool version2 = true,
  }) async {
    final fields = <String, dynamic>{
      'is_self_pickup': selfPickup ? '1' : '0',
      'lat': latitude.toString(),
      'long': longitude.toString(),
      'location': location,
      'coupon_code': couponCode.trim(),
      'payment_type': paymentType,
      'redeem_amount': redeemAmount,
      'notes': note,
      'order_note': note,
    };
    if (!version2 && cartId != null) fields['cart_id'] = '$cartId';
    final envelope = await _send(
      () => _client.dio.post(
        version2 ? ApiConstants.checkoutV2 : ApiConstants.checkout,
        data: FormData.fromMap(fields),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    data['message'] = envelope.message;
    return data;
  }

  Future<Map<String, dynamic>> masrviSession(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.masrviSession),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    data['message'] = envelope.message;
    return data;
  }

  Future<Map<String, dynamic>> masrviInit({
    required int orderId,
    required String amount,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.masrviInit,
        data: {
          'order_id': '$orderId',
          'test_amount': amount,
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    data['message'] = envelope.message;
    return data;
  }

  Future<String> checkDelivery({
    required double latitude,
    required double longitude,
    required int vendorId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.checkDeliveryAvailability,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'vendor_id': '$vendorId',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  Future<Map<String, dynamic>> orderDetails({
    required int orderId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.orderDetails,
        queryParameters: {'order_id': orderId},
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    data['message'] = envelope.message;
    return data;
  }

  Future<String> cancelOrder({
    required int orderId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.cancelOrder,
        data: {'order_id': '$orderId'},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  Future<Map<String, dynamic>> trackOrder({
    required int orderId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.trackOrder,
        queryParameters: {'order_id': orderId},
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    data['message'] = envelope.message;
    return data;
  }

  Future<List<Map<String, dynamic>>> coupons(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.coupons),
      language,
    );
    final data = envelope.data;
    final raw = data is List
        ? data
        : (asJsonMap(data)?['coupons'] ?? asJsonMap(data)?['data']);
    if (raw is! List) return const [];
    final coupons = <Map<String, dynamic>>[];
    for (final entry in raw) {
      final coupon = asJsonMap(entry);
      if (coupon == null) continue;
      final code = coupon['coupon_code'] ?? coupon['code'] ?? coupon['name'];
      coupons.add({
        'code': '$code',
        'title': '${coupon['title'] ?? coupon['name'] ?? code ?? 'Coupon'}',
        'subtitle':
            '${coupon['description'] ?? coupon['subtitle'] ?? coupon['details'] ?? ''}',
        'discount': '${coupon['discount'] ?? coupon['offer'] ?? ''}',
        'image': ApiConstants.mediaUrl(coupon['image']?.toString()) ?? '',
      });
    }
    return coupons;
  }

  Future<String> applyCoupon({
    required String couponCode,
    required num orderAmount,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.applyCoupon,
        data: {
          'coupon_code': couponCode.trim(),
          'order_amount': orderAmount.toString(),
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  Future<Map<String, dynamic>> rating({
    required int orderId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.rating,
        queryParameters: {'order_id': orderId},
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    data['message'] = envelope.message;
    return data;
  }

  Future<String> submitRating({
    required int orderId,
    required int vendorRating,
    required int driverRating,
    required String language,
    String vendorComment = '',
    String driverComment = '',
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.submitRating,
        data: {
          'order_id': '$orderId',
          'vendor_rating': '$vendorRating',
          'vendor_comment': vendorComment,
          'driver_rating': '$driverRating',
          'driver_comment': driverComment,
          'products': '',
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
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
