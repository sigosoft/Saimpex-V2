import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/models/order_tracking.dart';
import 'package:saimpex_v2/utils/cancel_reason.dart';

void main() {
  // No translations are loaded here, so .tr returns the key.
  test('fixed server remarks map to app strings', () {
    expect(
      cancelReasonLabel('Order Cancelled by Vendor'),
      'core_cancel_by_store',
    );
    expect(
      cancelReasonLabel('Order Cancelled by pharmacy'),
      'core_cancel_by_store',
    );
    expect(
      cancelReasonLabel('Order Cancelled by water vendor'),
      'core_cancel_by_store',
    );
    expect(
      cancelReasonLabel(
        'Order Cancelled - Not accepted by vendor within 24 hours',
      ),
      'core_cancel_not_accepted',
    );
  });

  test('plain cancel has no reason; a typed reason is kept', () {
    expect(cancelReasonLabel('Order Cancelled'), '');
    expect(cancelReasonLabel(null), '');
    expect(cancelReasonLabel(' Customer unreachable '), 'Customer unreachable');
  });

  test('reason comes from the latest Cancelled timeline entry', () {
    final order = OrderTracking.fromJson({
      'status': 10,
      'timeline': [
        {'status': 2, 'remark': 'Order Accepted'},
        {'status': 10, 'remark': 'Customer unreachable'},
      ],
    });
    expect(order.cancelReason, 'Customer unreachable');
    final open = OrderTracking.fromJson({
      'status': 2,
      'timeline': [
        {'status': 10, 'remark': 'Customer unreachable'},
      ],
    });
    expect(open.cancelReason, '');
  });
}
