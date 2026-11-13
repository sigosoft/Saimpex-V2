// The session token goes to the SAIMPEX API only, never to Google Places
// (address search uses the same DioClient), and debug logs hide the Maps key.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saimpex_v2/core/network/api_constants.dart';
import 'package:saimpex_v2/core/network/dio_client.dart';
import 'package:saimpex_v2/core/storage/session_store.dart';

void main() {
  late DioClient client;
  final sent = <Uri, String?>{};

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final session = SessionStore();
    await session.init();
    await session.saveGuestToken('guest-token-123');
    client = DioClient(session);
    sent.clear();
    // Runs after DioClient's interceptor: records what would go out.
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent[options.uri] = options.headers['Authorization']?.toString();
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: {}),
          );
        },
      ),
    );
  });

  test('SAIMPEX API requests carry the session token', () async {
    await client.dio.get(ApiConstants.profile);
    expect(sent.values.single, 'Bearer guest-token-123');
  });

  test('Google Places requests carry no token', () async {
    await client.dio.get(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
      queryParameters: {'input': 'Ksar', 'key': 'secret'},
    );
    expect(sent.values.single, isNull);
  });

  test('a token set by hand is removed for other hosts', () async {
    await client.dio.get(
      'https://maps.googleapis.com/maps/api/place/details/json',
      options: Options(headers: {'Authorization': 'Bearer leaked'}),
    );
    expect(sent.values.single, isNull);
  });

  test('isOwnApi matches only the API host', () {
    expect(
      isOwnApi(Uri.parse('${ApiConstants.baseUrl}customer/profile')),
      isTrue,
    );
    expect(isOwnApi(Uri.parse('https://maps.googleapis.com/x')), isFalse);
    expect(
      isOwnApi(Uri.parse('https://dev.saimpexenterprise.com.evil.test/api')),
      isFalse,
    );
  });

  test('logs hide the key query value', () {
    final logged = safeUriForLog(
      Uri.parse('https://maps.googleapis.com/x?input=Ksar&key=AIzaSECRET'),
    );
    expect(logged, isNot(contains('AIzaSECRET')));
    expect(logged, contains('input=Ksar'));
  });
}
