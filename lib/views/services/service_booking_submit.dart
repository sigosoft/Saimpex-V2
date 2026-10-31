import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/select_location_controller.dart';
import '../../controllers/service_booking_draft.dart';
import '../../core/network/api_exception.dart';
import '../../models/service_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';

/// Places the booking for the service picked on the provider screen
/// ([ServiceBookingDraft]) through customer/service/book. Returns the created
/// booking, or null after showing why it failed.
///
/// [spaces], [addons] and [garments] are `{name, quantity}` rows from the
/// cart; only names in the provider's catalog are sent, because the API
/// rejects any others and prices the booking from its own catalog.
///
/// [shownTotal] is the total the cart showed. The booking is charged at the
/// server's price, so when customer/service/quote comes back different the
/// customer confirms that price before anything is booked.
Future<Map<String, dynamic>?> placeServiceBooking({
  required DateTime slotDate,
  required String slotLabel,

  /// paymentTypeWallet, paymentTypeOnline or paymentTypeCash (utils/wallet_balance.dart).
  required String paymentType,
  num? shownTotal,
  List<Map<String, dynamic>> spaces = const [],
  List<Map<String, dynamic>> addons = const [],
  List<Map<String, dynamic>> garments = const [],
  List<Map<String, dynamic>> vehicles = const [],
  String? productSupply,
  String propertyType = '',
  num? quantity,
  String place = 'home',
  String notes = '',
  // Where the provider goes when it isn't the delivery location (car wash
  // "another address"); null uses the selected delivery location.
  String? address,
  double? latitude,
  double? longitude,
}) async {
  final request = _bookingRequest(
    slotDate: slotDate,
    slotLabel: slotLabel,
    paymentType: paymentType,
    spaces: spaces,
    addons: addons,
    garments: garments,
    vehicles: vehicles,
    productSupply: productSupply,
    propertyType: propertyType,
    quantity: quantity,
    place: place,
    notes: notes,
    address: address,
    latitude: latitude,
    longitude: longitude,
  );
  if (request == null) {
    showAppToast(
      'svc_choose_service_again'.tr,
      backgroundColor: const Color(0xFFEF4444),
    );
    return null;
  }

  if (shownTotal != null && !await _confirmServerPrice(request, shownTotal)) {
    return null;
  }

  try {
    final result = await Get.find<ServiceRepository>().book(
      request: request,
      language: apiLanguageCode(),
    );
    showAppToast(
      result.message.isEmpty ? 'svc_booking_created'.tr : result.message,
      backgroundColor: const Color(0xFFFF5E00),
    );
    return result.booking;
  } on ApiException catch (error) {
    showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    return null;
  }
}

/// The server's price for the same booking [placeServiceBooking] would place
/// (customer/service/quote): `subtotal`, `tax`, `tax_percent`, `total`,
/// `lines`. Throws [ApiException] when the server can't price it; null when
/// no service is picked.
Future<Map<String, dynamic>?> quoteServiceBooking({
  required DateTime slotDate,
  required String slotLabel,
  required String paymentType,
  List<Map<String, dynamic>> spaces = const [],
  List<Map<String, dynamic>> addons = const [],
  List<Map<String, dynamic>> garments = const [],
  List<Map<String, dynamic>> vehicles = const [],
  String? productSupply,
  String propertyType = '',
  num? quantity,
  String place = 'home',
  String? address,
  double? latitude,
  double? longitude,
}) async {
  final request = _bookingRequest(
    slotDate: slotDate,
    slotLabel: slotLabel,
    paymentType: paymentType,
    spaces: spaces,
    addons: addons,
    garments: garments,
    vehicles: vehicles,
    productSupply: productSupply,
    propertyType: propertyType,
    quantity: quantity,
    place: place,
    address: address,
    latitude: latitude,
    longitude: longitude,
  );
  if (request == null) return null;
  return Get.find<ServiceRepository>().quote(
    request: request,
    language: apiLanguageCode(),
  );
}

/// The service/book (and service/quote) body for the picked service, or null
/// when no service is picked.
Map<String, dynamic>? _bookingRequest({
  required DateTime slotDate,
  required String slotLabel,
  required String paymentType,
  List<Map<String, dynamic>> spaces = const [],
  List<Map<String, dynamic>> addons = const [],
  List<Map<String, dynamic>> garments = const [],
  List<Map<String, dynamic>> vehicles = const [],
  String? productSupply,
  String propertyType = '',
  num? quantity,
  String place = 'home',
  String notes = '',
  String? address,
  double? latitude,
  double? longitude,
}) {
  final vertical = ServiceBookingDraft.vertical;
  final vendorId = ServiceBookingDraft.vendorId;
  final itemId = ServiceBookingDraft.serviceItemId;
  if (vertical == null ||
      vendorId == null ||
      itemId == null ||
      !Get.isRegistered<ServiceRepository>()) {
    return null;
  }

  final window = serviceSlotWindow(slotDate, slotLabel);
  final bookingAddress =
      address ??
      (SelectLocationController.selectedSubtitle.trim().isEmpty
          ? SelectLocationController.deliveryLabel.value
          : SelectLocationController.selectedSubtitle);
  final request = <String, dynamic>{
    'vertical': vertical,
    'vendor_id': vendorId,
    'service_item_id': itemId,
    'place': place,
    'address': bookingAddress,
    'latitude': latitude ?? SelectLocationController.selectedLatitude,
    'longitude': longitude ?? SelectLocationController.selectedLongitude,
    'scheduled_for': ?window?.$1,
    'slot_end': ?window?.$2,
    'slot_label': slotLabel,
    'payment_type': paymentType,
    if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    'quantity': ?quantity,
    'product_supply': ?productSupply,
    if (propertyType.trim().isNotEmpty) 'property_type': propertyType.trim(),
  };
  final matchedSpaces = _catalogRows(spaces, 'spaces');
  if (matchedSpaces.isNotEmpty) request['spaces'] = matchedSpaces;
  final matchedAddons = _catalogRows(addons, 'addons');
  if (matchedAddons.isNotEmpty) request['addons'] = matchedAddons;
  final matchedGarments = _catalogRows(garments, 'garments');
  if (matchedGarments.isNotEmpty) request['garments'] = matchedGarments;
  // Car wash vehicle types are listed as the item's spaces. Each vehicle can
  // carry its own add-ons, which are matched against the catalog too.
  final matchedVehicles = [
    for (final vehicle in _catalogRows(vehicles, 'spaces'))
      {
        ...vehicle,
        'addons': _catalogRows([
          for (final addon in (vehicle['addons'] as List? ?? const []))
            if (addon is Map) Map<String, dynamic>.from(addon),
        ], 'addons'),
      },
  ];
  if (matchedVehicles.isNotEmpty) request['vehicles'] = matchedVehicles;
  return request;
}

/// Prices [request] with customer/service/quote. True when the server's total
/// matches [shownTotal] or the customer accepts the server's price.
Future<bool> _confirmServerPrice(
  Map<String, dynamic> request,
  num shownTotal,
) async {
  final Map<String, dynamic> quote;
  try {
    quote = await Get.find<ServiceRepository>().quote(
      request: request,
      language: apiLanguageCode(),
    );
  } on ApiException catch (error) {
    showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    return false;
  }
  final total = double.tryParse('${quote['total'] ?? ''}');
  if (total == null || total.round() == shownTotal.round()) return true;
  final lines = [
    for (final line in (quote['lines'] as List? ?? const []))
      if (line is Map) Map<String, dynamic>.from(line),
  ];
  final accepted = await Get.dialog<bool>(
    _ServerPriceDialog(lines: lines, total: total),
  );
  return accepted == true;
}

/// The provider's price for the booking, line by line, to accept or go back.
class _ServerPriceDialog extends StatelessWidget {
  const _ServerPriceDialog({required this.lines, required this.total});

  final List<Map<String, dynamic>> lines;
  final double total;

  static String _mru(num value) =>
      'mru'.trParams({'amount': '${value.round()}'});

  @override
  Widget build(BuildContext context) {
    TextStyle style(double size, FontWeight weight, Color color) =>
        GoogleFonts.outfit(fontSize: size, fontWeight: weight, color: color);
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'svc_providers_price'.tr,
        style: style(17, FontWeight.w800, const Color(0xFF2C2520)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'svc_providers_price_body'.tr,
            style: style(12.5, FontWeight.w500, const Color(0xFF7A6A60)),
          ),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        '${line['name'] ?? ''}',
                        if ('${line['unit'] ?? ''}'.isNotEmpty)
                          '(${line['unit']})',
                        if ((num.tryParse('${line['quantity']}') ?? 1) > 1)
                          '×${line['quantity']}',
                      ].join(' '),
                      style: style(
                        13,
                        FontWeight.w500,
                        const Color(0xFF2C2520),
                      ),
                    ),
                  ),
                  Text(
                    _mru(
                      (num.tryParse('${line['price']}') ?? 0) *
                          (num.tryParse('${line['quantity']}') ?? 1),
                    ),
                    style: style(13, FontWeight.w700, const Color(0xFF2C2520)),
                  ),
                ],
              ),
            ),
          const Divider(height: 18, color: Color(0xFFEAD8C9)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'svc_total'.tr,
                  style: style(15, FontWeight.w800, const Color(0xFF2C2520)),
                ),
              ),
              Text(
                _mru(total),
                style: style(16, FontWeight.w800, const Color(0xFFFF5E00)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text(
            'svc_go_back'.tr,
            style: style(14, FontWeight.w700, const Color(0xFF7A6A60)),
          ),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text(
            'svc_book_at'.trParams({'amount': _mru(total)}),
            style: style(14, FontWeight.w800, const Color(0xFFFF5E00)),
          ),
        ),
      ],
    );
  }
}

/// Rows whose name is in the item's [catalogKey] list, renamed to the
/// catalog's spelling.
List<Map<String, dynamic>> _catalogRows(
  List<Map<String, dynamic>> rows,
  String catalogKey,
) {
  final raw = ServiceBookingDraft.item[catalogKey];
  if (raw is! List || rows.isEmpty) return const [];
  final byName = <String, String>{};
  for (final entry in raw) {
    final name = entry is Map ? '${entry['name'] ?? ''}'.trim() : '$entry';
    if (name.isNotEmpty) byName[name.toLowerCase()] = name;
  }
  final matched = <Map<String, dynamic>>[];
  for (final row in rows) {
    final name = '${row['name'] ?? ''}'.trim().toLowerCase();
    final catalogName = byName[name];
    if (catalogName == null) continue;
    final quantity = row['quantity'];
    matched.add({
      ...row,
      'name': catalogName,
      if (quantity is num && quantity > 0) 'quantity': quantity,
    });
  }
  return matched;
}

/// Start and end of a slot label such as "10:00-12:00 PM" or "8-10 AM" on
/// [day], as "yyyy-MM-dd HH:mm:ss". Null when the label can't be read.
(String, String)? serviceSlotWindow(DateTime day, String label) {
  final match = RegExp(
    r'(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?\s*[-–]\s*(\d{1,2})(?::(\d{2}))?\s*(AM|PM)',
    caseSensitive: false,
  ).firstMatch(label);
  if (match == null) return null;
  final endMeridiem = match.group(6)!.toUpperCase();
  var startHour = int.parse(match.group(1)!);
  final startMinute = int.tryParse(match.group(2) ?? '') ?? 0;
  var endHour = int.parse(match.group(4)!);
  final endMinute = int.tryParse(match.group(5) ?? '') ?? 0;
  int to24(int hour, String meridiem) {
    if (meridiem == 'AM') return hour == 12 ? 0 : hour;
    return hour == 12 ? 12 : hour + 12;
  }

  endHour = to24(endHour, endMeridiem);
  // "10-12 PM" means 10 AM to noon: a start later than the end in the same
  // meridiem belongs to the morning.
  final startMeridiem = match.group(3)?.toUpperCase();
  if (startMeridiem != null) {
    startHour = to24(startHour, startMeridiem);
  } else {
    final asEnd = to24(startHour, endMeridiem);
    startHour = asEnd > endHour ? to24(startHour, 'AM') : asEnd;
  }
  String format(int hour, int minute) {
    final date = DateTime(day.year, day.month, day.day, hour, minute);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}:00';
  }

  return (format(startHour, startMinute), format(endHour, endMinute));
}

/// Display form of a slot label: "10:00-12:00 PM" → "10:00 AM - 12:00 PM".
/// One AM/PM suffix covers the whole range, so a start hour later than the
/// end (or any start before a 12 o'clock end) is in the morning.
String formatServiceSlotLabel(String label) {
  final match = RegExp(
    r'(\d{1,2})(?::(\d{2}))?\s*[-–]\s*(\d{1,2})(?::(\d{2}))?\s*(AM|PM)',
    caseSensitive: false,
  ).firstMatch(label);
  if (match == null) return label;
  final startHour = int.parse(match.group(1)!);
  final endHour = int.parse(match.group(3)!);
  final period = match.group(5)!.toUpperCase();
  final startIsMorning =
      period == 'PM' &&
      startHour != 12 &&
      (startHour > endHour || endHour == 12);
  final startPeriod = startIsMorning ? 'AM' : period;
  final startMinute = match.group(2) ?? '00';
  final endMinute = match.group(4) ?? '00';
  return '$startHour:$startMinute $startPeriod - $endHour:$endMinute $period';
}
