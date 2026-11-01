import 'package:dio/dio.dart';
import 'package:get/get.dart' show Get, Inst, Trans;

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';
import '../core/storage/session_store.dart';

/// Messages from SAIMPEX support about an order (API §6.37). Text only;
/// one thread per order.
class SupportRepository {
  SupportRepository(this._client);

  final DioClient _client;

  /// The repository, registered on first use.
  static SupportRepository get instance {
    if (Get.isRegistered<SupportRepository>()) {
      return Get.find<SupportRepository>();
    }
    final session = Get.isRegistered<SessionStore>()
        ? Get.find<SessionStore>()
        : SessionStore();
    final dio = Get.isRegistered<DioClient>()
        ? Get.find<DioClient>()
        : Get.put(DioClient(session), permanent: true);
    return Get.put(SupportRepository(dio), permanent: true);
  }

  /// Threads newest first, and the unread count for the badge.
  Future<({List<Map<String, dynamic>> threads, int unread})> threads(
    String language,
  ) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.supportMessages),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final list = data['threads'];
    return (
      threads: list is List
          ? list
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList()
          : <Map<String, dynamic>>[],
      unread: int.tryParse('${data['unread_total'] ?? 0}') ?? 0,
    );
  }

  /// One order's messages, oldest first. Marks support's messages read.
  Future<List<Map<String, dynamic>>> messages(
    int orderId,
    String language,
  ) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.supportMessages,
        queryParameters: {'order_id': orderId},
      ),
      language,
    );
    final list = (asJsonMap(envelope.data) ?? {})['messages'];
    return list is List
        ? list
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList()
        : <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> reply(
    int orderId,
    String text,
    String language,
  ) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.replySupportMessage,
        data: {'order_id': orderId, 'message': text},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return asJsonMap((asJsonMap(envelope.data) ?? {})['message']);
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
          error.message.isEmpty ? 'core_request_failed'.tr : error.message,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }
}
