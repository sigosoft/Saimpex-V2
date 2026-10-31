import 'dart:io';

import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

class ChatRepository {
  ChatRepository(this._client);

  final DioClient _client;

  Future<List<Map<String, dynamic>>> getAllConversations({
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.chatAllConversations),
      language,
    );

    final dataMap = asJsonMap(envelope.data);
    final rawList = dataMap?['conversations'] ?? envelope.data;
    if (rawList is List) {
      return rawList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> getConversation({
    dynamic vendorId,
    dynamic conversationId,
    required String language,
  }) async {
    final body = <String, dynamic>{};

    if (vendorId != null &&
        vendorId.toString().trim().isNotEmpty &&
        vendorId.toString().trim() != '0') {
      body['vendor_id'] = vendorId.toString().trim();
    }

    if (conversationId != null &&
        conversationId.toString().trim().isNotEmpty &&
        conversationId.toString().trim() != '0') {
      body['conversation_id'] = conversationId.toString().trim();
    }

    final envelope = await _send(
      () => _client.dio.post(ApiConstants.chatGetConversation, data: body),
      language,
    );

    return asJsonMap(envelope.data) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> sendMessage({
    dynamic conversationId,
    dynamic vendorId,
    String? message,
    String messageType = 'text',
    String? attachmentUrl,
    String? imagePath,
    String? voiceNotePath,
    int? duration,
    required String language,
  }) async {
    final fields = <String, dynamic>{};

    if (conversationId != null &&
        conversationId.toString().trim().isNotEmpty &&
        conversationId.toString().trim() != '0') {
      fields['conversation_id'] = conversationId.toString().trim();
    }

    if (vendorId != null &&
        vendorId.toString().trim().isNotEmpty &&
        vendorId.toString().trim() != '0') {
      fields['vendor_id'] = vendorId.toString().trim();
    }

    if (message != null && message.trim().isNotEmpty) {
      fields['message'] = message.trim();
    }

    fields['message_type'] = messageType;

    if (attachmentUrl != null && attachmentUrl.trim().isNotEmpty) {
      fields['attachment_url'] = attachmentUrl.trim();
    }

    if (imagePath != null && imagePath.trim().isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        final fileName = imagePath.split(RegExp(r'[/\\]')).last;
        fields['image'] = await MultipartFile.fromFile(
          imagePath,
          filename: fileName,
        );
      }
    }

    if (voiceNotePath != null && voiceNotePath.trim().isNotEmpty) {
      final file = File(voiceNotePath);
      if (await file.exists()) {
        final fileName = voiceNotePath.split(RegExp(r'[/\\]')).last;
        fields['voice_note'] = await MultipartFile.fromFile(
          voiceNotePath,
          filename: fileName,
        );
      }
    }

    if (duration != null && duration > 0) {
      fields['duration'] = duration.toString();
    }

    final formData = FormData.fromMap(fields);

    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.chatSendMessage,
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ),
      language,
    );

    return asJsonMap(envelope.data) ?? <String, dynamic>{};
  }

  /// Marks the vendor's messages in [conversationId] as read (chat/markAsRead).
  Future<void> markAsRead({
    required dynamic conversationId,
    required String language,
  }) async {
    await _send(
      () => _client.dio.post(
        ApiConstants.chatMarkAsRead,
        data: {'conversation_id': conversationId.toString()},
      ),
      language,
    );
  }

  /// Deletes the conversation for good (chat/deleteConversation, a GET).
  Future<void> deleteConversation({
    required dynamic conversationId,
    required String language,
  }) async {
    await _send(
      () => _client.dio.get(
        ApiConstants.chatDeleteConversation,
        queryParameters: {'conversation_id': conversationId.toString()},
      ),
      language,
    );
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
