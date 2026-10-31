// Unit tests for the pieces every screen relies on: the API envelope, the
// payment method rules, a repository mapper and the service slot window.
// (Replaces the template counter test, which didn't match this app.)

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saimpex_v2/core/network/api_exception.dart';
import 'package:saimpex_v2/core/network/api_message.dart';
import 'package:saimpex_v2/core/network/dio_client.dart';
import 'package:saimpex_v2/core/storage/session_store.dart';
import 'package:saimpex_v2/models/chatbot_repository.dart';
import 'package:saimpex_v2/models/service_booking_detail.dart';
import 'package:saimpex_v2/utils/payment_methods.dart';
import 'package:saimpex_v2/utils/wallet_balance.dart';
import 'package:saimpex_v2/views/services/service_booking_submit.dart';

const _messages = {
  'message_en': ['Done'],
  'message_fr': ['Fait'],
  'message_ar': ['تم'],
};

/// A DioClient whose requests never leave the test: [answer] builds the
/// response (or throws a DioException) for each request.
Future<DioClient> _fakeClient(
  Response<dynamic> Function(RequestOptions options) answer,
) async {
  SharedPreferences.setMockInitialValues({});
  final session = SessionStore();
  await session.init();
  final client = DioClient(session);
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          handler.resolve(answer(options));
        } on DioException catch (error) {
          handler.reject(error);
        }
      },
    ),
  );
  return client;
}

void main() {
  group('ApiEnvelope.parse', () {
    test('returns data and the message in the asked language', () {
      final envelope = ApiEnvelope.parse(
        {
          'status': true,
          'data': {'id': 7},
          'message': _messages,
        },
        'fr',
        statusCode: 200,
      );
      expect(envelope.data, {'id': 7});
      expect(envelope.message, 'Fait');
      expect(envelope.statusCode, 200);
    });

    test('a JSON string body is decoded', () {
      final envelope = ApiEnvelope.parse(
        '{"status": true, "data": [1, 2], "message": {"message_en": ["Ok"]}}',
        'en',
      );
      expect(envelope.data, [1, 2]);
      expect(envelope.message, 'Ok');
    });

    test('status false throws with the translated reason', () {
      expect(
        () => ApiEnvelope.parse({
          'status': false,
          'message': {
            'payment_type_en': ['Cash is not available right now.'],
            'payment_type_ar': ['النقد غير متاح حالياً.'],
          },
        }, 'ar'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'النقد غير متاح حالياً.',
          ),
        ),
      );
    });

    test('a 422 nests the languages under the field name', () {
      expect(
        resolveApiMessage({
          'is_self_pickup': {
            'message_en': ['Choose delivery or pickup.'],
          },
        }, 'en'),
        'Choose delivery or pickup.',
      );
    });

    test('a body that is not an object is rejected', () {
      expect(
        () => ApiEnvelope.parse('<html>', 'en'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PaymentMethods', () {
    tearDown(() => PaymentMethods.enabledForTest = null);

    test('every method counts as on until the list loads', () {
      PaymentMethods.enabledForTest = null;
      expect(PaymentMethods.isOn(paymentTypeCash), isTrue);
      expect(PaymentMethods.isOn(paymentTypePayAfterDelivery), isTrue);
    });

    test('keeps the choice while it is on', () {
      PaymentMethods.enabledForTest = {paymentTypeWallet, paymentTypeOnline};
      expect(
        PaymentMethods.keepOrFirstOn(paymentTypeOnline, [
          paymentTypeWallet,
          paymentTypeOnline,
        ]),
        paymentTypeOnline,
      );
    });

    test('moves to the first method still on', () {
      PaymentMethods.enabledForTest = {paymentTypeOnline, paymentTypeCash};
      expect(
        PaymentMethods.keepOrFirstOn(paymentTypeWallet, [
          paymentTypeWallet,
          paymentTypeOnline,
          paymentTypeCash,
        ]),
        paymentTypeOnline,
      );
    });

    test('null when every offered method is off', () {
      PaymentMethods.enabledForTest = {paymentTypeCash};
      expect(
        PaymentMethods.keepOrFirstOn(paymentTypeWallet, [
          paymentTypeWallet,
          paymentTypeOnline,
        ]),
        isNull,
      );
    });
  });

  group('ChatbotRepository', () {
    test('maps a reply and sends the conversation id', () async {
      late RequestOptions sent;
      final client = await _fakeClient((options) {
        sent = options;
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': true,
            'data': {
              'conversation_id': '12',
              'reply': ' Your order is on its way. ',
              'refused': 0,
              'voice_output': true,
            },
            'message': _messages,
          },
        );
      });
      final reply = await ChatbotRepository(client).sendMessage(
        message: 'Where is my order?',
        conversationId: 12,
        language: 'en',
      );
      expect(sent.path, 'customer/chatbot/message');
      expect(sent.data, {
        'message': 'Where is my order?',
        'conversation_id': 12,
      });
      expect(reply.conversationId, 12);
      expect(reply.reply, 'Your order is on its way.');
      expect(reply.refused, isFalse);
      expect(reply.voiceOutput, isTrue);
    });

    test('a 429 becomes a translated ApiException', () async {
      final client = await _fakeClient((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 429,
            data: {
              'status': false,
              'message': {
                'message_en': ['Daily limit reached.'],
                'message_fr': ['Limite quotidienne atteinte.'],
              },
            },
          ),
        );
      });
      await expectLater(
        ChatbotRepository(client).sendMessage(message: 'Hi', language: 'fr'),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                'Limite quotidienne atteinte.',
              )
              .having((e) => e.statusCode, 'statusCode', 429),
        ),
      );
    });
  });

  group('serviceSlotWindow', () {
    final day = DateTime(2026, 11, 2);

    test('one meridiem for the range: 10-12 PM is 10 AM to noon', () {
      expect(serviceSlotWindow(day, '10-12 PM'), (
        '2026-11-02 10:00:00',
        '2026-11-02 12:00:00',
      ));
    });

    test('both meridiems and minutes', () {
      expect(serviceSlotWindow(day, '11:30 AM - 1:15 PM'), (
        '2026-11-02 11:30:00',
        '2026-11-02 13:15:00',
      ));
    });

    test('an unreadable label gives null', () {
      expect(serviceSlotWindow(day, 'Tomorrow'), isNull);
    });
  });

  group('ServiceBookingDetail', () {
    ServiceBookingDetail parse(int status, List<int> logged) =>
        ServiceBookingDetail.fromJson({
          'booking': {
            'id': 42,
            'order_code': 'SB42',
            'status': status,
            'payment_status': 1,
            'total': '575.00',
            'lines': [
              {
                'kind': 'space',
                'name': 'Bedrooms',
                'quantity': 2,
                'price': 100,
              },
              {
                'kind': 'addon',
                'name': 'Fridge Cleaning',
                'quantity': 1,
                'price': 50,
              },
            ],
          },
          'timeline': [
            for (final s in logged)
              {'status': s, 'created_at': '2026-10-31 14:05:00'},
          ],
        });

    test('lines are split by kind with their totals', () {
      final detail = parse(1, [1]);
      expect(detail.lines('space').single.total, 200);
      expect(detail.lines('addon').single.name, 'Fridge Cleaning');
      expect(detail.lines('vehicle'), isEmpty);
    });

    test('a step counts as reached from the timeline or a later finish', () {
      final arriving = parse(3, [1, 2, 8, 3]);
      expect(arriving.reached(8), isTrue);
      expect(arriving.reached(9), isFalse);
      expect(parse(9, [1]).reached(8), isTrue);
    });

    test('a cancelled booking only shows the first step reached', () {
      final cancelled = parse(10, [1, 2, 10]);
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.reached(1), isTrue);
      expect(cancelled.reached(2), isFalse);
      expect(cancelled.timeOf(10), '31 Oct 2026,\n2:05 PM');
    });

    test('unpaid bookings are not paid', () {
      final detail = parse(1, [1]);
      expect(detail.isPaid, isFalse);
      expect(detail.total, 575);
    });
  });
}
