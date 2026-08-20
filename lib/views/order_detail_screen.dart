import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'track_order_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final bool isSelfPickup;

  const OrderDetailScreen({
    super.key,
    this.orderId = "#22789002",
    this.isSelfPickup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: const Color(0xFFFFFDF9),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
          ),
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
                        color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF5E00).withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Help',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Order Status Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
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
                          color: isSelfPickup ? const Color(0xFF007DFE) : const Color(0xFFFF5E00),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Custom Stepper layout
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Connector lines behind circles
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
                      // Stepper nodes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepperNode(
                            isActive: true,
                            icon: Icons.check,
                            title: "Order placed",
                            time: isSelfPickup
                                ? "22 Oct 2023, 10:05 AM"
                                : "22 Oct 2023, 10:00 AM",
                          ),
                          _buildStepperNode(
                            isActive: true,
                            icon: Icons.shopping_bag_outlined,
                            title: "Picking Items",
                            time: isSelfPickup
                                ? "22 Oct 2023, 10:05 AM"
                                : "22 Oct 2023, 10:10 AM",
                          ),
                          _buildStepperNode(
                            isActive: true,
                            showGlow: true,
                            icon: isSelfPickup
                                ? Icons.inventory_2_outlined
                                : Icons.delivery_dining_rounded,
                            title: isSelfPickup
                                ? "Ready for pickup"
                                : "On the way",
                            time: isSelfPickup
                                ? "22 Oct 2023, 10:10 AM"
                                : "22 Oct 2023, 10:15 AM",
                          ),
                          _buildStepperNode(
                            isActive: false,
                            icon: Icons.check,
                            title: "Delivered",
                            time: "",
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Delivery Details / Pickup Location
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
              // Restaurant Location Card for Pickup
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0EA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFFFF5E00),
                        size: 16,
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Salam Supermarket, Near Nouakchott, Mauritania',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
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
              )
            else ...[
              // Address Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0EA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.home_outlined,
                        color: Color(0xFFFF5E00),
                        size: 16,
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Near Marhaba Supermarket, Nouakchott',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.network(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              width: 56,
                              height: 56,
                              color: const Color(0xFFEAD8C9),
                              child: const Icon(Icons.person, color: Colors.white),
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
                              fontWeight: FontWeight.w700,
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
                                '4.8',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ' (10k+ reviews)',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFA59A94),
                                  fontSize: 11,
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
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5E00),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call,
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

            // 3. Order Summary
            Text(
              'Order Summary',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Items Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  // Item 1
                  _buildSummaryItem(
                    title: "Potato",
                    description: "1Kg",
                    priceText: "50 MRU",
                    imageUrl:
                        "https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=200&auto=format&fit=crop",
                  ),
                  const Divider(
                    color: Color(0xFFEAD8C9),
                    height: 20,
                    thickness: 0.5,
                  ),
                  _buildSummaryItem(
                    title: "Banana",
                    description: "2 Kg",
                    priceText: "50 MRU",
                    imageUrl:
                        "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=200&auto=format&fit=crop",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. Payment Details Box
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2520),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAYMENT DETAILS',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPaymentDetailsRow("Item total", "100 MRU", false),
                  const SizedBox(height: 10),
                  _buildPaymentDetailsRow("Redeemed points", "-50 MRU", true),
                  if (!isSelfPickup) ...[
                    const SizedBox(height: 10),
                    _buildPaymentDetailsRow("Delivery fee", "5 MRU", false),
                  ],
                  const SizedBox(height: 10),
                  _buildPaymentDetailsRow("Tax", "2 MRU", false),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFF423B36), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSelfPickup ? 'To pay' : 'Total paid',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isSelfPickup ? '52 MRU' : '57 MRU',
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
            ),

            const SizedBox(height: 8),
          ],
        ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewPadding.bottom + 12,
            ),
            child: isSelfPickup
                ? GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Order cancellation requested!',
                            style: GoogleFonts.outfit(),
                          ),
                          backgroundColor: const Color(0xFFFF3E3E),
                        ),
                      );
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFEA),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Order cancellation requested!',
                                  style: GoogleFonts.outfit(),
                                ),
                                backgroundColor: const Color(0xFFFF3E3E),
                              ),
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EFEA),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => TrackOrderScreen(orderId: orderId));
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5E00)
                                      .withValues(alpha: 0.3),
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
        ],
      ),
    );
  }

  Widget _buildStepperNode({
    required bool isActive,
    required IconData icon,
    required String title,
    required String time,
    bool showGlow = false,
  }) {
    return SizedBox(
      width: 78,
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
                        color: const Color(0xFFFF5E00).withOpacity(0.45),
                        blurRadius: 12,
                        spreadRadius: 2,
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
                  : const Color(0xFFA59A94),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              time,
              style: GoogleFonts.outfit(
                color: const Color(0xFFA59A94),
                fontSize: 6.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String description,
    required String priceText,
    required String imageUrl,
  }) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 46,
            height: 46,
            fit: BoxFit.cover,
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'x1',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          priceText,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsRow(String label, String value, bool isOrange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isOrange ? const Color(0xFFFF5E00) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
