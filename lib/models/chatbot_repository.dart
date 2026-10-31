import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

/// One answer from the SAIMPEX assistant (POST chatbot/message).
typedef ChatbotReply = ({
  int? conversationId,
  String reply,
  bool refused,
  bool voiceOutput,
});

/// The AI assistant (Claude, on the server; API §6.19). Read-only: it answers
/// about SAIMPEX and this customer's own orders, wallet and points. Needs a
/// session. Errors (not configured, daily limit, temporary failure) come back
/// as translated [ApiException]s.
class ChatbotRepository {
  ChatbotRepository(this._client);

  final DioClient _client;

  /// Sends typed text or a voice transcript. Pass the [conversationId] the
  /// previous reply returned to continue the same conversation.
  Future<ChatbotReply> sendMessage({
    required String message,
    int? conversationId,
    double? latitude,
    double? longitude,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.chatbotMessage,
        data: {
          'message': message,
          'conversation_id': ?conversationId,
          'latitude': ?latitude,
          'longitude': ?longitude,
        },
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return (
      conversationId: _asInt(data['conversation_id']),
      reply: '${data['reply'] ?? ''}'.trim(),
      refused: data['refused'] == true || data['refused'] == 1,
      voiceOutput: data['voice_output'] == true || data['voice_output'] == 1,
    );
  }

  /// The customer's conversations, latest first: `id`, `title`, `created_at`,
  /// `updated_at`.
  Future<List<Map<String, dynamic>>> conversations(String language) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.chatbotConversations),
      language,
    );
    final rows = (asJsonMap(envelope.data) ?? {})['conversations'];
    if (rows is! List) return const [];
    return [for (final row in rows) ?asJsonMap(row)];
  }

  /// A conversation's transcript: each message has `from` (customer |
  /// assistant), `text` and `at`.
  Future<List<Map<String, dynamic>>> transcript({
    required int conversationId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.chatbotConversation(conversationId)),
      language,
    );
    final rows = (asJsonMap(envelope.data) ?? {})['messages'];
    if (rows is! List) return const [];
    return [for (final row in rows) ?asJsonMap(row)];
  }

  int? _asInt(dynamic value) {
    final parsed = value is int ? value : int.tryParse('${value ?? ''}');
    return parsed == null || parsed < 1 ? null : parsed;
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
          error.message.isEmpty
              ? 'Request failed. Please try again.'
              : error.message,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }
}
