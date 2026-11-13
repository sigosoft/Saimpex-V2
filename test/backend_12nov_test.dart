// The app side of the 12 Nov backend list: cancel reason (#177), courier
// pickup time (#184) and banners (#164), notifications read (#183) and the
// closed-store opening time (#185).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saimpex_v2/core/network/dio_client.dart';
import 'package:saimpex_v2/core/storage/session_store.dart';
import 'package:saimpex_v2/models/courier_repository.dart';
import 'package:saimpex_v2/models/order_repository.dart';
import 'package:saimpex_v2/models/profile_repository.dart';
import 'package:saimpex_v2/utils/store_labels.dart';

const _messages = {
  'message_en': ['Done'],
};

/// A DioClient that records each request and answers [data] without
/// leaving the test.
Future<(DioClient, List<RequestOptions>)> _client(Object? data) async {
  SharedPreferences.setMockInitialValues({});
  final session = SessionStore();
  await session.init();
  final client = DioClient(session);
  final sent = <RequestOptions>[];
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        sent.add(options);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'status': true, 'data': data, 'message': _messages},
          ),
        );
      },
    ),
  );
  return (client, sent);
}

void main() {
  test('cancelOrder sends the reason, and none when empty', () async {
    final (client, sent) = await _client(null);
    final orders = OrderRepository(client);
    await orders.cancelOrder(
      orderId: 7,
      language: 'en',
      reason: ' Changed my mind ',
    );
    await orders.cancelOrder(orderId: 8, language: 'en');
    expect(sent[0].data, {'order_id': '7', 'reason': 'Changed my mind'});
    expect(sent[1].data, {'order_id': '8'});
  });

  test('courier create sends scheduled_for with the offset', () async {
    final (client, sent) = await _client({'order_id': 5});
    const stop = CourierStop(address: 'A', latitude: 1, longitude: 2);
    final result = await CourierRepository(client).create(
      pickup: stop,
      dropoff: stop,
      isExpress: false,
      paymentType: '1',
      language: 'en',
      scheduledFor: DateTime(2026, 11, 14, 10),
    );
    final body = sent.single.data as Map;
    expect(
      body['scheduled_for'],
      OrderRepository.scheduledForValue(DateTime(2026, 11, 14, 10)),
    );
    expect(body['scheduled_for'], matches(RegExp(r'[+-]\d\d:\d\d$')));
    expect(result.orderId, 5);
  });

  test('courier sliders: active banner URLs, express flag sent', () async {
    final (client, sent) = await _client({
      'sliders': [
        {'image_url': 'https://cdn.test/a.jpg', 'status': 1},
        {'image_url': 'https://cdn.test/b.jpg', 'status': 0},
      ],
    });
    final urls = await CourierRepository(
      client,
    ).sliders(isExpress: true, language: 'en');
    expect(urls, ['https://cdn.test/a.jpg']);
    expect(sent.single.path, 'customer/courier/sliders');
    expect(sent.single.queryParameters, {'express': 1});
  });

  test('notifications carry order, type and read state', () async {
    final (client, sent) = await _client({
      'notifications': [
        {
          'title_en': 'Order Cancelled!',
          'order_id': 1568,
          'order_type': 1,
          'type': 'order',
          'is_read': false,
        },
      ],
      'unread_count': 1,
    });
    final profile = ProfileRepository(client);
    final row = (await profile.fetchNotifications(language: 'en')).single;
    expect(row['orderId'], 1568);
    expect(row['orderType'], 1);
    expect(row['type'], 'order');
    expect(row['isRead'], isFalse);
    await profile.markNotificationsRead(language: 'en');
    expect(sent.last.path, 'customer/notifications/read');
    expect(sent.last.method, 'POST');
  });

  group('opensAtLabel', () {
    final now = DateTime(2026, 11, 13, 9);

    test('empty when the store has no opening time', () {
      expect(opensAtLabel(null, now: now), '');
      expect(opensAtLabel('null', now: now), '');
    });

    test('today: the time alone', () {
      final today = DateTime(2026, 11, 13, 10).toUtc().toIso8601String();
      final label = opensAtLabel(today, now: now);
      expect(label, contains('10:00'));
      expect(label, isNot(contains('svc_month')));
    });

    test('another day: the day and time, without the year', () {
      final later = DateTime(2026, 11, 14, 10).toUtc().toIso8601String();
      final label = opensAtLabel(later, now: now);
      expect(label, contains('14 svc_month_11'));
      expect(label, contains('10:00'));
      expect(label, isNot(contains('2026')));
    });
  });
}
