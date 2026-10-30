import 'package:dio/dio.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';

/// Service verticals (car wash, home cleaning, laundry): providers,
/// slots, quotes and bookings.
class ServiceRepository {
  ServiceRepository(this._client);

  final DioClient _client;

  static const carWash = 'car_wash';
  static const homeCleaning = 'home_cleaning';
  static const laundry = 'laundry';

  /// Providers near the given point, shaped for the provider cards.
  Future<List<Map<String, String>>> fetchProviders({
    required String vertical,
    required double latitude,
    required double longitude,
    required String language,
    int limit = 20,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.serviceProviders,
        queryParameters: {
          'vertical': vertical,
          'latitude': latitude,
          'longitude': longitude,
          'limit': limit,
        },
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final page = asJsonMap(data['providers']) ?? <String, dynamic>{};
    return _maps(page['data']).map(_providerCard).toList();
  }

  /// One provider with its active services and the next available slots.
  Future<Map<String, dynamic>> fetchProvider({
    required int vendorId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.serviceProvider,
        queryParameters: {'vendor_id': vendorId},
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    return {
      'provider': asJsonMap(data['provider']) ?? <String, dynamic>{},
      'services': _maps(data['services']),
      'slots': data['slots'],
    };
  }

  /// Bookable slots for a provider, optionally for one date (yyyy-MM-dd).
  Future<dynamic> fetchSlots({
    required int vendorId,
    required String language,
    String? date,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.serviceSlots,
        queryParameters: {'vendor_id': vendorId, 'date': ?date},
      ),
      language,
    );
    return envelope.data;
  }

  /// Price breakdown for a booking request without placing it.
  Future<Map<String, dynamic>> quote({
    required Map<String, dynamic> request,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.serviceQuote,
        data: request,
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return asJsonMap(envelope.data) ?? <String, dynamic>{};
  }

  /// Places a booking. Needs a session. Returns the created booking.
  Future<({String message, Map<String, dynamic> booking})> book({
    required Map<String, dynamic> request,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.serviceBook,
        data: request,
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return (
      message: envelope.message,
      booking: asJsonMap(envelope.data) ?? <String, dynamic>{},
    );
  }

  /// The customer's service bookings, newest first. All verticals unless
  /// [vertical] is given.
  Future<({List<Map<String, dynamic>> bookings, int currentPage, int lastPage})>
  fetchBookings({
    required String language,
    String? vertical,
    int page = 1,
    int limit = 20,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.serviceBookings,
        queryParameters: {'vertical': ?vertical, 'page': page, 'limit': limit},
      ),
      language,
    );
    final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
    final pageData = asJsonMap(data['bookings']) ?? <String, dynamic>{};
    return (
      bookings: _maps(pageData['data']),
      currentPage: _asInt(pageData['current_page']) ?? page,
      lastPage: _asInt(pageData['last_page']) ?? page,
    );
  }

  /// One booking with its status timeline.
  Future<Map<String, dynamic>> fetchBooking({
    required int orderId,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.get(
        ApiConstants.serviceBooking,
        queryParameters: {'order_id': orderId},
      ),
      language,
    );
    return asJsonMap(envelope.data) ?? <String, dynamic>{};
  }

  Future<String> cancelBooking({
    required int orderId,
    required String reason,
    required String language,
  }) async {
    final envelope = await _send(
      () => _client.dio.post(
        ApiConstants.serviceCancel,
        data: {'order_id': orderId, 'reason': reason},
        options: Options(contentType: Headers.jsonContentType),
      ),
      language,
    );
    return envelope.message;
  }

  /// Provider row shaped like the existing provider cards. Laundry cards also
  /// read ready/tag/price keys.
  Map<String, String> _providerCard(Map<String, dynamic> row) {
    String text(dynamic value) => '${value ?? ''}'.trim();
    final rating = double.tryParse(text(row['rating'])) ?? 0;
    final rate = text(row['starting_rate']);
    final unit = text(row['rate_unit']);
    final availability = text(row['availability']);
    return {
      'id': text(row['id']),
      'name': text(row['name']).isEmpty ? 'Provider' : text(row['name']),
      'rating': rating > 0 ? rating.toStringAsFixed(1) : 'New',
      'distance': text(row['distance_label']),
      'price': rate.replaceAll(' MRU', ''),
      'points': availability.isEmpty ? 'Open' : availability,
      'image': ApiConstants.mediaUrl(text(row['image'])) ?? '',
      'isOpen': row['is_open'] == true ? '1' : '0',
      'ready': text(row['hours_label']).isEmpty
          ? availability
          : text(row['hours_label']),
      'tag1': 'Starting from',
      'price1': rate.isEmpty
          ? '—'
          : unit.isEmpty
          ? rate
          : '$rate/$unit',
      'tag2': 'Rating',
      'price2': rating > 0 ? '${rating.toStringAsFixed(1)} ★' : 'New',
    };
  }

  List<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((entry) => asJsonMap(entry))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('${value ?? ''}');

  Future<ApiEnvelope> _send(
    Future<Response<dynamic>> Function() call,
    String language,
  ) async {
    try {
      final response = await call();
      return ApiEnvelope.parse(
        response.data,
        language,
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
  }
}
