import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../models/order_repository.dart';
import '../../../utils/api_language.dart';
import '../../../utils/toast_helper.dart';

import '../../chat_screen.dart';
import '../../rating_reviews_screen.dart';
import '../../../widgets/cancel_order_bottom_sheet.dart';
import '../pharmacy_track_order_screen.dart';
import '../quotation_detail_screen.dart';
import '../pharmacy_paid_order_detail_screen.dart';
import '../pharmacy_item_order_detail_screen.dart';

class PharmacyQuotationReadyCard extends StatefulWidget {
  final String pharmacyName;
  final String orderId;
  final String amount;
  final Duration expiresIn;
  final int? prescriptionId;
  // Called after the quotation is declined, so the list can reload.
  final VoidCallback? onChanged;

  const PharmacyQuotationReadyCard({
    super.key,
    required this.pharmacyName,
    required this.orderId,
    required this.amount,
    required this.expiresIn,
    this.prescriptionId,
    this.onChanged,
  });

  @override
  State<PharmacyQuotationReadyCard> createState() =>
      _PharmacyQuotationReadyCardState();
}

class _PharmacyQuotationReadyCardState
    extends State<PharmacyQuotationReadyCard> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresIn;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.pharmacyName,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      text: 'QUOTATION READY',
                      color: const Color(0xFF00A854),
                      bgColor: const Color(0xFFDDF7E8),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Prescription • ${widget.orderId}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2430),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E00),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.alarm_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Quote Expires in:',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timerText,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4EC),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quotation Summary',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Item total',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8A7F77),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.amount,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SoftButton(
                        label: 'Decline Quotation',
                        outlined: true,
                        onTap: () async {
                          final id = widget.prescriptionId;
                          if (id == null) return;
                          final declined = await declineQuotation(context, id);
                          if (declined) widget.onChanged?.call();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.to(
                            () => ChatScreen(
                              restaurant: {
                                'title': widget.pharmacyName,
                                'image': '',
                              },
                            ),
                          );
                        },
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5E00),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Chat with Pharmacy',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final declined = await Get.to<bool>(
                () => QuotationDetailScreen(
                  orderId: widget.orderId,
                  pharmacyName: widget.pharmacyName,
                  expiresIn: _remaining,
                  prescriptionId: widget.prescriptionId,
                  amount: widget.amount,
                ),
              );
              if (declined == true) widget.onChanged?.call();
            },
            child: Container(
              width: double.infinity,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Review & Pay',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.amount,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PharmacyActiveOrderCard extends StatelessWidget {
  final String pharmacyName;
  final String statusText;
  final Color statusColor;
  final Color statusBgColor;
  final String detailsText;
  final String orderId;
  final int? apiOrderId;
  final bool showPrescription;
  final bool showTrack;
  final String? prescriptionName;
  final int? vendorId;

  const PharmacyActiveOrderCard({
    super.key,
    this.pharmacyName = 'Pharmacy Nasr',
    required this.statusText,
    required this.statusColor,
    required this.statusBgColor,
    required this.detailsText,
    required this.orderId,
    this.vendorId,
    this.apiOrderId,
    this.showPrescription = false,
    this.showTrack = true,
    this.prescriptionName = 'Prescription_Jun25.jpg',
  });

  void _openOrderDetails() {
    final id = apiOrderId;
    if (id != null && id > 0 && Get.isRegistered<OrderRepository>()) {
      final orders = Get.find<OrderRepository>();
      final language = apiLanguageCode();
      orders
          .orderDetails(orderId: id, language: language)
          .then((_) {
            return orders.rating(orderId: id, language: language);
          })
          .catchError((Object error) {
            if (error is ApiException) {
              showAppToast(
                error.message,
                backgroundColor: const Color(0xFFEF4444),
              );
            }
            return <String, dynamic>{};
          });
    }
    if (showPrescription) {
      Get.to(
        () => PharmacyPaidOrderDetailScreen(
          orderId: orderId,
          apiOrderId: apiOrderId,
          isDelivery: statusText != 'SELF PICKUP',
        ),
      );
    } else {
      Get.to(
        () => PharmacyItemOrderDetailScreen(
          orderId: orderId,
          apiOrderId: apiOrderId,
          isDelivery: statusText != 'SELF PICKUP',
        ),
      );
    }
  }

  Future<void> _rateOrder(BuildContext context) async {
    final id = apiOrderId;
    if (id == null || id < 1 || !Get.isRegistered<OrderRepository>()) return;
    final orders = Get.find<OrderRepository>();
    final language = apiLanguageCode();
    try {
      await orders.rating(orderId: id, language: language);
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      return;
    }
    if (!context.mounted) return;
    var vendorRating = 5;
    var driverRating = 5;
    final vendorComment = TextEditingController();
    final driverComment = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget stars(int value, ValueChanged<int> onPick) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => onPick(star)),
                    icon: Icon(
                      star <= value ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFF5E00),
                    ),
                  );
                }),
              );
            }

            return AlertDialog(
              title: Text('Rate order', style: GoogleFonts.outfit()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pharmacy', style: GoogleFonts.outfit()),
                  stars(vendorRating, (value) => vendorRating = value),
                  TextField(
                    controller: vendorComment,
                    decoration: const InputDecoration(hintText: 'Comment'),
                  ),
                  const SizedBox(height: 8),
                  Text('Driver', style: GoogleFonts.outfit()),
                  stars(driverRating, (value) => driverRating = value),
                  TextField(
                    controller: driverComment,
                    decoration: const InputDecoration(hintText: 'Comment'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    final vendorText = vendorComment.text.trim();
    final driverText = driverComment.text.trim();
    vendorComment.dispose();
    driverComment.dispose();
    if (submitted != true) return;
    try {
      final message = await orders.submitRating(
        orderId: id,
        vendorRating: vendorRating,
        driverRating: driverRating,
        vendorComment: vendorText,
        driverComment: driverText,
        language: language,
      );
      showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      return;
    }
    final vendor = vendorId;
    if (vendor == null || vendor < 1 || !context.mounted) return;
    Get.to(
      () => RatingReviewsScreen(
        target: ReviewTarget(
          type: 'provider',
          expectedSubjectType: 'pharmacy',
          title: pharmacyName,
          vendorId: vendor,
          vendorType: 4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openOrderDetails,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pharmacyName,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusBadge(
                  text: statusText,
                  color: statusColor,
                  bgColor: statusBgColor,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              detailsText,
              style: GoogleFonts.outfit(
                color: const Color(0xFFA59A94),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showPrescription) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0EC),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 42,
                        height: 42,
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.description_outlined,
                          color: Color(0xFFA59A94),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prescriptionName ?? 'Prescription.jpg',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                'View Full Prescription',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.open_in_new_rounded,
                                color: Color(0xFFFF5E00),
                                size: 13,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SoftButton(
                    label: 'Cancel',
                    onTap: () {
                      showCancelOrderBottomSheet(
                        context,
                        orderId: orderId,
                        apiOrderId: apiOrderId,
                      );
                    },
                  ),
                ),
                if (showTrack) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.to(
                          () => PharmacyTrackOrderScreen(
                            orderId: orderId,
                            apiOrderId: apiOrderId,
                          ),
                        );
                      },
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF5E00,
                              ).withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Track Order',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (statusText.toUpperCase().contains('DELIVER')) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _rateOrder(context),
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFFF5E00)),
                  ),
                  child: Text(
                    'Rate Order',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _openOrderDetails,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Order Status & Details',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF5E00),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color bgColor;

  const _StatusBadge({
    required this.text,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const _SoftButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : const Color(0xFFF3EFEA),
          borderRadius: BorderRadius.circular(30),
          border: outlined
              ? Border.all(color: const Color(0xFFE5DDD4), width: 1)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
