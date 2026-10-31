import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

/// The customer's SAIMPEX Wallet: balance, history and top-ups. Needs a session.
class WalletRepository {
  WalletRepository(this._client);

  final DioClient _client;

  /// GET wallet: `balance`, `topup_limits` {min, max}, `transactions[]`
  /// (id, type credit|debit, amount, balance_after, description, order_id,
  /// created_at) and `pagination` {current_page, last_page, total}.
  Future<Map<String, dynamic>> fetch({
    required String language,
    int page = 1,
    int perPage = 20,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.wallet,
        queryParameters: {'page': page, 'per_page': perPage},
      ),
      language,
    );
    return asJsonMap(envelope.data) ?? <String, dynamic>{};
  }

  /// Starts a top-up (POST wallet/topup). Returns `topup_id` and the Masrvi
  /// `payment_url` to open; the wallet is credited when the payment succeeds.
  Future<Map<String, dynamic>> topUp({
    required num amount,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.walletTopUp,
        data: {'amount': amount},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return asJsonMap(envelope.data) ?? <String, dynamic>{};
  }

  /// A top-up's `status` (pending | paid | failed) and the wallet `balance`.
  Future<Map<String, dynamic>> topUpStatus({
    required int topUpId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(ApiConstants.walletTopUpStatus(topUpId)),
      language,
    );
    return asJsonMap(envelope.data) ?? <String, dynamic>{};
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
