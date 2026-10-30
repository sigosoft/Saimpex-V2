import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../utils/api_language.dart';
import 'order_repository.dart';

/// customer/trackOrder or customer/orderDetails, parsed for the tracking and
/// order detail screens. Both return the same status, vendor, courier,
/// driver, delivery_location and timeline shapes.
class OrderTracking {
  OrderTracking._(this._data);

  factory OrderTracking.fromJson(Map<String, dynamic> data) =>
      OrderTracking._(data);

  final Map<String, dynamic> _data;

  // Order status codes: 1 placed … 7 picked up, 8 on the way, 9 delivered,
  // 10 cancelled.
  int get status => int.tryParse('${_data['status'] ?? ''}') ?? 0;
  String get statusText => '${_data['status_text'] ?? ''}'.trim();
  bool get isDelivered => status == 9;
  bool get isCancelled => status == 10;
  bool get isFinished => isDelivered || isCancelled;

  /// 0 placed, 1 preparing, 2 on the way, 3 delivered.
  int get stage {
    if (status >= 9) return 3;
    if (status >= 7) return 2;
    if (status >= 2) return 1;
    return 0;
  }

  String get orderCode => '${_data['order_code'] ?? ''}'.trim();

  Map<String, dynamic> _map(String key) {
    final value = _data[key];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  String get vendorName => '${_map('vendor')['name'] ?? ''}'.trim();
  String get vendorAddress => '${_map('vendor')['address'] ?? ''}'.trim();

  LatLng? get storeLocation =>
      _point(_map('vendor')['latitude'], _map('vendor')['longitude']);

  bool get isSelfPickup =>
      int.tryParse('${_data['is_self_pickup'] ?? ''}') == 1;

  /// Courier and express orders carry pickup/drop-off instead of a vendor.
  bool get isCourier => _data['courier'] is Map;
  CourierStop get pickup => CourierStop._(_courierMap('pickup'));
  CourierStop get dropoff => CourierStop._(_courierMap('dropoff'));
  String get packageSize => '${_map('courier')['package_size'] ?? ''}'.trim();
  String get packageDescription =>
      '${_map('courier')['package_description'] ?? ''}'.trim();
  bool get isExpress {
    final value = _map('courier')['is_express'];
    return value == true || value == 1 || value == '1';
  }

  Map<String, dynamic> _courierMap(String key) {
    final value = _map('courier')[key];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  /// orderDetails only: the order lines and the payment summary.
  List<Map<String, dynamic>> get items {
    final value = _data['items'];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  Map<String, dynamic> get payment => _map('payment');

  LatLng? get deliveryLocation => _point(
    _map('delivery_location')['latitude'],
    _map('delivery_location')['longitude'],
  );

  String get deliveryAddress =>
      '${_map('delivery_location')['address'] ?? ''}'.trim();

  bool get hasDriver => _data['driver'] is Map;
  LatLng? get driverLocation =>
      _point(_map('driver')['lat'], _map('driver')['lng']);
  String get driverName => '${_map('driver')['name'] ?? ''}'.trim();
  String get driverImage =>
      ApiConstants.mediaUrl('${_map('driver')['image'] ?? ''}') ?? '';
  double get driverRating =>
      double.tryParse('${_map('driver')['rating'] ?? ''}') ?? 0;
  int get driverReviews =>
      int.tryParse('${_map('driver')['reviews'] ?? ''}') ?? 0;

  /// When the order first reached [status], from the status timeline.
  String timeOf(int status) {
    final timeline = _data['timeline'];
    if (timeline is! List) return '';
    for (final entry in timeline) {
      if (entry is Map && int.tryParse('${entry['status']}') == status) {
        return '${entry['updated_at'] ?? ''}';
      }
    }
    return '';
  }

  String get placedAt {
    final time = timeOf(1);
    return time.isNotEmpty ? time : '${_data['ordered_at'] ?? ''}';
  }

  static LatLng? _point(dynamic lat, dynamic lng) {
    final latitude = double.tryParse('${lat ?? ''}');
    final longitude = double.tryParse('${lng ?? ''}');
    if (latitude == null || longitude == null) return null;
    if (latitude == 0 && longitude == 0) return null;
    return LatLng(latitude, longitude);
  }
}

/// A courier order's pickup or drop-off point.
class CourierStop {
  const CourierStop._(this._data);

  final Map<String, dynamic> _data;

  String get address => '${_data['address'] ?? ''}'.trim();
  String get contactName => '${_data['contact_name'] ?? ''}'.trim();
  String get contactPhone => '${_data['contact_phone'] ?? ''}'.trim();
  LatLng? get location =>
      OrderTracking._point(_data['latitude'], _data['longitude']);
}

/// Loads customer/orderDetails once for an order detail screen. Returns null
/// when there is no numeric id; API failures throw [ApiException].
Future<OrderTracking?> loadOrderDetail(int? orderId) async {
  if (orderId == null || orderId < 1) return null;
  if (!Get.isRegistered<OrderRepository>()) return null;
  final data = await Get.find<OrderRepository>().orderDetails(
    orderId: orderId,
    language: apiLanguageCode(),
  );
  return OrderTracking.fromJson(data);
}

/// Loads customer/trackOrder for a tracking screen and refreshes it every
/// 15 seconds until the order is delivered or cancelled.
mixin OrderTrackingMixin<T extends StatefulWidget> on State<T> {
  OrderTracking? tracking;
  String? trackingError;
  Timer? _trackingTimer;

  /// Called after each successful load so the screen can move its pins.
  void onTrackingUpdated(OrderTracking tracking);

  void startTracking(int? orderId) {
    if (orderId == null || orderId < 1) {
      setState(() => trackingError = 'Live tracking is not available');
      return;
    }
    _loadTracking(orderId);
    _trackingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (tracking?.isFinished == true) {
        _trackingTimer?.cancel();
        return;
      }
      _loadTracking(orderId);
    });
  }

  Future<void> _loadTracking(int orderId) async {
    if (!Get.isRegistered<OrderRepository>()) return;
    try {
      final data = await Get.find<OrderRepository>().trackOrder(
        orderId: orderId,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      final next = OrderTracking.fromJson(data);
      setState(() {
        tracking = next;
        trackingError = null;
      });
      onTrackingUpdated(next);
    } on ApiException catch (error) {
      if (!mounted) return;
      // Keep showing the last good data; only report when there is none.
      if (tracking == null) setState(() => trackingError = error.message);
    }
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }
}
