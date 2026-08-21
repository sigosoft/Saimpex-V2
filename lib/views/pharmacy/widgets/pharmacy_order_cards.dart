import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../chat_screen.dart';
import '../../track_order_screen.dart';
import '../quotation_detail_screen.dart';
import '../pharmacy_paid_order_detail_screen.dart';

class PharmacyQuotationReadyCard extends StatefulWidget {
  final String pharmacyName;
  final String orderId;
  final String amount;
  final Duration expiresIn;

  const PharmacyQuotationReadyCard({
    super.key,
    this.pharmacyName = 'Pharmacy Nasr',
    this.orderId = '#22789007',
    this.amount = '150 MRU',
    this.expiresIn = const Duration(hours: 2, minutes: 45, seconds: 9),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2430),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5E00),
                    borderRadius: BorderRadius.circular(7),
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
              borderRadius: BorderRadius.circular(12),
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
                  onTap: () {},
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
                          'image':
                              'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=150&auto=format&fit=crop',
                        },
                      ),
                    );
                  },
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5E00),
                      borderRadius: BorderRadius.circular(22),
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
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Get.to(
                () => QuotationDetailScreen(
                  orderId: widget.orderId,
                  pharmacyName: widget.pharmacyName,
                  expiresIn: _remaining,
                ),
              );
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Review & Pay',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.amount,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
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
  final bool showPrescription;
  final bool showTrack;
  final String? prescriptionName;

  const PharmacyActiveOrderCard({
    super.key,
    this.pharmacyName = 'Pharmacy Nasr',
    required this.statusText,
    required this.statusColor,
    required this.statusBgColor,
    required this.detailsText,
    required this.orderId,
    this.showPrescription = true,
    this.showTrack = true,
    this.prescriptionName = 'Prescription_Jun25.jpg',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
                  onTap: () {},
                ),
              ),
              if (showTrack) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.to(() => TrackOrderScreen(orderId: orderId));
                    },
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5E00)
                                .withValues(alpha: 0.22),
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
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () {
                Get.to(
                  () => PharmacyPaidOrderDetailScreen(
                    orderId: orderId,
                    isDelivery: statusText != 'SELF PICKUP',
                  ),
                );
              },
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
        borderRadius: BorderRadius.circular(10),
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
          borderRadius: BorderRadius.circular(22),
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
