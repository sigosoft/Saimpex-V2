import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/network/api_exception.dart';
import '../models/order_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../views/order_cancelled_success_screen.dart';

/// [orderId] is the order code shown to the customer; [apiOrderId] is the
/// numeric id the cancel API needs. Without [onConfirm] the sheet cancels
/// [apiOrderId] itself. The success screen only opens once the cancel succeeds.
void showCancelOrderBottomSheet(
  BuildContext context, {
  Future<bool> Function()? onConfirm,
  String? orderId,
  int? apiOrderId,
  VoidCallback? onCancelled,
}) {
  int selectedReasonIndex = -1;
  var cancelling = false;
  const cancelReasons = [
    'Changed my mind',
    'Found a better price',
    'Wait time too long',
    'Other',
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE8DC),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFFF5E00),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDF9F0),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 251, 249, 248),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: Text(
                          'Cancel Order',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5216),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF4F0E8),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + bottomPad),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Are you sure you want to cancel this order?',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Please let us know why you need to cancel this order. Your feedback helps us improve',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF9A8A84),
                              fontSize: 12.5,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cancelReasons.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final isSelected = selectedReasonIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedReasonIndex = index;
                                });
                              },
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cancelReasons[index],
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF626465),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFFF5E00)
                                              : const Color(0xFF8A7264),
                                          width: 1.4,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: isSelected
                                          ? Container(
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
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 238, 233, 224),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF1B1B1B),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 6,
                              child: Builder(
                                builder: (context) {
                                  final canConfirm = selectedReasonIndex >= 0;
                                  return GestureDetector(
                                    onTap: () async {
                                      if (cancelling) return;
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
                                          duration: const Duration(seconds: 2),
                                        );
                                        return;
                                      }
                                      setModalState(() => cancelling = true);
                                      final cancelled = await (onConfirm ??
                                          () => _cancelOrderById(apiOrderId))();
                                      if (!context.mounted) return;
                                      setModalState(() => cancelling = false);
                                      if (!cancelled) return;
                                      Navigator.pop(context);
                                      onCancelled?.call();
                                      Get.to(
                                        () => OrderCancelledSuccessScreen(
                                          orderId: orderId,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF5216),
                                            Color(0xFFFFAE00),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        cancelling
                                            ? 'Cancelling...'
                                            : 'Cancel Order',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
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
              ],
            ),
          );
        },
      );
    },
  );
}

Future<bool> _cancelOrderById(int? orderId) async {
  if (orderId == null || orderId < 1 || !Get.isRegistered<OrderRepository>()) {
    showAppToast(
      'This order cannot be cancelled right now',
      backgroundColor: const Color(0xFFEF4444),
    );
    return false;
  }
  try {
    final message = await Get.find<OrderRepository>().cancelOrder(
      orderId: orderId,
      language: apiLanguageCode(),
    );
    showAppToast(
      message.isEmpty ? 'Order cancelled' : message,
      backgroundColor: const Color(0xFFFF5E00),
    );
    return true;
  } on ApiException catch (error) {
    showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    return false;
  }
}
