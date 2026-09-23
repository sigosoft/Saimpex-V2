import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_back_button.dart';

import '../../widgets/cancel_order_bottom_sheet.dart';
import 'pharmacy_track_order_screen.dart';

class PharmacyPaidOrderDetailScreen extends StatelessWidget {
  final String orderId;
  final bool isDelivery;
  final String pharmacyName;
  final String? prescriptionImageUrl;

  const PharmacyPaidOrderDetailScreen({
    super.key,
    this.orderId = '#22789007',
    this.isDelivery = true,
    this.pharmacyName = 'Pharmacy Nasr',
    this.prescriptionImageUrl,
  });

  static const _samplePrescription =
      'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=800&auto=format&fit=crop';

  @override
  Widget build(BuildContext context) {
    final imageUrl = prescriptionImageUrl ?? _samplePrescription;
    final displayId = orderId.startsWith('#') ? orderId : '#$orderId';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppBackButton(onTap: () => Navigator.pop(context),),
                  ),
                  Text(
                    'Order $displayId',
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
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrescriptionCard(imageUrl),
                  const SizedBox(height: 14),
                  _buildOrderStatusCard(),
                  const SizedBox(height: 18),
                  Text(
                    'Medicines In Your Quotation',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMedicineCard(
                    title: '1. Paracetamol 500 mg',
                    unit: 'Unit: 10 tablets x 50 MRU',
                    totalAmount: '500',
                  ),
                  const SizedBox(height: 10),
                  _buildMedicineCard(
                    title: '1. Paracetamol 650 mg',
                    unit: 'Unit: 10 tablets x 50 MRU',
                    totalAmount: '500',
                    availabilityBadge: '6 of 10 available',
                  ),
                  const SizedBox(height: 10),
                  _buildMedicineCard(
                    title: '1. Paracetamol 500 mg',
                    unit: '10 tablets × 50 MRU',
                    totalAmount: '500',
                    showSuggestedAlternative: true,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isDelivery ? 'Delivery Details' : 'Pickup Location',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isDelivery) ...[
                    _buildAddressCard(),
                    const SizedBox(height: 10),
                    _buildCourierCard(),
                  ] else
                    _buildPickupLocationCard(),
                  const SizedBox(height: 16),
                  _buildQuotationSummaryCard(),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFFFF8F3),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: isDelivery
                  ? Row(
                      children: [
                        Expanded(child: _buildCancelButton(context)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTrackButton()),
                      ],
                    )
                  : _buildCancelButton(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showCancelOrderBottomSheet(context, orderId: orderId);
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFEA),
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          'Cancel',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackButton() {
    return GestureDetector(
      onTap: () {
        Get.to(() => PharmacyTrackOrderScreen(orderId: orderId));
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'Track Order',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(String imageUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prescription',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF3EFEA),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: Color(0xFFFF5E00),
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Prescription_Jun25.jpg',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8A7F77),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard() {
    final steps = isDelivery
        ? const [
            _StatusStep(
              label: 'Payment\nSuccessful',
              time: '23 Oct 2023,\n10:20 AM',
              done: true,
              icon: Icons.check_rounded,
            ),
            _StatusStep(
              label: 'Preparing\nMedicines',
              time: '23 Oct 2023,\n10:24 AM',
              done: true,
              icon: Icons.medication_liquid_rounded,
            ),
            _StatusStep(
              label: 'On the way',
              time: '23 Oct 2023,\n10:40 AM',
              done: true,
              icon: Icons.delivery_dining_rounded,
            ),
            _StatusStep(
              label: 'Delivered',
              time: '',
              done: false,
              icon: Icons.check_rounded,
            ),
          ]
        : const [
            _StatusStep(
              label: 'Payment\nSuccessful',
              time: '23 Oct 2023,\n10:20 AM',
              done: true,
              icon: Icons.check_rounded,
            ),
            _StatusStep(
              label: 'Preparing\nMedicines',
              time: '23 Oct 2023,\n10:24 AM',
              done: true,
              icon: Icons.medication_liquid_rounded,
            ),
            _StatusStep(
              label: 'Ready for\nPickup',
              time: '23 Oct 2023,\n10:40 AM',
              done: true,
              icon: Icons.shopping_bag_outlined,
              highlight: true,
            ),
            _StatusStep(
              label: 'Delivered',
              time: '',
              done: false,
              icon: Icons.check_rounded,
            ),
          ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
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
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Order Status',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                isDelivery ? 'Delivery' : 'Self Pickup',
                style: GoogleFonts.outfit(
                  color: isDelivery
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFF007DFE),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              const circle = 36.0;
              final usable = constraints.maxWidth - circle;
              final segment = usable / 3;

              return Column(
                children: [
                  SizedBox(
                    height: circle + 8,
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
                          children: [
                            for (var i = 0; i < steps.length; i++)
                              Container(
                                width: circle,
                                height: circle,
                                decoration: BoxDecoration(
                                  color: steps[i].done
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFFEFE8E1),
                                  shape: BoxShape.circle,
                                  boxShadow: steps[i].highlight
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFF5E00)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: i == 2 && steps[i].done && isDelivery
                                    ? Image.asset(
                                        'lib/assets/images/delivery_icon.png',
                                        width: 18,
                                        height: 18,
                                        color: Colors.white,
                                        errorBuilder: (_, __, ___) => Icon(
                                          steps[i].icon,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      )
                                    : Icon(
                                        steps[i].icon,
                                        color: steps[i].done
                                            ? Colors.white
                                            : const Color(0xFFB0A59C),
                                        size: 18,
                                      ),
                              ),
                          ],
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
                                color: step.done
                                    ? const Color(0xFF2C2520)
                                    : const Color(0xFFA59A94),
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
        ],
      ),
    );
  }

  Widget _buildMedicineCard({
    required String title,
    required String unit,
    required String totalAmount,
    String? availabilityBadge,
    bool showSuggestedAlternative = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A2338),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (availabilityBadge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    availabilityBadge,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFB8860B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (showSuggestedAlternative) ...[
            const SizedBox(height: 12),
            _buildSuggestedAlternativeBox(),
            const SizedBox(height: 14),
            _buildUnitTotalFooter(
              unitValue: unit,
              totalAmount: totalAmount,
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    unit.startsWith('Unit:') ? unit : 'Unit: $unit',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'Total: ',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  totalAmount,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  ' MRU',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestedAlternativeBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Alternative',
            style: GoogleFonts.outfit(
              color: const Color(0xFF8A94A6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4D4D),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Paracetamol 500 mg',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8A94A6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE8DC),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFFFF7A45),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Paracetamol 650 mg',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1A2338),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _buildUnitTotalFooter({
    required String unitValue,
    required String totalAmount,
  }) {
    final cleanUnit = unitValue
        .replaceFirst(RegExp(r'^Unit:\s*'), '')
        .replaceAll('x', '×');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unit',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8A94A6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cleanUnit,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A2338),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Total',
              style: GoogleFonts.outfit(
                color: const Color(0xFF8A94A6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  totalAmount,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A2338),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'MRU',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Color(0xFFFF5E00),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sahara View Home',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Near Marhaba Supermarket, Nouakchott',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Color(0xFFFF5E00),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pharmacyName,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$pharmacyName, Near Nouakchott, Mauritania',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFFF5E00),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildCourierCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&auto=format&fit=crop',
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 46,
                height: 46,
                color: const Color(0xFFF3EFEA),
                child: const Icon(Icons.person, color: Color(0xFFFF5E00)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amadou Sy',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFAE00),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '4.8',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(10k + reviews)',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5E00),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(22),
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
          _payRow('Item total', '1450 MRU'),
          const SizedBox(height: 10),
          _payRow('Delivery fee', '50 MRU'),
          const SizedBox(height: 10),
          _payRow('Tax', '20 MRU'),
          const SizedBox(height: 10),
          _payRow(
            'Redeemed points',
            '-50 MRU',
            valueColor: const Color(0xFFFF5E00),
            labelColor: const Color(0xFFFF5E00),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFF3A434E)),
          ),
          Row(
            children: [
              Text(
                'Total Paid',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '1470 MRU',
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

  Widget _payRow(
    String label,
    String value, {
    Color? valueColor,
    Color? labelColor,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: labelColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusStep {
  final String label;
  final String time;
  final bool done;
  final IconData icon;
  final bool highlight;

  const _StatusStep({
    required this.label,
    required this.time,
    required this.done,
    required this.icon,
    this.highlight = false,
  });
}
