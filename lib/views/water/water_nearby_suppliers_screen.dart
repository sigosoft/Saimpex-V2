import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import 'water_product_subscription_screen.dart';

class WaterNearbySuppliersScreen extends StatefulWidget {
  const WaterNearbySuppliersScreen({super.key});

  @override
  State<WaterNearbySuppliersScreen> createState() =>
      _WaterNearbySuppliersScreenState();
}

class _WaterNearbySuppliersScreenState
    extends State<WaterNearbySuppliersScreen> {
  final TextEditingController searchController = TextEditingController();

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
      'cardImage': 'lib/assets/images/19Lbottle.png',
      'headerImage':
          'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=800&auto=format&fit=crop',
      'opensAt': '10 AM',
    },
    {
      'id': 'w2',
      'title': 'AquaPure',
      'subtitle': 'Natural spring water',
      'rating': '4.6',
      'time': '30-35 min',
      'dist': '10 Km',
      'discount': '50% OFF',
      'points': '200 Points Available',
      'cardImage': 'lib/assets/images/bottledwater.png',
      'opensAt': '9 AM',
    },
    {
      'id': 'w3',
      'title': 'AquaFresh Supply',
      'subtitle': 'Mineral & filtered water',
      'rating': '4.5',
      'time': '25-30 min',
      'dist': '8 Km',
      'discount': '40% OFF',
      'points': '180 Points Available',
      'cardImage': 'lib/assets/images/10Lbottle.png',
      'opensAt': '8 AM',
    },
    {
      'id': 'w4',
      'title': 'Crystal Springs',
      'subtitle': 'Natural spring water delivery',
      'rating': '4.7',
      'time': '35-40 min',
      'dist': '12 Km',
      'discount': '30% OFF',
      'points': '220 Points Available',
      'cardImage': 'lib/assets/images/19Lbottle.png',
      'opensAt': '8 AM',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredSuppliers {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return suppliers;
    return suppliers.where((s) {
      final title = (s['title'] ?? '').toString().toLowerCase();
      final subtitle = (s['subtitle'] ?? '').toString().toLowerCase();
      return title.contains(query) || subtitle.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8F0F8),
              Color(0xFFFFF4EE),
              Color(0xFFFFF9F5),
            ],
            stops: [0.0, 0.18, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildStoreMapButton(),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      return _buildSupplierCard(
                        controller,
                        filteredSuppliers[index],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFF5E00),
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Nearby Suppliers',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFA59A94),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search water suppliers',
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFFA59A94),
              size: 18,
            ),
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'lib/assets/images/Voice.png',
                  width: 14,
                  height: 14,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFFFF5E00),
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreMapButton() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Store Map',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.location_on_rounded,
              color: Color(0xFFFF5E00),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierCard(
    HomeController controller,
    Map<String, dynamic> item,
  ) {
    final cardImage =
        (item['cardImage'] ?? 'lib/assets/images/19Lbottle.png').toString();
    final supplierId = (item['id'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        Get.to(
          () => WaterProductSubscriptionScreen(
            supplier: Map<String, dynamic>.from(item),
            product: {
              'title': 'Drinking Water 19L',
              'image': item['cardImage'] ?? 'lib/assets/images/19Lbottle.png',
              'size': '19L',
              'quantity': '1 BOTTLE',
              'rating': item['rating'] ?? '4.6',
              'reviews': '10k + reviews',
              'price': '50 MRU',
              'originalPrice': '100 MRU',
              'discount': item['discount'] ?? '50% OFF',
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 168,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF7AD3F3),
                            Color(0xFF2E9FE6),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                        child: Image.asset(
                          cardImage,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.water_drop_outlined,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5E00),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['discount'] as String,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFAE00),
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                item['rating'] as String,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Obx(() {
                      final liked = controller.isLiked(supplierId);
                      return GestureDetector(
                        onTap: () =>
                            controller.toggleLike(supplierId, item),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: liked
                                ? const Color(0xFFE03A3A)
                                : const Color(0xFF2C2520),
                            size: 17,
                          ),
                        ),
                      );
                    }),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'lib/assets/images/Coin.png',
                            width: 14,
                            height: 14,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.monetization_on,
                              color: Color(0xFFFFAE00),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item['points'] as String,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['subtitle'] as String,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFFFF5E00),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['time'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4A453F),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFFF5E00),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['dist'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4A453F),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
