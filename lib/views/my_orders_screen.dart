import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_screen.dart';
import 'order_detail_screen.dart';
import 'track_order_screen.dart';
import 'rate_order_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  int selectedCategoryIndex = 0; // 0: All, 1: Food, 2: Grocery, 3: Pharmacy
  final List<String> categories = ["All", "Food", "Grocery", "Pharmacy"];

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
                'My Orders',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                bottom: 110,
              ), // extra padding for bottom nav bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Horizontal Category Pills
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final isSelected = selectedCategoryIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategoryIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF5E00)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF5E00)
                                    : const Color(0xFFEAD8C9),
                                width: 0.8,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              categories[index],
                              style: GoogleFonts.outfit(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFA59A94),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Orders Cards List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Card 1
                        _buildOrderCard(
                          restaurantName: "Al Fantasia Restaurant",
                          statusText: "ON THE WAY",
                          statusColor: const Color(0xFFFF8A00),
                          statusBgColor: const Color(0xFFFFF4EC),
                          detailsText:
                              "Delivery - 750 MRU - 2 items - #22789002",
                          buttons: [
                            _buildOrderButton(
                              text: "Cancel",
                              onTap: () => _showCancelDialog(),
                            ),
                            const SizedBox(width: 12),
                            _buildGradientButton(
                              text: "Track Order",
                              onTap: () {
                                Get.to(
                                  () => const TrackOrderScreen(
                                    orderId: "#22789002",
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // Card 2
                        _buildOrderCard(
                          restaurantName: "Al Fantasia Restaurant",
                          statusText: "SELF PICKUP",
                          statusColor: const Color(0xFF007DFE),
                          statusBgColor: const Color(0xFFECF5FF),
                          detailsText: "Pickup - 500 MRU - 2 items - #22789001",
                          buttons: [
                            _buildOrderButton(
                              text: "Cancel",
                              onTap: () => _showCancelDialog(),
                            ),
                          ],
                        ),

                        // Card 3
                        _buildOrderCard(
                          restaurantName: "Salam Supermarket",
                          statusText: "DELIVERED",
                          statusColor: const Color(0xFF00B25C),
                          statusBgColor: const Color(0xFFE8F8EE),
                          detailsText:
                              "Delivery - 1500 MRU - 10 items - #22789000",
                          buttons: [
                            _buildOrderButton(
                              text: "Reorder",
                              onTap: () => _showReorderSnackBar(),
                            ),
                            const SizedBox(width: 12),
                            _buildOrderButton(
                              text: "Rate",
                              onTap: () {
                                Get.to(() => const RateOrderScreen());
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required String restaurantName,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
    required String detailsText,
    required List<Widget> buttons,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Top Row: Restaurant Name and Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                restaurantName,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.outfit(
                    color: statusColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Details text
          Text(
            detailsText,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons
          Row(children: buttons),

          if (statusText != "DELIVERED") ...[
            const SizedBox(height: 12),
            // Bottom details link
            Center(
              child: GestureDetector(
                onTap: () {
                  final parts = detailsText.split('#');
                  final orderId = parts.length > 1
                      ? '#${parts[1]}'
                      : '#22789002';
                  Get.to(
                    () => OrderDetailScreen(
                      orderId: orderId,
                      isSelfPickup: statusText == "SELF PICKUP",
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
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EFEA),
            borderRadius: BorderRadius.circular(19),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E00).withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Floating Bottom Navigation Bar
  Widget _buildBottomNavigationBar(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              0,
              "lib/assets/images/Bottom Home.png",
              'Home',
              false,
            ),
            _buildNavItem(
              1,
              "lib/assets/images/Bottom Search.png",
              'Search',
              false,
            ),
            _buildNavItem(
              2,
              "lib/assets/images/Bottom Order.png",
              'Orders',
              true,
            ),
            _buildNavItem(
              3,
              "lib/assets/images/Bottom Cart.png",
              'Cart',
              false,
            ),
            _buildNavItem(
              4,
              "lib/assets/images/Bottom Profile.png",
              'Profile',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String assetPath,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          // Go to HomeScreen
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (index == 3) {
          // Off to CartScreen
          Get.off(() => const CartScreen());
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              width: 22,
              height: 22,
              color: isSelected
                  ? const Color(0xFFFF5E00)
                  : const Color(0xFFA59A94),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected
                    ? const Color(0xFFFF5E00)
                    : const Color(0xFFA59A94),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5E00),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // SnackBar notifications
  void _showCancelDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cancel requested!', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFFFF3E3E),
      ),
    );
  }

  void _showTrackSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tracking order route...', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFFFF5E00),
      ),
    );
  }

  void _showReorderSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Items added for reorder!', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF00B25C),
      ),
    );
  }

  void _showRateSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening rating window...', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFFFF5E00),
      ),
    );
  }

  void _showDetailsSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening order details...', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFFFF5E00),
      ),
    );
  }
}
