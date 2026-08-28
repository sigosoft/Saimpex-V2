import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'track_order_screen.dart';
import '../widgets/cancel_order_bottom_sheet.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final bool isSelfPickup;

  const OrderDetailScreen({
    super.key,
    this.orderId = "#22789000",
    this.isSelfPickup = false,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFF7F2),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F2),
        body: Column(
          children: [
            SizedBox(height: topInset + 10),

            // 1. App Bar Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            color: const Color(
                              0xFFFF5E00,
                            ).withValues(alpha: 0.2),
                            width: 1.0,
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
                    'Order $orderId',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Help center opened',
                              style: GoogleFonts.outfit(),
                            ),
                            backgroundColor: const Color(0xFFFF5E00),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFFF5E00,
                            ).withValues(alpha: 0.35),
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 2. Order Status Stepper Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order Status',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isSelfPickup ? 'Self Pickup' : 'Delivery',
                                style: GoogleFonts.outfit(
                                  color: isSelfPickup
                                      ? const Color(0xFF007DFE)
                                      : const Color(0xFFFF5E00),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Custom Stepper Progress Row
                          Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              // Connector Lines
                              Positioned(
                                top: 18,
                                left: 30,
                                right: 30,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: const Color(0xFFFF5E00),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: const Color(0xFFFF5E00),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: const Color(0xFFEAD8C9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Nodes
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStepperNode(
                                    isActive: true,
                                    icon: Icons.check,
                                    title: 'Order placed',
                                    time: '22 Oct 2023, 10:00 AM',
                                  ),
                                  _buildStepperNode(
                                    isActive: true,
                                    icon: Icons.shopping_bag_outlined,
                                    title: 'Picking Items',
                                    time: '22 Oct 2023, 10:05 AM',
                                  ),
                                  _buildStepperNode(
                                    isActive: true,
                                    showGlow: true,
                                    icon: isSelfPickup
                                        ? Icons.inventory_2_outlined
                                        : Icons.two_wheeler_rounded,
                                    title: isSelfPickup
                                        ? 'Ready for pickup'
                                        : 'On the way',
                                    time: '22 Oct 2023, 10:15 AM',
                                  ),
                                  _buildStepperNode(
                                    isActive: false,
                                    icon: Icons.check,
                                    title: 'Delivered',
                                    time: '',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 3. Delivery Details Header & Card
                    Text(
                      isSelfPickup ? 'Pickup Location' : 'Delivery Details',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (isSelfPickup)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF0EA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
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
                                      color: const Color(0xFF2C2520),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Salam Supermarket, Near Nouakchott, Mauritania',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF8C7D73),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Address Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF0EA),
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
                                      color: const Color(0xFF2C2520),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Near Marhaba Supermarket,Nouakchott',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF8C7D73),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Driver Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipOval(
                              child: Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFFF3E7DC),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFFFF5E00),
                                  size: 28,
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFFFAE00),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '4.6',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(10k + reviews)',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF8C7D73),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Calling Amadou Sy...',
                                      style: GoogleFonts.outfit(),
                                    ),
                                    backgroundColor: const Color(0xFFFF5E00),
                                  ),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5E00),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.call_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // 4. Order Summary Section
                    Text(
                      'Order Summary',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Item 1: Butter Croissant
                          _buildSummaryItem(
                            title: 'Butter Croissant',
                            weight: '1Kg',
                            quantity: 'x1',
                            price: '50 MRU',
                            assetPath: 'lib/assets/images/Bakery.png',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: Color(0xFFF3E7DC), height: 1),
                          ),
                          // Item 2: Citrus Lemon Tart
                          _buildSummaryItem(
                            title: 'Citrus Lemon Tart',
                            weight: '2 Kg',
                            quantity: 'x1',
                            price: '50 MRU',
                            assetPath: 'lib/assets/images/Cookies.png',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 5. Payment Details Card (Dark Container)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2520),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PAYMENT DETAILS',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildPaymentRow('Item total', '100 MRU'),
                          const SizedBox(height: 8),
                          _buildPaymentRow(
                            'Redeemed points',
                            '-50 MRU',
                            isOrange: true,
                          ),
                          if (!isSelfPickup) ...[
                            const SizedBox(height: 8),
                            _buildPaymentRow('Delivery fee', '5 MRU'),
                          ],
                          const SizedBox(height: 8),
                          _buildPaymentRow('Tax', '2 MRU'),
                          const SizedBox(height: 14),
                          Container(height: 1, color: Colors.white12),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total paid',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '57 MRU',
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
                    ),

                    const SizedBox(height: 20),

                    // 6. Action Buttons Row (Cancel & Track Order)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              showCancelOrderBottomSheet(context);
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6ECE5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Get.to(() => TrackOrderScreen(orderId: orderId));
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5E00),
                                    Color(0xFFFFAE00),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF5E00,
                                    ).withValues(alpha: 0.3),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stepper Node Helper
  Widget _buildStepperNode({
    required bool isActive,
    required IconData icon,
    required String title,
    required String time,
    bool showGlow = false,
  }) {
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFFF5E00)
                  : const Color(0xFFEAD8C9),
              shape: BoxShape.circle,
              boxShadow: showGlow
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFFC4B8B0),
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: isActive
                  ? const Color(0xFF2C2520)
                  : const Color(0xFF8C7D73),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              time,
              style: GoogleFonts.outfit(
                color: const Color(0xFF8C7D73),
                fontSize: 7,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Order Summary Item Row Helper
  Widget _buildSummaryItem({
    required String title,
    required String weight,
    required String quantity,
    required String price,
    required String assetPath,
  }) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 58,
            height: 58,
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF3E7DC),
                child: const Icon(
                  Icons.fastfood_rounded,
                  color: Color(0xFFFF5E00),
                  size: 24,
                ),
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
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                weight,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8C7D73),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                quantity,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Payment Details Row Helper
  Widget _buildPaymentRow(String label, String value, {bool isOrange = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFFA59A94),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isOrange ? const Color(0xFFFF5E00) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
