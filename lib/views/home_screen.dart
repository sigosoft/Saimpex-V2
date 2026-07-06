import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../controllers/home_controller.dart';
import '../controllers/select_location_controller.dart';
import 'category_screen.dart';
import 'grocery/grocery_screen.dart';
import 'pharmacy/pharmacy_screen.dart';
import 'under_30_min_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFE6DC), // Top peach gradient
            Color(0xFFFFF4EE), // Middle soft peach
            Color(0xFFFAF6F0), // Base color at the bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Scrollable Content Layer
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top Header Row
                  _buildTopHeader(context),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // Banner Carousel (Iftar in 25 min)
                          _buildTopBannerCarousel(controller),
                          const SizedBox(height: 16),

                          // Search Box
                          _buildSearchBox(),
                          const SizedBox(height: 20),

                          // Category Selector Grid
                          _buildCategoryGrid(controller),
                          const SizedBox(height: 24),

                          // Save More Today Section
                          _buildSaveMoreToday(),
                          const SizedBox(height: 24),

                          // Trending in Nouakchott
                          _buildTrendingSection(controller),
                          const SizedBox(height: 24),

                          // Recent Orders
                          _buildRecentOrdersSection(),
                          const SizedBox(height: 24),

                          // Under 30 Minutes
                          _buildUnder30MinSection(controller),
                          const SizedBox(height: 24),

                          // Mid-page Grocery Banner Slider
                          _buildGroceryPromoBanner(controller),
                          const SizedBox(height: 24),

                          // Top Grocery Stores Near You
                          _buildTopGroceryStores(controller),
                          const SizedBox(height: 24),

                          // Mid-page Pharmacy Banner Slider
                          _buildPharmacyPromoBanner(controller),
                          const SizedBox(height: 24),

                          // Trusted Pharmacies
                          _buildTrustedPharmacies(controller),
                          const SizedBox(height: 24),

                          // Mid-page Water Banner Slider
                          _buildWaterPromoBanner(controller),
                          const SizedBox(height: 24),

                          // Top Rated Suppliers (Water)
                          _buildTopRatedSuppliers(controller),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 2. Floating Bottom Navigation Bar Layer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNavigationBar(controller),
            ),
          ],
        ),
      ),
    );
  }

  // Top Header Row
  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Delivery Details
          Image.asset("lib/assets/images/Home.png", width: 22, height: 22),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deliver To',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        SelectLocationController.selectedTitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF2C2520),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Wallet pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '300 MRU',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Notification Bell
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
            ),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF2C2520),
                  size: 20,
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Profile Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF5E00), width: 1.5),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Top Banner Slider
  Widget _buildTopBannerCarousel(HomeController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          "lib/assets/images/Slider.png",
          fit: BoxFit.fill,
          width: double.infinity,
          height: 140,
        ),
      ),
    );
  }

  // Search Box
  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFA59A94),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                style: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'What do you need today?',
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 12.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Image.asset(
              "lib/assets/images/Camera.png",
              width: 20,
              height: 20,
              color: Color(0xFFA59A94),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 249, 210, 187),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "lib/assets/images/Voice.png",
                width: 16,
                height: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Category Selector Grid
  Widget _buildCategoryGrid(HomeController controller) {
    final categories = [
      {
        'label': 'All',
        'icon': "lib/assets/images/All.png",
        'gradient': const LinearGradient(
          colors: [Color(0xFFFE5102), Color(0xFFFFAE00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'label': 'Food',
        'icon': "lib/assets/images/Food.png",
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFF5EC), Color(0xFFFEE6D6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      },
      {
        'label': 'Grocery',
        'icon': "lib/assets/images/Grocery.png",
        'gradient': const LinearGradient(
          colors: [Color(0xFFEBF6EE), Color(0xFFD4EBD9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      },
      {
        'label': 'Pharmacy',
        'icon': "lib/assets/images/Pharmacy.png",
        'gradient': const LinearGradient(
          colors: [Color(0xFFEEF5FC), Color(0xFFD3E5F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      },
      {
        'label': 'Water',
        'icon': "lib/assets/images/Water.png",
        'gradient': const LinearGradient(
          colors: [Color(0xFFE6F7FF), Color(0xFFCBEBFE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      },
      {
        'label': 'Courier',
        'icon': "lib/assets/images/Courier.png",
        'gradient': const LinearGradient(
          colors: [Color(0xFFF7EBF6), Color(0xFFECD2EB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      },
      {
        'label': 'Express',
        'icon': "lib/assets/images/Express.png",
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFFBE6), Color(0xFFFFF1CC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      },
      {
        'label': 'Local Store',
        'icon': "lib/assets/images/Local Store.png",
        'gradient': const LinearGradient(
          colors: [Color(0xFFF6F6F6), Color(0xFFE8E8E8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        itemCount: categories.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.90,
        ),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = index == 0;
          return GestureDetector(
            onTap: () {
              if (cat['label'] == 'Grocery') {
                Get.to(() => const GroceryScreen());
              } else if (cat['label'] == 'Pharmacy') {
                Get.to(() => const PharmacyScreen());
              } else {
                Get.to(
                  () => CategoryScreen(categoryName: cat['label'] as String),
                );
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Card Background (Starts 16px from top)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFFE5102), Color(0xFFFFAE00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : (cat['gradient'] as Gradient?),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      cat['label'] as String,
                      style: GoogleFonts.outfit(
                        color: isSelected
                            ? Colors.white
                            : (index == 0
                                  ? Colors.white
                                  : const Color(0xFF2C2520)),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 2. Overlapping Illustration Image
                Positioned(
                  top: index == 0 ? 22 : 0,
                  left: 4,
                  right: 4,
                  bottom: index == 0 ? 28 : 22,
                  child: index == 0
                      ? Center(
                          child: Image.asset(
                            cat['icon'] as String,
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                        )
                      : Image.asset(cat['icon'] as String, fit: BoxFit.contain),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Save More Today Section
  Widget _buildSaveMoreToday() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Save More Today',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Free Delivery
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "lib/assets/images/FreeDelivery.png",
                    fit: BoxFit.fill,
                    width: 220,
                  ),
                ),
              ),
              // Cashback banner
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  "lib/assets/images/Cashback.png",
                  fit: BoxFit.fill,
                  width: 150,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section header builder utility
  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              if (title.contains('Trending'))
                const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFFFF5E00),
                  size: 18,
                ),
            ],
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  'See All',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFF5E00),
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Trending Section
  Widget _buildTrendingSection(HomeController controller) {
    final trending = [
      {
        'id': 't1',
        'title': 'Al Fantasia',
        'subtitle': 'Moroccan - Traditional',
        'rating': '4.5',
        'time': '30-35 min',
        'dist': '10 Km',
        'discount': '50% OFF',
        'points': '200 Points Available',
        'isTemporarilyClosed': false,
        'image':
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=350&auto=format&fit=crop',
      },
      {
        'id': 't2',
        'title': 'Tarif Restaurant',
        'subtitle': 'Lebanese - Grill',
        'rating': '4.6',
        'time': '30-35 min',
        'dist': '12 Km',
        'discount': '30% OFF',
        'points': '200 Points Available',
        'isTemporarilyClosed': false,
        'image':
            'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=350&auto=format&fit=crop',
      },
    ];

    return Column(
      children: [
        _buildSectionHeader('Trending in Nouakchott', () {}),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trending.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final item = trending[index];
              return _buildRestaurantCard(controller, item);
            },
          ),
        ),
      ],
    );
  }

  // Card view builder for food/restaurants
  Widget _buildRestaurantCard(
    HomeController controller,
    Map<String, dynamic> item,
  ) {
    final isClosed = item['isClosed'] == true || item['isClosed'] == 'true';
    final isTemporarilyClosed =
        item['isTemporarilyClosed'] == true ||
        item['isTemporarilyClosed'] == 'true';
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Badges
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: (item['image'] ?? '').toString().startsWith('http')
                      ? Image.network(
                          (item['image'] ?? '').toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: const Color(0xFFF3EFEA),
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : Image.asset(
                          (item['image'] ?? '').toString(),
                          fit: BoxFit.cover,
                        ),
                ),
                // Discount Overlay
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE03A3A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (item['discount'] ?? '').toString(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Star Rating
                Positioned(
                  top: 10,
                  left: 70,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFAE00),
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (item['rating'] ?? '').toString(),
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Heart Fav Icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Obx(() {
                    final liked = controller.isLiked(
                      (item['id'] ?? '').toString(),
                    );
                    return GestureDetector(
                      onTap: () =>
                          controller.toggleLike((item['id'] ?? '').toString()),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: const Color(0xFFE03A3A),
                          size: 16,
                        ),
                      ),
                    );
                  }),
                ),
                // Gold points tag overlay at bottom of image
                Positioned(
                  bottom: 8,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          "lib/assets/images/Coin.png",
                          width: 12,
                          height: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (item['points'] ?? '').toString(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isClosed) ...[
                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.35)),
                  ),
                  Positioned.fill(
                    child: _buildClosedOverlay(
                      (item['opensAt'] ?? '10 AM').toString(),
                    ),
                  ),
                ] else if (isTemporarilyClosed) ...[
                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.35)),
                  ),
                  Positioned.fill(child: _buildTemporarilyClosedOverlay()),
                ],
              ],
            ),
          ),
          // Info Details
          Opacity(
            opacity: (isClosed || isTemporarilyClosed) ? 0.65 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['title'] ?? '').toString(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (item['subtitle'] ?? '').toString(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF7A6A60),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (item['time'] ?? '').toString(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF7A6A60),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (item['dist'] ?? '').toString(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedOverlay(String opensAt) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD30000),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Closed',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Opens $opensAt',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -3),
            child: Transform.rotate(
              angle: 45 * 3.14159 / 180,
              child: Container(
                width: 8,
                height: 8,
                color: const Color(0xFFD30000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemporarilyClosedOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A00),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Temporarily not accepting',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'orders',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -3),
            child: Transform.rotate(
              angle: 45 * 3.14159 / 180,
              child: Container(
                width: 8,
                height: 8,
                color: const Color(0xFFFF8A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Recent Orders Section
  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View Orders',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Container(
                width: 250,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pizza thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=120&auto=format&fit=crop',
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 54,
                                  height: 54,
                                  color: const Color(0xFFF3EFEA),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Al Fantasia',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF2C2520),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Chiken Tagine (Half) x2 • Chick.....',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF7A6A60),
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: Color(0xFFFF5E00),
                                    size: 11,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Yesterday',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF7A6A60),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '2 Items',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFF5E00),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.refresh_rounded,
                                  color: Color(0xFFFF5E00),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reorder',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFF5E00),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  // Under 30 Minutes
  Widget _buildUnder30MinSection(HomeController controller) {
    final items = [
      {
        'id': 'u1',
        'title': 'Al Fantasia',
        'subtitle': 'Moroccan • Traditional',
        'rating': '4.6',
        'time': '30m',
        'discount': '50% OFF',
        'points': '200 Points Available',
        'isTemporarilyClosed': false,
        'image':
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=350&auto=format&fit=crop',
      },
      {
        'id': 'u2',
        'title': 'Tarif Restaurant',
        'subtitle': 'Lebanese • Grill',
        'rating': '4.6',
        'time': '30m',
        'discount': '50% OFF',
        'points': '200 Points Available',
        'isTemporarilyClosed': false,
        'image':
            'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=350&auto=format&fit=crop',
      },
    ];

    return Column(
      children: [
        _buildSectionHeader(
          'Under 30 Minutes',
          () => Get.to(() => const Under30MinScreen()),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return _buildUnder30MinCard(controller, items[index]);
            },
          ),
        ),
      ],
    );
  }

  // Custom Card for Under 30 Minutes Items
  Widget _buildUnder30MinCard(
    HomeController controller,
    Map<String, dynamic> item,
  ) {
    final isClosed = item['isClosed'] == true || item['isClosed'] == 'true';
    final isTemporarilyClosed =
        item['isTemporarilyClosed'] == true ||
        item['isTemporarilyClosed'] == 'true';
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Badges
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: (item['image'] ?? '').toString().startsWith('http')
                      ? Image.network(
                          (item['image'] ?? '').toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: const Color(0xFFF3EFEA),
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : Image.asset(
                          (item['image'] ?? '').toString(),
                          fit: BoxFit.cover,
                        ),
                ),
                // Discount Overlay
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE03A3A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (item['discount'] ?? '').toString(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Star Rating overlay (top right)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFAE00),
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (item['rating'] ?? '').toString(),
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom overlays: Left Points, Right Delivery Time
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Points Badge with Coin.png
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "lib/assets/images/Coin.png",
                              width: 12,
                              height: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (item['points'] ?? '').toString(),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Time Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              (item['time'] ?? '').toString(),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isClosed) ...[
                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.35)),
                  ),
                  Positioned.fill(
                    child: _buildClosedOverlay(
                      (item['opensAt'] ?? '10 AM').toString(),
                    ),
                  ),
                ] else if (isTemporarilyClosed) ...[
                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.35)),
                  ),
                  Positioned.fill(child: _buildTemporarilyClosedOverlay()),
                ],
              ],
            ),
          ),
          // Info Details
          Opacity(
            opacity: (isClosed || isTemporarilyClosed) ? 0.65 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['title'] ?? '').toString(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (item['subtitle'] ?? '').toString(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 10,
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

  // Mid-page Grocery Promo Banner
  Widget _buildGroceryPromoBanner(HomeController controller) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              "lib/assets/images/Grocery slider.png",
              fit: BoxFit.fill,
              width: double.infinity,
            ),
          ),
        ),
      ],
    );
  }

  // Top Grocery Stores
  Widget _buildTopGroceryStores(HomeController controller) {
    final stores = [
      {
        'id': 'g1',
        'title': 'Salam Supermarket',
        'subtitle': 'Hypermarket',
        'rating': '4.6',
        'time': '35 min',
        'dist': '10 Km',
        'discount': '50% OFF',
        'points': '200 Points Available',
        'image': 'lib/assets/images/Grocery.png',
      },
      {
        'id': 'g2',
        'title': 'Good Choice',
        'subtitle': 'Fruits & Vegetables',
        'rating': '4.5',
        'time': '35 min',
        'dist': '10 Km',
        'discount': '30% OFF',
        'points': '200 Points Available',
        'image':
            'https://images.unsplash.com/photo-1542838132-92c53300491e?w=350&auto=format&fit=crop',
      },
    ];

    return Column(
      children: [
        _buildSectionHeader('Top Grocery Stores Near You', () {}),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return _buildRestaurantCard(controller, stores[index]);
            },
          ),
        ),
      ],
    );
  }

  // Mid-page Pharmacy Promo Banner
  Widget _buildPharmacyPromoBanner(HomeController controller) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              "lib/assets/images/Pharmacy slider.png",
              fit: BoxFit.fill,
              width: double.infinity,
            ),
          ),
        ),
      ],
    );
  }

  // Mid-page Water Promo Banner
  Widget _buildWaterPromoBanner(HomeController controller) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              "lib/assets/images/Water slider.png",
              fit: BoxFit.fill,
              width: double.infinity,
            ),
          ),
        ),
      ],
    );
  }

  // Trusted Pharmacies
  Widget _buildTrustedPharmacies(HomeController controller) {
    final pharmacies = [
      {
        'id': 'p1',
        'title': 'Pharmacy Nasr',
        'subtitle': 'Trusted',
        'rating': '4.6',
        'time': '30-35 min',
        'dist': '10 Km',
        'discount': '50% OFF',
        'points': '200 Points Available',
        'image':
            'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=350&auto=format&fit=crop',
      },
    ];

    return Column(
      children: [
        _buildSectionHeader('Trusted Pharmacies', () {}),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pharmacies.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return _buildRestaurantCard(controller, pharmacies[index]);
            },
          ),
        ),
      ],
    );
  }

  // Top Rated Suppliers (Water)
  Widget _buildTopRatedSuppliers(HomeController controller) {
    final suppliers = [
      {
        'id': 'w1',
        'title': 'PureLife Water Co.',
        'subtitle': 'Premium purified drinking water',
        'rating': '4.6',
        'time': '30-35 min',
        'dist': '10 Km',
        'discount': '50% OFF',
        'points': '200 Points Available',
        'image':
            'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=350&auto=format&fit=crop',
      },
    ];

    return Column(
      children: [
        _buildSectionHeader('Top Rated Suppliers', () {}),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suppliers.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return _buildRestaurantCard(controller, suppliers[index]);
            },
          ),
        ),
      ],
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar(HomeController controller) {
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
        child: Obx(() {
          final selected = controller.currentNavIndex.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                "lib/assets/images/Bottom Home.png",
                'Home',
                selected == 0,
                controller,
              ),
              _buildNavItem(
                1,
                "lib/assets/images/Bottom Search.png",
                'Search',
                selected == 1,
                controller,
              ),
              _buildNavItem(
                2,
                "lib/assets/images/Bottom Order.png",
                'Orders',
                selected == 2,
                controller,
              ),
              _buildNavItem(
                3,
                "lib/assets/images/Bottom Cart.png",
                'Cart',
                selected == 3,
                controller,
                badgeCount: 2,
              ),
              _buildNavItem(
                4,
                "lib/assets/images/Bottom Profile.png",
                'Profile',
                selected == 4,
                controller,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String assetPath,
    String label,
    bool isSelected,
    HomeController controller, {
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () async {
        if (index == 2) {
          controller.selectNavigation(2);
          await Get.to(() => const MyOrdersScreen());
          controller.selectNavigation(0);
        } else if (index == 3) {
          controller.selectNavigation(3);
          await Get.to(() => const CartScreen());
          controller.selectNavigation(0);
        } else {
          controller.selectNavigation(index);
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  assetPath,
                  width: 22,
                  height: 22,
                  color: isSelected
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFA59A94),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E00),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected
                    ? const Color(0xFFFF5E00)
                    : const Color(0xFFA59A94),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF5E00)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
