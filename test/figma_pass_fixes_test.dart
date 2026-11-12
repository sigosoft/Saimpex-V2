// Order steps shared by Order details and tracking, and the stale driver
// position filter (Figma pass, 12 Nov).

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:saimpex_v2/models/order_tracking.dart';

void main() {
  group('OrderTracking.stageFor', () {
    test('delivery: Ready is still Preparing, Picked up is On the way', () {
      expect(OrderTracking.stageFor(1), 0);
      expect(OrderTracking.stageFor(3), 1);
      expect(OrderTracking.stageFor(4), 1);
      expect(OrderTracking.stageFor(7), 2);
      expect(OrderTracking.stageFor(9), 3);
    });

    test('self pickup: Ready is the third step', () {
      expect(OrderTracking.stageFor(4, selfPickup: true), 2);
      expect(OrderTracking.stageFor(9, selfPickup: true), 3);
    });
  });

  group('driverLocation', () {
    Map<String, dynamic> order(String lat, String lng) => {
      'vendor': {'latitude': '18.0982840', 'longitude': '-15.9529160'},
      'delivery_location': {'latitude': '18.0858', 'longitude': '-15.9785'},
      'driver': {'lat': lat, 'lng': lng},
    };

    test('kept when near the order', () {
      final tracking = OrderTracking.fromJson(order('18.09', '-15.96'));
      expect(tracking.driverLocation, isNotNull);
    });

    test('dropped when on another continent (stale test GPS)', () {
      final tracking = OrderTracking.fromJson(
        order('11.3046402', '75.8762223'),
      );
      expect(tracking.driverLocation, isNull);
    });

    test('distanceKm', () {
      final km = OrderTracking.distanceKm(
        const LatLng(18.0858, -15.9785),
        const LatLng(18.0983, -15.9529),
      );
      expect(km, closeTo(3.0, 0.5));
    });
  });
}
