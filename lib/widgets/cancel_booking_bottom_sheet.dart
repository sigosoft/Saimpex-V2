import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../views/booking_cancelled_success_screen.dart';

void showCancelBookingBottomSheet(
  BuildContext context, {
  VoidCallback? onConfirm,
  String? bookingId,
}) {
  int selectedReasonIndex = -1;
  const cancelReasons = [
    'Changed my mind',
    'Found a better price',
    'Wait time too long',
    'Other',
  ];

  const closeSize = 44.0;
  const closeGap = 12.0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: closeSize + closeGap),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF6F0),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0EA),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Text(
                        'Cancel Booking',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Are you sure you want to cancel this booking?',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please let us know why you need to cancel this booking. Your feedback helps us improve',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8C7D73),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          for (var i = 0; i < cancelReasons.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedReasonIndex = i;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cancelReasons[i],
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF1A1A1A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selectedReasonIndex == i
                                              ? const Color(0xFFFF5E00)
                                              : const Color(0xFFC4B8AF),
                                          width: selectedReasonIndex == i
                                              ? 1.8
                                              : 1.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: selectedReasonIndex == i
                                          ? Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFF5E00),
                                                shape: BoxShape.circle,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE6DE),
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'No',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF1A1A1A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Builder(
                                  builder: (context) {
                                    final canConfirm =
                                        selectedReasonIndex >= 0;
                                    return GestureDetector(
                                      onTap: () {
                                        if (!canConfirm) {
                                          Get.snackbar(
                                            '',
                                            'Please select a reason to cancel',
                                            titleText: const SizedBox.shrink(),
                                            messageText: Text(
                                              'Please select a reason to cancel',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            snackPosition: SnackPosition.TOP,
                                            backgroundColor:
                                                const Color(0xFF2C2520),
                                            margin: const EdgeInsets.all(16),
                                            borderRadius: 12,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.pop(context);
                                        onConfirm?.call();
                                        Get.to(
                                          () => BookingCancelledSuccessScreen(
                                            bookingId: bookingId,
                                          ),
                                        );
                                      },
                                      child: Opacity(
                                        opacity: canConfirm ? 1 : 0.45,
                                        child: Container(
                                          height: 52,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFF5E00),
                                                Color(0xFFFFAE00),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(28),
                                            boxShadow: canConfirm
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFFFF5E00)
                                                          .withValues(
                                                              alpha: 0.28),
                                                      blurRadius: 10,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Cancel Booking',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
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
                    width: closeSize,
                    height: closeSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5E00).withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFFF5E00),
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
