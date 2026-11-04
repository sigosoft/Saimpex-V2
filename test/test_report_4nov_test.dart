import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/controllers/select_location_controller.dart';
import 'package:saimpex_v2/models/order_tracking.dart';
import 'package:saimpex_v2/utils/order_status_label.dart';

void main() {
  // No translations are loaded here, so .tr returns the key.
  test('C-B26: a finished self-pickup order says picked up', () {
    expect(orderStatusLabel(9, 'Delivered'), 'core_status_9');
    expect(
      orderStatusLabel(9, 'Delivered', selfPickup: true),
      'core_status_9_pickup',
    );
    expect(orderStatusLabel(4, 'Ready', selfPickup: true), 'core_status_4');
    expect(
      OrderTracking.fromJson(const {
        'status': 9,
        'is_self_pickup': 1,
      }).statusText,
      'core_status_9_pickup',
    );
  });

  test('C-B22: only places in Mauritania count as a delivery spot', () {
    // Nouakchott, Nouadhibou, Néma.
    expect(
      SelectLocationController.isInServiceCountry(18.0858, -15.9785),
      isTrue,
    );
    expect(
      SelectLocationController.isInServiceCountry(20.9425, -17.0362),
      isTrue,
    );
    expect(
      SelectLocationController.isInServiceCountry(16.6167, -7.2500),
      isTrue,
    );
    // Kochi (India), Las Palmas (Spain).
    expect(
      SelectLocationController.isInServiceCountry(9.9312, 76.2673),
      isFalse,
    );
    expect(
      SelectLocationController.isInServiceCountry(28.1235, -15.4363),
      isFalse,
    );
  });
}
