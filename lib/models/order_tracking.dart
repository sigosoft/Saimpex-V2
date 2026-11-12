import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../utils/api_language.dart';
import '../utils/cancel_reason.dart';
import '../utils/order_status_label.dart';
import '../utils/store_labels.dart';
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

  /// In the app language for codes 1–10; the server's English text otherwise.
  String get statusText => orderStatusLabel(
    _data['status'],
    '${_data['status_text'] ?? ''}'.trim(),
    selfPickup: isSelfPickup,
  );
  bool get isDelivered => status == 9;
  bool get isCancelled => status == 10;
  bool get isFinished => isDelivered || isCancelled;

  /// 0 placed, 1 preparing, 2 on the way (ready, for pickup), 3 delivered.
  int get stage => stageFor(status, selfPickup: isSelfPickup);

  /// The four-step progress for an order status code, shared by Order
  /// details and tracking so both screens show the same step (they
  /// disagreed for "Ready": details said On the way, tracking Preparing).
  /// 1 placed, 2 accepted, 3 preparing, 4 ready, 5 assigned, 6 arrived,
  /// 7 picked up, 8 on the way, 9 delivered.
  static int stageFor(int status, {bool selfPickup = false}) {
    if (status >= 9) return 3;
    // A pickup order is "ready" once the store has it ready; a delivery is
    // "on the way" only once the driver has picked it up.
    if (status >= (selfPickup ? 4 : 7)) return 2;
    if (status >= 2) return 1;
    return 0;
  }

  String get orderCode => '${_data['order_code'] ?? ''}'.trim();

  /// The 4-digit code the customer gives the driver at the door; empty when
  /// the order has none.
  String get deliveryPin => '${_data['delivery_pin'] ?? ''}'.trim();

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

  /// The driver's last position, or null when it is unknown or clearly
  /// stale: more than [_maxDriverKm] from every stop of the order. A test
  /// driver on dev reported a position in India, so the route and camera
  /// spanned half the world.
  LatLng? get driverLocation {
    final driver = _point(_map('driver')['lat'], _map('driver')['lng']);
    if (driver == null) return null;
    final stops = [
      storeLocation,
      deliveryLocation,
      if (isCourier) ...[pickup.location, dropoff.location],
    ].whereType<LatLng>();
    if (stops.isEmpty) return driver;
    final near = stops.any((stop) => distanceKm(driver, stop) <= _maxDriverKm);
    return near ? driver : null;
  }

  static const double _maxDriverKm = 100;

  /// Great-circle distance in kilometres.
  @visibleForTesting
  static double distanceKm(LatLng a, LatLng b) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

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
        // updated_at_iso has the offset, so the step shows in the phone's
        // time zone (C-B9); older servers only send the text.
        final iso = readableIsoTime(entry['updated_at_iso']);
        return iso.isNotEmpty ? iso : readableServerTime(entry['updated_at']);
      }
    }
    return '';
  }

  /// Why a cancelled order was cancelled (the latest "Cancelled" timeline
  /// remark), in the app language where the server text is fixed; empty when
  /// there is none.
  String get cancelReason {
    if (!isCancelled) return '';
    final timeline = _data['timeline'];
    if (timeline is! List) return '';
    for (final entry in timeline.reversed) {
      if (entry is Map && int.tryParse('${entry['status']}') == 10) {
        return cancelReasonLabel('${entry['remark'] ?? ''}');
      }
    }
    return '';
  }

  String get placedAt {
    final time = timeOf(1);
    return time.isNotEmpty ? time : readableServerTime(_data['ordered_at']);
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
      setState(() => trackingError = 'core_live_tracking_unavailable'.tr);
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
