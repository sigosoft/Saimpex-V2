import 'package:get/get.dart';

import '../core/network/api_constants.dart';
import '../utils/api_language.dart';
import 'service_repository.dart';

/// customer/service/booking: one service booking (car wash, home cleaning,
/// laundry, gas) with its status timeline, parsed for the detail screens.
class ServiceBookingDetail {
  ServiceBookingDetail._(this._data, this._timeline);

  factory ServiceBookingDetail.fromJson(Map<String, dynamic> data) {
    final booking = data['booking'];
    final timeline = data['timeline'];
    return ServiceBookingDetail._(
      booking is Map ? Map<String, dynamic>.from(booking) : const {},
      [
        if (timeline is List)
          for (final entry in timeline)
            if (entry is Map) Map<String, dynamic>.from(entry),
      ],
    );
  }

  final Map<String, dynamic> _data;
  final List<Map<String, dynamic>> _timeline;

  String _text(String key) => '${_data[key] ?? ''}'.trim();
  double _number(String key) => double.tryParse(_text(key)) ?? 0;

  int? get orderId => int.tryParse(_text('id'));
  String get orderCode => _text('order_code');
  String get vertical => _text('vertical');

  // Order status codes: 1 new, 2 accepted, 3 in progress, 4 ready,
  // 8 on the way, 9 completed/delivered, 10 cancelled.
  int get status => int.tryParse(_text('status')) ?? 0;
  String get statusLabel => _text('status_label');
  bool get isCancelled => status == 10;
  bool get canCancel => _data['can_cancel'] == true;

  String get serviceName => _text('service_name_en');
  String get providerName => _text('provider_name');
  String get location => _text('location');
  String get address => _text('address');
  String get addressLabel => _text('address_label');
  String get slot =>
      _text('slot_window').isNotEmpty ? _text('slot_window') : _text('slot');
  String get notes => _text('notes');

  double get subtotal => _number('subtotal');
  double get tax => _number('tax');
  double get total => _number('total');
  double get totalPaid => _number('total_paid');
  bool get isPaid => int.tryParse(_text('payment_status')) == 2;
  String get paymentLabel => _text('payment_type_label');
  bool get paymentRequired => _data['payment_required'] == true;

  /// Home cleaning: 'vendor' when the provider brings the products.
  String get productSupply => _text('product_supply');
  double get supplyFee => _number('supply_fee');

  /// Gas: empty cylinders the driver collects.
  int get emptyCylinders =>
      int.tryParse(_text('empty_cylinders_to_collect')) ?? 0;
  int get quantity => int.tryParse(_text('quantity')) ?? 1;

  /// Booked lines of one kind: space, addon, vehicle, garment, supply,
  /// distance, issue or property.
  List<ServiceBookingLine> lines(String kind) => [
    for (final line in _list('lines'))
      if ('${line['kind'] ?? ''}' == kind) ServiceBookingLine._(line),
  ];

  /// Home cleaning: the assigned cleaner, null until one is assigned.
  Map<String, dynamic>? get cleaner {
    final value = _data['cleaner'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  /// Raw booking fields for screens with vertical-specific extras (laundry).
  dynamic operator [](String key) => _data[key];

  List<Map<String, dynamic>> _list(String key) {
    final value = _data[key];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  /// When the booking first reached [status], from the timeline, or ''.
  String timeOf(int status) {
    for (final entry in _timeline) {
      if (int.tryParse('${entry['status']}') == status) {
        final time = '${entry['created_at'] ?? entry['updated_at'] ?? ''}';
        return formatServiceTime(time);
      }
    }
    if (status == 1) return formatServiceTime(_text('placed_at'));
    return '';
  }

  /// True once the booking reached [status]. Statuses aren't strictly
  /// increasing (8 "on the way" comes before 3 "in progress" for home
  /// cleaning), so the timeline is checked too.
  bool reached(int status) {
    if (isCancelled) return status == 1;
    if (this.status == status || this.status == 9) return true;
    return _timeline.any(
      (entry) => int.tryParse('${entry['status']}') == status,
    );
  }
}

class ServiceBookingLine {
  const ServiceBookingLine._(this._data);

  final Map<String, dynamic> _data;

  String get name => '${_data['name'] ?? ''}'.trim();
  String get unit => '${_data['unit'] ?? ''}'.trim();
  double get quantity => double.tryParse('${_data['quantity'] ?? ''}') ?? 1;
  double get price => double.tryParse('${_data['price'] ?? ''}') ?? 0;
  double get total => price * quantity;
}

/// '2026-10-31 14:05:00' → '31 Oct 2026,\n2:05 PM'; other text unchanged.
String formatServiceTime(String value) {
  final time = DateTime.tryParse(value);
  if (time == null) return value;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = time.isUtc ? time.toLocal() : time;
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${local.day} ${months[local.month - 1]} ${local.year},\n'
      '$hour:$minute $period';
}

/// Whole MRU amounts as the cards show them ("550 MRU").
String serviceMru(double amount) => 'mru'.trParams({
  'amount': amount == amount.roundToDouble()
      ? '${amount.round()}'
      : amount.toStringAsFixed(2),
});

/// Loads customer/service/booking for a detail screen. Returns null when
/// there is no numeric id; API failures throw ApiException.
Future<ServiceBookingDetail?> loadServiceBooking(int? orderId) async {
  if (orderId == null || orderId < 1) return null;
  if (!Get.isRegistered<ServiceRepository>()) return null;
  final data = await Get.find<ServiceRepository>().fetchBooking(
    orderId: orderId,
    language: apiLanguageCode(),
  );
  return ServiceBookingDetail.fromJson(data);
}

/// The cleaner's photo as a full URL, or ''.
String cleanerPhotoUrl(Map<String, dynamic> cleaner) {
  final url = '${cleaner['photo_url'] ?? ''}'.trim();
  if (url.isNotEmpty) return url;
  return ApiConstants.mediaUrl('${cleaner['photo'] ?? ''}') ?? '';
}
