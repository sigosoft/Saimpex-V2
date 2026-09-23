import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_detail_screen.dart';
import 'order_updated_detail_screen.dart';
import 'water/water_order_details_screen.dart';
import 'water/water_track_order_screen.dart';
import 'track_order_screen.dart';
import 'rate_order_screen.dart';
import 'pharmacy/widgets/pharmacy_order_cards.dart';
import 'courier/widgets/courier_order_cards.dart';
import '../controllers/home_controller.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../navigation/bottom_nav_router.dart';
import '../widgets/cancel_order_bottom_sheet.dart';

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
  // Matches design: All, Food, Pharmacy, Water, Courier, Local Store
  late int selectedCategoryIndex;
  final List<String> categories = [
    "All",
    "Food",
    "Pharmacy",
    "Water",
    "Courier",
    "Local Store",
  ];
  Worker? _ordersCategoryWorker;

  @override
  void initState() {
    super.initState();
    _applyInitialCategory();
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      _ordersCategoryWorker = ever<int>(home.pendingOrdersCategoryIndex, (
        pending,
      ) {
        if (pending < 0 || !mounted) return;
        setState(() {
          selectedCategoryIndex = pending.clamp(0, categories.length - 1);
        });
        home.pendingOrdersCategoryIndex.value = -1;
      });
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

    BottomNavRouter.returnToShell(tabIndex: HomeController.navOrders);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFAF6F0), Color(0xFFFFEEE5), Color(0xFFFFDDCF)],
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
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
                          ? _buildAllOrders()
                          : selectedCategoryIndex == 1
                          ? _buildFoodOrders()
                          : selectedCategoryIndex == 2
                          ? _buildPharmacyOrders()
                          : selectedCategoryIndex == 3
                          ? _buildWaterOrders()
                          : selectedCategoryIndex == 4
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
                  selectedIndex: HomeController.navOrders,
                  onTap: BottomNavRouter.go,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllOrders() {
    return Column(
      children: [
        _buildOrderUpdatedCard(),
        _buildPaymentPendingCard(),
        _buildFoodOrders(),
        _buildPharmacyOrders(),
        _buildWaterOrders(),
        _buildCourierOrders(),
        _buildOtherCategoryOrders(),
      ],
    );
  }

  Widget _buildFoodOrders() {
    return Column(
      children: [
        _buildOrderCard(
          restaurantName: "Al Fantasia",
          statusText: "ON THE WAY",
          statusColor: const Color(0xFFFF8A00),
          statusBgColor: const Color(0xFFFFF4EC),
          detailsText: "Delivery • 750 MRU • 2 items • #22789000",
          buttons: [
            _buildOrderButton(
              text: "Cancel",
              onTap: () => _showCancelDialog(orderId: "#22789000"),
            ),
            const SizedBox(width: 12),
            _buildGradientButton(
              text: "Track Order",
              onTap: () {
                Get.to(() => const TrackOrderScreen(orderId: "#22789000"));
              },
            ),
          ],
        ),
        _buildOrderCard(
          restaurantName: "Tarif Restaurant",
          statusText: "SELF PICKUP",
          statusColor: const Color(0xFF007DFE),
          statusBgColor: const Color(0xFFECF5FF),
          detailsText: "Pickup • 500 MRU • 1 items • #22789001",
          buttons: [
            _buildOrderButton(
              text: "Cancel",
              onTap: () => _showCancelDialog(orderId: "#22789001"),
            ),
          ],
        ),
        _buildOrderCard(
          restaurantName: "Portuguese restaurant",
          statusText: "DELIVERED",
          statusColor: const Color(0xFF00B25C),
          statusBgColor: const Color(0xFFE8F8EE),
          detailsText: "Delivery • 1,200 MRU • 3 items • #22789002",
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
              onTap: () => _showCancelDialog(orderId: "#22789002"),
            ),
            const SizedBox(width: 12),
            _buildGradientButton(
              text: "Track Order",
              onTap: () {
                Get.to(() => const WaterTrackOrderScreen(orderId: "#22789002"));
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
              onTap: () => _showCancelDialog(orderId: "#22789001"),
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
        if (selectedCategoryIndex != 0) ...[
          _buildOrderUpdatedCard(),
          _buildPaymentPendingCard(),
        ],
        // 1. Golden Bakery - ON THE WAY (Delivery)
        _buildOrderCard(
          restaurantName: "Golden Bakery",
          statusText: "ON THE WAY",
          statusColor: const Color(0xFFFF8A00),
          statusBgColor: const Color(0xFFFFF4EC),
          detailsText: "Delivery • 200 MRU • 4 items • #22789002",
          buttons: [
            _buildOrderButton(
              text: "Cancel",
              onTap: () => _showCancelDialog(orderId: "#22789002"),
            ),
            const SizedBox(width: 12),
            _buildGradientButton(
              text: "Track Order",
              onTap: () {
                Get.to(() => const TrackOrderScreen(orderId: "#22789002"));
              },
            ),
          ],
        ),

        // 2. Golden Bakery - SELF PICKUP (Pickup)
        _buildOrderCard(
          restaurantName: "Golden Bakery",
          statusText: "SELF PICKUP",
          statusColor: const Color(0xFF007DFE),
          statusBgColor: const Color(0xFFECF5FF),
          detailsText: "Pickup • 200 MRU • 4 items • #22789001",
          buttons: [
            _buildOrderButton(
              text: "Cancel",
              onTap: () => _showCancelDialog(orderId: "#22789001"),
            ),
          ],
        ),

        // 3. City Florist - DELIVERED (Delivery)
        _buildOrderCard(
          restaurantName: "City Florist",
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

  Widget _buildPaymentPendingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  'Salam Supermarket',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                    children: const [
                      TextSpan(
                        text: 'DELIVERED',
                        style: TextStyle(color: Color(0xFF00B25C)),
                      ),
                      TextSpan(
                        text: ' • ',
                        style: TextStyle(color: Color(0xFFFF5E00)),
                      ),
                      TextSpan(
                        text: 'PAYMENT PENDING',
                        style: TextStyle(color: Color(0xFFFF5E00)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Delivery • 1500 MRU • 10 items • #22789000',
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildOrderButton(
                text: 'Reorder',
                onTap: () => _showReorderSnackBar(),
              ),
              const SizedBox(width: 12),
              _buildOrderButton(
                text: 'Rate',
                onTap: () {
                  Get.to(() => const RateOrderScreen());
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: 46,
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
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Pay Now',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderUpdatedCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  'Salam Supermarket',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GestureDetector(
                  onTap: () {
                    Get.to(
                      () => const OrderUpdatedDetailScreen(
                        orderId: '#22789000',
                        storeName: 'Salam Supermarket',
                      ),
                    );
                  },
                  child: Text(
                    'REVIEW CHANGES',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF3B6FE8),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Delivery • 210 MRU • 4 items • #22789002',
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5E00),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sync_problem_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Order Updated',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Salam Supermarket adjusted unavailable items. Please review and approve the changes before your order continues.',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF5C656F),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFFFF5E00),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Adjustment Difference:',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+10 MRU Credit Due',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EFEA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Reject',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
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
                    Get.to(
                      () => const OrderUpdatedDetailScreen(
                        orderId: '#22789000',
                        storeName: 'Salam Supermarket',
                      ),
                    );
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF5E00,
                          ).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Approve Changes',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () {
                Get.to(
                  () => const OrderUpdatedDetailScreen(
                    orderId: '#22789000',
                    storeName: 'Salam Supermarket',
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFFF5E00),
                    size: 18,
                  ),
                ],
              ),
            ),
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
                    Get.to(
                      () => WaterOrderDetailsScreen(
                        orderId: orderId,
                        isSelfPickup: statusText == "SELF PICKUP",
                      ),
                    );
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
  void _showCancelDialog({String? orderId}) {
    showCancelOrderBottomSheet(context, orderId: orderId);
  }


  void _showReorderSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Items added for reorder!', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF00B25C),
      ),
    );
  }
}
