import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../models/order_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/app_fonts.dart';
import '../../utils/toast_helper.dart';

/// When each slot starts: the pre-order is placed for that time.
const _slotStartHours = {
  '8-10 AM': 8,
  '10-12 PM': 10,
  '2-4 PM': 14,
  '4-6 PM': 16,
  '6-8 PM': 18,
  'Late night': 22,
};

/// Shown text for a slot value (the values stay English: they key the hours).
String _slotText(String slot) => switch (slot) {
  '8-10 AM' => 'orders_slot_8_10'.tr,
  '10-12 PM' => 'orders_slot_10_12'.tr,
  '2-4 PM' => 'orders_slot_2_4'.tr,
  '4-6 PM' => 'orders_slot_4_6'.tr,
  '6-8 PM' => 'orders_slot_6_8'.tr,
  'Late night' => 'orders_slot_late'.tr,
  _ => slot,
};

/// The customer picks a day and a slot inside the server's pre-order
/// window (`preorder/window`); returns the slot's start and its text
/// ("Sat, Nov 14 • 10 AM – 12 PM"), or null when closed. Used by the cart
/// and courier "Schedule for Later".
///
/// [titleKey] / [subtitleKey] name what is scheduled (delivery by default;
/// courier passes its pickup texts).
Future<({DateTime time, String text})?> showPreorderSlotSheet(
  BuildContext context, {
  String titleKey = 'preorder_sheet_title',
  String subtitleKey = 'preorder_sheet_subtitle',
}) async {
  // Only times inside the server's pre-order window can be picked.
  final ({DateTime earliest, DateTime latest}) window;
  try {
    window = await Get.find<OrderRepository>().preorderWindow(
      apiLanguageCode(),
    );
  } on ApiException catch (error) {
    showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    return null;
  }
  if (!context.mounted) return null;
  final firstDay = DateTime(
    window.earliest.year,
    window.earliest.month,
    window.earliest.day,
  );
  final lastDay = DateTime(
    window.latest.year,
    window.latest.month,
    window.latest.day,
  );
  final dates = <DateTime>[
    for (
      var day = firstDay;
      !day.isAfter(lastDay);
      day = DateTime(day.year, day.month, day.day + 1)
    )
      day,
  ];
  DateTime slotStart(DateTime day, String slot) =>
      DateTime(day.year, day.month, day.day, _slotStartHours[slot]!);
  bool slotOpen(DateTime day, String slot) {
    final start = slotStart(day, slot);
    return !start.isBefore(window.earliest) && !start.isAfter(window.latest);
  }

  DateTime selectedDate = dates.first;
  String? selectedTimeSlot;

  // Translation keys, shown with .tr.
  const months = [
    'orders_month_jan',
    'orders_month_feb',
    'orders_month_mar',
    'orders_month_apr',
    'orders_month_may',
    'orders_month_jun',
    'orders_month_jul',
    'orders_month_aug',
    'orders_month_sep',
    'orders_month_oct',
    'orders_month_nov',
    'orders_month_dec',
  ];
  const weekdays = [
    'orders_day_mon',
    'orders_day_tue',
    'orders_day_wed',
    'orders_day_thu',
    'orders_day_fri',
    'orders_day_sat',
    'orders_day_sun',
  ];
  const timeSlots = [
    '8-10 AM',
    '10-12 PM',
    '2-4 PM',
    '4-6 PM',
    '6-8 PM',
    'Late night',
  ];

  return showModalBottomSheet<({DateTime time, String text})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPad = MediaQuery.paddingOf(context).bottom;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 56),
                height: MediaQuery.of(context).size.height * 0.72,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF3EC), Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6F1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFD7C2),
                              ),
                            ),
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFFFF5216),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titleKey.tr,
                                  style: AppFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitleKey.tr,
                                  style: AppFonts.outfit(
                                    color: const Color(0xFFA59A94),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFFEAD8C9), height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'preorder_select_date'.tr,
                              style: AppFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 86,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: dates.length,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final date = dates[index];
                                  final isSelected =
                                      selectedDate.year == date.year &&
                                      selectedDate.month == date.month &&
                                      selectedDate.day == date.day;
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        selectedDate = date;
                                        final slot = selectedTimeSlot;
                                        if (slot != null &&
                                            !slotOpen(date, slot)) {
                                          selectedTimeSlot = null;
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: 62,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFFF5216)
                                              : const Color(0xFFEAD8C9),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            months[date.month - 1].tr,
                                            style: AppFonts.outfit(
                                              color: isSelected
                                                  ? const Color(0xFFFF5216)
                                                  : const Color(0xFFA59A94),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${date.day}',
                                            style: AppFonts.outfit(
                                              color: const Color(0xFF2C2520),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            weekdays[date.weekday - 1].tr,
                                            style: AppFonts.outfit(
                                              color: isSelected
                                                  ? const Color(0xFFFF5216)
                                                  : const Color(0xFFA59A94),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'preorder_time_slot'.tr,
                              style: AppFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 3.4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 10,
                              children: timeSlots.map((slot) {
                                final isSelected = selectedTimeSlot == slot;
                                final open = slotOpen(selectedDate, slot);
                                return GestureDetector(
                                  onTap: () {
                                    if (!open) return;
                                    setModalState(
                                      () => selectedTimeSlot = slot,
                                    );
                                  },
                                  child: Opacity(
                                    opacity: open ? 1 : 0.35,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFFF5216)
                                              : const Color(0xFFE6E0DB),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            color: Color(0xFFFF5216),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _slotText(slot),
                                              overflow: TextOverflow.ellipsis,
                                              style: AppFonts.outfit(
                                                color: const Color(0xFFFF5216),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPad),
                      child: GestureDetector(
                        onTap: () {
                          final slot = selectedTimeSlot;
                          if (slot == null || !slotOpen(selectedDate, slot)) {
                            showAppToast(
                              'preorder_choose_slot'.tr,
                              backgroundColor: const Color(0xFFEF4444),
                            );
                            return;
                          }
                          Navigator.pop(context, (
                            time: slotStart(selectedDate, slot),
                            text:
                                '${preorderDayText(selectedDate)} • ${_slotText(slot)}',
                          ));
                        },
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5216), Color(0xFFFFAE00)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF5216,
                                ).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'orders_continue'.tr,
                            style: AppFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFFF5216),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
/// The picked day in the app language: "Sat, Nov 14" in English, the day
/// first in French and Arabic ("sam. 14 nov.", "السبت 14 نوفمبر"); it read
/// "Sam, NOV. 14" in French.
String preorderDayText(DateTime day) {
  const weekdays = [
    'orders_day_mon',
    'orders_day_tue',
    'orders_day_wed',
    'orders_day_thu',
    'orders_day_fri',
    'orders_day_sat',
    'orders_day_sun',
  ];
  final weekday = weekdays[day.weekday - 1].tr;
  final month = 'svc_month_${day.month}'.tr;
  if (apiLanguageCode() == 'en') return '$weekday, $month ${day.day}';
  return '\u2066$weekday ${day.day} $month\u2069';
}
