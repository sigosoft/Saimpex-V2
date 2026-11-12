import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/views/services/service_booking_submit.dart';

void main() {
  // The slot sheets give "10-12 PM"; six screens used to turn that into
  // "10:00 PM - 12:00 PM" and book a night-time slot.
  test('one AM/PM suffix: a start before a 12 o\'clock end is morning', () {
    expect(formatServiceSlotLabel('10-12 PM'), '10:00 AM - 12:00 PM');
    expect(formatServiceSlotLabel('8-10 AM'), '8:00 AM - 10:00 AM');
    expect(formatServiceSlotLabel('2-4 PM'), '2:00 PM - 4:00 PM');
    expect(formatServiceSlotLabel('11-1 PM'), '11:00 AM - 1:00 PM');
    expect(formatServiceSlotLabel('8:00-10:00 AM'), '8:00 AM - 10:00 AM');
  });

  test('the booked window for "10-12 PM" starts at 10:00', () {
    final window = serviceSlotWindow(
      DateTime(2026, 11, 13),
      formatServiceSlotLabel('10-12 PM'),
    );
    expect(window?.$1, '2026-11-13 10:00:00');
    expect(window?.$2, '2026-11-13 12:00:00');
  });
}
