import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../chat_screen.dart';
import 'prescription_checkout_screen.dart';

class QuotationDetailScreen extends StatefulWidget {
  final String orderId;
  final String pharmacyName;
  final Duration expiresIn;

  const QuotationDetailScreen({
    super.key,
    this.orderId = '#22789007',
    this.pharmacyName = 'Pharmacy Nasr',
    this.expiresIn = const Duration(hours: 2, minutes: 45, seconds: 9),
  });

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFAF6F0),
            Color(0xFFFFEEE5),
            Color(0xFFFFDDCF),
          ],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD4B8),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFFFF5E00),
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Order ${widget.orderId}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPharmacyCard(),
              const SizedBox(height: 12),
              _buildExpiryBanner(),
              const SizedBox(height: 12),
              _buildPrescriptionCard(),
              const SizedBox(height: 20),
              Text(
                'Medicines In Your Quotation',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildAvailableItemsCard(),
              const SizedBox(height: 12),
              _buildAlternativeCard(),
              const SizedBox(height: 20),
              Text(
                'Order Status',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildOrderStatusCard(),
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 12),
              _buildPayButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPharmacyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pharmacyName,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Delivery • Prescription • ${widget.orderId}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF7E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'QUOTATION READY',
              style: GoogleFonts.outfit(
                color: const Color(0xFF00A854),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(14),
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
    );
  }

  Widget _buildPrescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              color: Colors.white,
              alignment: Alignment.center,
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFFA59A94),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescription_Jun25.jpg',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
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
    );
  }

  Widget _buildAvailableItemsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _medicineRow(
            title: 'Paracetamol 500 mg',
            meta: 'Qty: 2 • Unit Price: 25 MRU',
            price: '50 MRU',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEFE8E1)),
          ),
          _medicineRow(
            title: 'Baby Diapers',
            meta: 'Qty: 2 • Unit Price: 25 MRU',
            price: '50 MRU',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEFE8E1)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '100 MRU',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicineRow({
    required String title,
    required String meta,
    required String price,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                meta,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Amoxicillin 500 mg',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: const Color(0xFFA59A94),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '• Out Of Stock',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFE53935),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              const Divider(height: 1, thickness: 1, color: Color(0xFFEFE8E1)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0EC),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: Color(0xFF8A7F77),
                  size: 16,
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Suggested Alternative',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amoxiclav 625 mg',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Qty: 2 • Unit Price: 25 MRU',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '50 MRU',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '50 MRU',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard() {
    const steps = [
      _StatusStep(
        label: 'Prescription\nSent',
        time: '22 Oct 2023,\n10:30 AM',
        done: true,
        icon: Icons.check_rounded,
      ),
      _StatusStep(
        label: 'Under\nReview',
        time: '22 Oct 2023,\n10:35 AM',
        done: true,
        icon: Icons.description_outlined,
      ),
      _StatusStep(
        label: 'Quotation\nReady',
        time: '22 Oct 2023,\n10:40 AM',
        done: true,
        icon: Icons.request_quote_outlined,
      ),
      _StatusStep(
        label: 'Review\n& Pay',
        time: '',
        done: false,
        icon: Icons.check_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const circle = 34.0;
          final usable = constraints.maxWidth - circle;
          final segment = usable / 3;

          return Column(
            children: [
              SizedBox(
                height: circle,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: circle / 2,
                      right: circle / 2,
                      child: Row(
                        children: List.generate(3, (i) {
                          final active = i < 2;
                          return Container(
                            width: segment,
                            height: 3,
                            color: active
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFFE5DDD4),
                          );
                        }),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: steps.map((step) {
                        return Container(
                          width: circle,
                          height: circle,
                          decoration: BoxDecoration(
                            color: step.done
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFFEFE8E1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step.icon,
                            color: step.done
                                ? Colors.white
                                : const Color(0xFFB0A59C),
                            size: 18,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: steps.map((step) {
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          step.label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        if (step.time.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            step.time,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUOTATION SUMMARY',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Item total',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '150 MRU',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFF3A434E)),
          ),
          Row(
            children: [
              Text(
                'To Pay',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '150 MRU',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFEA),
                borderRadius: BorderRadius.circular(23),
              ),
              alignment: Alignment.center,
              child: Text(
                'Decline Quotation',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5E00),
                borderRadius: BorderRadius.circular(23),
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
    );
  }

  Widget _buildPayButton() {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => PrescriptionCheckoutScreen(
            pharmacyName: widget.pharmacyName,
            itemTotal: 150,
          ),
        );
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.3),
              blurRadius: 12,
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
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '150 MRU',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStep {
  final String label;
  final String time;
  final bool done;
  final IconData icon;

  const _StatusStep({
    required this.label,
    required this.time,
    required this.done,
    required this.icon,
  });
}
