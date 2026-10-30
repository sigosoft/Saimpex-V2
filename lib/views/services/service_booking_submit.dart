import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
Future<Map<String, dynamic>?> placeServiceBooking({
  required DateTime slotDate,
  required String slotLabel,
  required bool onlinePayment,
  List<Map<String, dynamic>> spaces = const [],
  List<Map<String, dynamic>> addons = const [],
  List<Map<String, dynamic>> garments = const [],
  List<Map<String, dynamic>> vehicles = const [],
  String? productSupply,
  num? quantity,
  String place = 'home',
  String notes = '',
}) async {
  final vertical = ServiceBookingDraft.vertical;
  final vendorId = ServiceBookingDraft.vendorId;
  final itemId = ServiceBookingDraft.serviceItemId;
  if (vertical == null ||
      vendorId == null ||
      itemId == null ||
      !Get.isRegistered<ServiceRepository>()) {
    showAppToast(
      'Please choose a service from the provider again',
      backgroundColor: const Color(0xFFEF4444),
    );
    return null;
  }

  final window = serviceSlotWindow(slotDate, slotLabel);
  final address = SelectLocationController.selectedSubtitle.trim().isEmpty
      ? SelectLocationController.deliveryLabel.value
      : SelectLocationController.selectedSubtitle;
  final request = <String, dynamic>{
    'vertical': vertical,
    'vendor_id': vendorId,
    'service_item_id': itemId,
    'place': place,
    'address': address,
    'latitude': SelectLocationController.selectedLatitude,
    'longitude': SelectLocationController.selectedLongitude,
    'scheduled_for': ?window?.$1,
    'slot_end': ?window?.$2,
    'slot_label': slotLabel,
    'payment_type': onlinePayment ? '2' : '1',
    if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    'quantity': ?quantity,
    'product_supply': ?productSupply,
  };
  final matchedSpaces = _catalogRows(spaces, 'spaces');
  if (matchedSpaces.isNotEmpty) request['spaces'] = matchedSpaces;
  final matchedAddons = _catalogRows(addons, 'addons');
  if (matchedAddons.isNotEmpty) request['addons'] = matchedAddons;
  final matchedGarments = _catalogRows(garments, 'garments');
  if (matchedGarments.isNotEmpty) request['garments'] = matchedGarments;
  // Car wash vehicle types are listed as the item's spaces.
  final matchedVehicles = _catalogRows(vehicles, 'spaces');
  if (matchedVehicles.isNotEmpty) request['vehicles'] = matchedVehicles;

  try {
    final result = await Get.find<ServiceRepository>().book(
      request: request,
      language: apiLanguageCode(),
    );
    showAppToast(
      result.message.isEmpty ? 'Booking created' : result.message,
      backgroundColor: const Color(0xFFFF5E00),
    );
    return result.booking;
  } on ApiException catch (error) {
    showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    return null;
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
