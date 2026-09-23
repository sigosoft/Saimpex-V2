import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'water_track_order_screen.dart';
import '../help_support_screen.dart';
import '../../widgets/cancel_order_bottom_sheet.dart';
import '../../widgets/app_back_button.dart';

class WaterOrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final bool isSelfPickup;

  const WaterOrderDetailsScreen({
    super.key,
    this.orderId = "#22789000",
    this.isSelfPickup = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // 1. Header Bar (Back button, Order ID Title, Help button)
              _buildHeader(context),
              const SizedBox(height: 12),

              // Scrollable Order Details Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Order Status Timeline Card
                      _buildOrderStatusCard(),
                      const SizedBox(height: 18),

                      // 3. Location / Driver Section (Dynamic based on isSelfPickup)
                      _buildLocationDriverSection(),
                      const SizedBox(height: 18),

                      // 4. Order Summary Section
                      _buildOrderSummarySection(),
                      const SizedBox(height: 18),

                      // 5. Dark Receipt Container (PAYMENT DETAILS)
                      _buildDarkReceiptBox(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // 6. Bottom Action Buttons Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: isSelfPickup
                    ? _buildSingleCancelButton(context)
                    : _buildDualActionButtons(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Bar Widget
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppBackButton(onTap: () => Get.back(),),
          Text(
            'Order $orderId',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              Get.to(() => const HelpSupportScreen());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEAD8C9),
                  width: 1.0,
                ),
              ),
              child: Text(
                'Help',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Order Status Timeline Card
  Widget _buildOrderStatusCard() {
    final steps = [
      (
        icon: Icons.check_rounded,
        title: 'Order placed',
        subtitle: '22 Oct 2023, 10:10 AM',
        isActive: true,
      ),
      (
        icon: Icons.shopping_bag_outlined,
        title: 'Picking items',
        subtitle: '22 Oct 2023, 10:11 AM',
        isActive: true,
      ),
      (
        icon: isSelfPickup
            ? Icons.storefront_outlined
            : Icons.delivery_dining_rounded,
        title: isSelfPickup ? 'Ready for pickup' : 'On the way',
        subtitle: '22 Oct 2023, 10:13 AM',
        isActive: true,
      ),
      (
        icon: Icons.check_rounded,
        title: 'Delivered',
        subtitle: '',
        isActive: false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
                  color: const Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                isSelfPickup ? 'Self Pickup' : 'Delivery',
                style: GoogleFonts.outfit(
                  color: isSelfPickup
                      ? const Color(0xFF007DFE)
                      : const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const circle = 36.0;
              final usable = constraints.maxWidth - circle;
              final segment = usable / (steps.length - 1);

              return Column(
                children: [
                  SizedBox(
                    height: circle,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Line through exact vertical center of circles
                        Positioned(
                          left: circle / 2,
                          right: circle / 2,
                          top: (circle - 3) / 2,
                          child: Row(
                            children: List.generate(steps.length - 1, (i) {
                              final segmentActive = steps[i].isActive &&
                                  steps[i + 1].isActive;
                              return Container(
                                width: segment,
                                height: 3,
                                color: segmentActive
                                    ? const Color(0xFFFF5E00)
                                    : const Color(0xFFE8E0D8),
                              );
                            }),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final step in steps)
                              Container(
                                width: circle,
                                height: circle,
                                decoration: BoxDecoration(
                                  color: step.isActive
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFFEFEBE7),
                                  shape: BoxShape.circle,
                                  boxShadow: step.isActive
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFF5E00)
                                                .withValues(alpha: 0.40),
                                            blurRadius: 12,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  step.icon,
                                  color: step.isActive
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
                              step.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1A1A1A),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                            if (step.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                step.subtitle,
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

  // Location / Driver Section (Dynamic)
  Widget _buildLocationDriverSection() {
    if (isSelfPickup) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Location',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: Color(0xFFFF5E00),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salam Supermarket',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Salam Supermarket, Near Nouakchott, Mauritania',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8C7E75),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFF5E00),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Details',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Location Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    color: Color(0xFFFF5E00),
                    size: 18,
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
                          color: const Color(0xFF1A1A1A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Near Marhaba Supermarket, Nouakchott',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8C7E75),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Driver Contact Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFFFF0E6),
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFFFF5E00),
                    size: 24,
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
                          color: const Color(0xFF1A1A1A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '4.6 (12k + reviews)',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8C7E75),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Phone Call Icon Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5E00),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // Order Summary Section
  Widget _buildOrderSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildOrderItemRow('Drinking Water', '19L', 'x1', '50 MRU'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Color(0xFFF3EFEA), height: 1),
              ),
              _buildOrderItemRow('Drinking Water', '19L', 'x1', '50 MRU'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemRow(
    String title,
    String subtitle,
    String qty,
    String price,
  ) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 55,
            height: 55,
            color: const Color(0xFFEBF4FE),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'lib/assets/images/19L water.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.water_drop,
                color: Color(0xFF007BFF),
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8C7E75),
                  fontSize: 11,
                ),
              ),
              Text(
                qty,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Dark Receipt Container (PAYMENT DETAILS)
  Widget _buildDarkReceiptBox() {
    final int totalAmount = isSelfPickup ? 52 : 57;
    final String totalLabel = isSelfPickup ? 'To pay' : 'Total paid';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _buildReceiptRow('Item total', '100 MRU'),
          const SizedBox(height: 8),
          _buildReceiptRow('Redeemed points', '-50 MRU', isOrange: true),
          if (!isSelfPickup) ...[
            const SizedBox(height: 8),
            _buildReceiptRow('Delivery fee', '5 MRU'),
          ],
          const SizedBox(height: 8),
          _buildReceiptRow('Tax', '2 MRU'),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalLabel,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalAmount MRU',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isOrange = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFFD4CDC5),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isOrange ? const Color(0xFFFF5E00) : Colors.white,
            fontSize: 12,
            fontWeight: isOrange ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Single Cancel Button for Self Pickup Mode
  Widget _buildSingleCancelButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showCancelDialog(context);
      },
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF6EFE6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            'Cancel',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Dual Buttons (Cancel & Track Order) for Delivery Mode
  Widget _buildDualActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              _showCancelDialog(context);
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF6EFE6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Get.to(() => WaterTrackOrderScreen(orderId: orderId));
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Track Order',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showCancelOrderBottomSheet(
      context,
      orderId: orderId,
    );
  }
}
