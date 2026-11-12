import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/service_booking_draft.dart';
import '../../core/network/api_message.dart';
import '../../models/service_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/app_fonts.dart';

/// One bookable time window of a provider on a day.
class ServiceSlot {
  const ServiceSlot({required this.label, required this.available});

  /// "10-12 PM" (the form the service carts and [formatServiceSlotLabel]
  /// read: one AM/PM suffix for the whole window).
  final String label;

  /// False when the provider is full or the time has passed.
  final bool available;
}

/// "10-12 PM" for 10:00–12:00, "8:30-10 AM" for 8:30–10:00: the slot label
/// the service screens expect, built from the server's start and end.
String serviceSlotLabel(DateTime start, DateTime end) {
  String part(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return time.minute == 0
        ? '$hour'
        : '$hour:${time.minute.toString().padLeft(2, '0')}';
  }

  return '${part(start)}-${part(end)} ${end.hour >= 12 ? 'PM' : 'AM'}';
}

/// The day's slots of the provider being booked (ServiceBookingDraft),
/// from `customer/serviceSlots`: the provider's own windows, which are full,
/// and whether it's closed that day. The slot sheets used to offer four
/// fixed windows on every day, also past ones and on closed days.
mixin ServiceSlotsMixin<T extends StatefulWidget> on State<T> {
  List<ServiceSlot> slots = const [];
  bool slotsLoading = false;
  bool dayClosed = false;
  String? slotsError;
  int _request = 0;
  DateTime? _slotsDate;

  /// Call from build with the selected day: loads its slots once per day.
  void ensureSlotsFor(DateTime date) {
    if (_slotsDate == date) return;
    _slotsDate = date;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) loadSlots(date);
    });
  }

  Future<void> loadSlots(DateTime date) async {
    final request = ++_request;
    final vendorId = ServiceBookingDraft.vendorId;
    setState(() {
      slots = const [];
      slotsLoading = true;
      dayClosed = false;
      slotsError = null;
    });
    if (vendorId == null || !Get.isRegistered<ServiceRepository>()) {
      setState(() {
        slotsLoading = false;
        slotsError = 'svc_choose_service_again'.tr;
      });
      return;
    }
    String two(int value) => value.toString().padLeft(2, '0');
    try {
      final raw = await Get.find<ServiceRepository>().fetchSlots(
        vendorId: vendorId,
        language: apiLanguageCode(),
        date: '${date.year}-${two(date.month)}-${two(date.day)}',
      );
      if (!mounted || request != _request) return;
      final data = asJsonMap(raw) ?? const <String, dynamic>{};
      final now = DateTime.now();
      final loaded = <ServiceSlot>[];
      final list = data['slots'];
      if (list is List) {
        for (final entry in list) {
          final row = asJsonMap(entry);
          final start = DateTime.tryParse('${row?['start'] ?? ''}');
          final end = DateTime.tryParse('${row?['end'] ?? ''}');
          if (row == null || start == null || end == null) continue;
          loaded.add(
            ServiceSlot(
              label: serviceSlotLabel(start, end),
              available: row['available'] != false && start.isAfter(now),
            ),
          );
        }
      }
      setState(() {
        slots = loaded;
        dayClosed = data['closed'] == true;
        slotsLoading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        slotsLoading = false;
        slotsError = 'svc_slots_load_failed'.tr;
      });
    }
  }

  /// The slot chips two per row, or why there are none.
  Widget buildSlotGrid(Widget Function(int index) chip) {
    if (slotsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFFFF5216),
            ),
          ),
        ),
      );
    }
    final message =
        slotsError ??
        (dayClosed
            ? 'svc_slots_closed_day'.tr
            : slots.every((slot) => !slot.available)
            ? 'svc_slots_none_left'.tr
            : null);
    return Column(
      children: [
        for (var i = 0; i < slots.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: chip(i)),
              const SizedBox(width: 10),
              Expanded(
                child: i + 1 < slots.length
                    ? chip(i + 1)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
        if (message != null)
          Padding(
            padding: EdgeInsets.only(top: slots.isEmpty ? 4 : 12),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.outfit(
                color: const Color(0xFF8C7D73),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
