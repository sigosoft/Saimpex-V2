import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_detail_screen.dart';
import 'water/water_order_details_screen.dart';
import 'water/water_track_order_screen.dart';
import 'track_order_screen.dart';
import 'rate_order_screen.dart';
import 'pharmacy/widgets/pharmacy_order_cards.dart';
import 'courier/widgets/courier_order_cards.dart';
import '../controllers/home_controller.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../navigation/bottom_nav_router.dart';

class MyOrdersScreen extends StatefulWidget {
  final bool showBottomNav;
  final int initialCategoryIndex;

  const MyOrdersScreen({
    super.key,
    this.showBottomNav = true,
    this.initialCategoryIndex = 0,
  });

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  // Matches design: Pharmacy, Water, Courier, Local Store
  late int selectedCategoryIndex;
  final List<String> categories = ["Pharmacy", "Water", "Courier", "Local Store"];
  Worker? _ordersCategoryWorker;

  @override
  void initState() {
    super.initState();
    _applyInitialCategory();
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      _ordersCategoryWorker = ever<int>(
        home.pendingOrdersCategoryIndex,
        (pending) {
          if (pending < 0 || !mounted) return;
          setState(() {
            selectedCategoryIndex =
                pending.clamp(0, categories.length - 1);
          });
          home.pendingOrdersCategoryIndex.value = -1;
        },
      );
    }
  }

  @override
  void dispose() {
    _ordersCategoryWorker?.dispose();
    super.dispose();
  }

  void _applyInitialCategory() {
    final fallback = widget.initialCategoryIndex.clamp(
      0,
      categories.length - 1,
    );
    if (Get.isRegistered<HomeController>()) {
      selectedCategoryIndex = Get.find<HomeController>()
          .consumePendingOrdersCategory(fallback)
          .clamp(0, categories.length - 1);
    } else {
      selectedCategoryIndex = fallback;
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
      return;
    }

    BottomNavRouter.returnToShell(tabIndex: 2);
  }

  @override
  Widget build(BuildContext context) {
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
        child: Container(
          color: Colors.transparent,
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
                child: widget.showBottomNav
                    ? GestureDetector(
                        onTap: () => _handleBack(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFEAD8C9),
                              width: 0.8,
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
                      )
                    : const SizedBox(width: 38),
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
                              borderRadius: BorderRadius.circular(30),
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
                                    : const Color(0xFF8A7F77),
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
                    child: selectedCategoryIndex == 0
                        ? _buildPharmacyOrders()
                        : selectedCategoryIndex == 1
                            ? _buildWaterOrders()
                            : selectedCategoryIndex == 2
                                ? _buildCourierOrders()
                                : _buildOtherCategoryOrders(),
                  ),
                ],
              ),
            ),
          ),

          // Floating Bottom Navigation Bar
          if (widget.showBottomNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNavBar(
                selectedIndex: 2,
                onTap: BottomNavRouter.go,
              ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildPharmacyOrders() {
    return Column(
      children: [
        const PharmacyQuotationReadyCard(),
        PharmacyActiveOrderCard(
          statusText: 'ON THE WAY',
          statusColor: const Color(0xFFFF8A00),
          statusBgColor: const Color(0xFFFFF4EC),
          detailsText: 'Delivery • 50 MRU • #22789007',
          orderId: '#22789007',
          showPrescription: true,
          showTrack: true,
        ),
        PharmacyActiveOrderCard(
          statusText: 'SELF PICKUP',
          statusColor: const Color(0xFF007DFE),
          statusBgColor: const Color(0xFFECF5FF),
          detailsText: 'Delivery • 50 MRU • #22789007',
          orderId: '#22789007',
          showPrescription: true,
          showTrack: true,
        ),
        PharmacyActiveOrderCard(
          statusText: 'ON THE WAY',
          statusColor: const Color(0xFFFF8A00),
          statusBgColor: const Color(0xFFFFF4EC),
          detailsText: 'Delivery • 100 MRU • 2 items • #22789009',
          orderId: '#22789009',
          showPrescription: false,
          showTrack: true,
        ),
        PharmacyActiveOrderCard(
          statusText: 'SELF PICKUP',
          statusColor: const Color(0xFF007DFE),
          statusBgColor: const Color(0xFFECF5FF),
          detailsText: 'Self Pickup • 60 MRU • 2 items • #22789010',
          orderId: '#22789010',
          showPrescription: false,
          showTrack: false,
        ),
      ],
    );
  }

  Widget _buildWaterOrders() {
    return Column(
      children: [
        // 1. Order Card 1: ON THE WAY (Delivery)
        _buildOrderCard(
          restaurantName: "PureLife Water Co.",
          statusText: "ON THE WAY",
          statusColor: const Color(0xFFFF5E00),
          statusBgColor: const Color(0xFFFFF4EC),
          detailsText: "Delivery • 50 MRU • 1 items • #22789002",
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
                  () => const WaterTrackOrderScreen(
                    orderId: "#22789002",
                  ),
                );
              },
            ),
          ],
        ),

        // 2. Order Card 2: SELF PICKUP (Pickup)
        _buildOrderCard(
          restaurantName: "PureLife Water Co.",
          statusText: "SELF PICKUP",
          statusColor: const Color(0xFF007DFE),
          statusBgColor: const Color(0xFFECF5FF),
          detailsText: "Pickup • 50 MRU • 1 items • #22789001",
          buttons: [
            _buildOrderButton(
              text: "Cancel",
              onTap: () => _showCancelDialog(),
            ),
          ],
        ),

        // 3. Order Card 3: DELIVERED (Delivery)
        _buildOrderCard(
          restaurantName: "PureLife Water Co.",
          statusText: "DELIVERED",
          statusColor: const Color(0xFF00B25C),
          statusBgColor: const Color(0xFFE8F8EE),
          detailsText: "Delivery • 500 MRU • 3 items • #22789000",
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
    );
  }

  Widget _buildCourierOrders() {
    return Column(
      children: [
        CourierActiveOrderCard(
          statusText: 'ON THE WAY',
          statusColor: const Color(0xFFFF8A00),
          statusBgColor: const Color(0xFFFFF4EC),
          detailsText: 'Bike Delivery • 50 MRU • #227890011',
          orderId: '#227890011',
        ),
      ],
    );
  }

  Widget _buildOtherCategoryOrders() {
    return Column(
      children: [
        _buildOrderCard(
          restaurantName: "Al Fantasia Restaurant",
          statusText: "ON THE WAY",
          statusColor: const Color(0xFFFF8A00),
          statusBgColor: const Color(0xFFFFF4EC),
          detailsText: "Delivery • 750 MRU • 2 items • #22789002",
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
        _buildOrderCard(
          restaurantName: "Al Fantasia Restaurant",
          statusText: "SELF PICKUP",
          statusColor: const Color(0xFF007DFE),
          statusBgColor: const Color(0xFFECF5FF),
          detailsText: "Pickup • 500 MRU • 2 items • #22789001",
          buttons: [
            _buildOrderButton(
              text: "Cancel",
              onTap: () => _showCancelDialog(),
            ),
          ],
        ),
        _buildOrderCard(
          restaurantName: "Salam Supermarket",
          statusText: "DELIVERED",
          statusColor: const Color(0xFF00B25C),
          statusBgColor: const Color(0xFFE8F8EE),
          detailsText: "Delivery • 1500 MRU • 10 items • #22789000",
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
        borderRadius: BorderRadius.circular(30),
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
                  borderRadius: BorderRadius.circular(30),
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
                  if (restaurantName.contains('Water')) {
                    Get.to(() => WaterOrderDetailsScreen(
                          orderId: orderId,
                          isSelfPickup: statusText == "SELF PICKUP",
                        ));
                  } else {
                    Get.to(
                      () => OrderDetailScreen(
                        orderId: orderId,
                        isSelfPickup: statusText == "SELF PICKUP",
                      ),
                    );
                  }
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
            borderRadius: BorderRadius.circular(30),
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
            borderRadius: BorderRadius.circular(30),
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
