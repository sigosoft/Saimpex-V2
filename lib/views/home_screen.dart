import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/home_controller.dart';
import '../controllers/select_location_controller.dart';
import '../core/network/api_constants.dart';
import 'category_screen.dart';
import 'water/water_screen.dart';
import 'grocery/grocery_screen.dart';
import 'pharmacy/pharmacy_screen.dart';
import 'express/express_screen.dart';
import 'courier/courier_screen.dart';
import 'local_store/local_store_screen.dart';
import 'under_30_min_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/see_all_button.dart';
import 'main_shell_screen.dart';
import 'widgets/chatbot_head.dart';
import 'widgets/home_search_box.dart';

class HomeScreen extends StatelessWidget {
  final bool showBottomNav;

  const HomeScreen({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Container(
        color: const Color(0xFFFAF6F0),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // 1. Scrollable Content Layer
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFDDCC9),
                                  Color(0xFFFDDCC9),
                                  Color(0xFFFAF6F0),
                                ],
                                stops: [0.0, 0.62, 1.0],
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildTopBlendContainer(context, controller),
                                _buildCategoryGrid(controller),
                              ],
                            ),
                          ),

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
              // 2. Floating Bottom Navigation Bar Layer
              if (showBottomNav)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomNavigationBar(controller),
                ),

              // 3. AI Chatbot Head (draggable overlay)
              const Positioned.fill(
                child: ChatBotHead(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header through search, with orange in the top-right and bottom-left.
  Widget _buildTopBlendContainer(
    BuildContext context,
    HomeController controller,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: Color(0xFFFDDCC9)),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.05, -0.2),
                  radius: 1.15,
                  colors: [
                    Color(0xF2FFFFFF),
                    Color(0x00FFFFFF),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color.fromARGB(255, 255, 133, 62).withValues(alpha: 0.95),
                    const Color.fromARGB(255, 255, 102, 0).withValues(alpha: 0.42),
                    const Color.fromARGB(255, 255, 137, 58).withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF5E00).withValues(alpha: 0.92),
                    const Color(0xFFFF8A3D).withValues(alpha: 0.4),
                    const Color(0xFFFF8A3D).withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            child: Column(
              children: [
                _buildTopHeader(context),
                const SizedBox(height: 10),
                const _HomeTopBannerCarousel(),
                const SizedBox(height: 16),
                _buildSearchBox(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
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
                  'Deliver To:',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Obx(
                        () => Text(
                          SelectLocationController.deliveryLabel.value,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF2C2520),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Wallet pill badge
          Container(
            height: 36,
            padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'lib/assets/images/wallet_home.png',
                    width: 16,
                    height: 16,
                  ),
                ),
                const SizedBox(width:3),
                Obx(() {
                  final home = Get.find<HomeController>();
                  final label = home.homeLoaded.value ? home.walletLabel : '';
                  if (label.isEmpty) return const SizedBox.shrink();
                  return Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Notification Bell
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
            ),
            child: Obx(() {
              final count = Get.find<HomeController>().unreadNotifications.value;
              final loaded = Get.find<HomeController>().homeLoaded.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF2C2520),
                    size: 24,
                  ),
                  if (loaded && count > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5E00),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(width: 10),
          // Profile Avatar
          const _HomeAvatar(),
        ],
      ),
    );
  }


  // Search Box
  Widget _buildSearchBox() {
    return const HomeSearchBox();
  }

  // Category Selector Grid
  Widget _buildCategoryGrid(HomeController controller) {
    return Obx(() {
      if (controller.homeLoading.value && !controller.homeLoaded.value) {
        return const SizedBox(
          height: 120,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF5E00),
              ),
            ),
          ),
        );
      }
      if (!controller.homeLoaded.value) return const SizedBox.shrink();
      return _categoryGrid(controller, _verticalTiles(controller));
    });
  }


  Widget _categoryGrid(
    HomeController controller,
    List<Map<String, dynamic>> categories,
  ) {
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
          final slug = (cat['slug'] ?? '').toString();
          final isSelected = slug == 'all';
          return GestureDetector(
            onTap: () => _openHomeVertical(
              slug,
              (cat['label'] ?? '').toString(),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Card Background (Starts 16px from top)
                Positioned(
                  top: 22,
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
                            : const Color(0xFF2C2520),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 2. Overlapping Illustration Image
                Positioned(
                  top: isSelected ? 22 : 0,
                  left: 4,
                  right: 4,
                  bottom: isSelected ? 28 : 22,
                  child: isSelected
                      ? Center(
                          child: Image.asset(
                            cat['icon'] as String,
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                        )
                      : _verticalIcon(cat),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _homeBusy(HomeController controller) =>
      controller.homeLoading.value && !controller.homeLoaded.value;

  List<Map<String, dynamic>> _verticalTiles(HomeController controller) {
    const icons = <String, String>{
      'all': 'lib/assets/images/All.png',
      'food': 'lib/assets/images/Food.png',
      'grocery': 'lib/assets/images/Grocery.png',
      'pharmacy': 'lib/assets/images/Pharmacy.png',
      'water': 'lib/assets/images/Water.png',
      'courier': 'lib/assets/images/Courier.png',
      'express': 'lib/assets/images/Express.png',
      'local_store': 'lib/assets/images/Local Store.png',
      'services': 'lib/assets/images/cleaning_services.png',
    };
    final tiles = <Map<String, dynamic>>[];
    for (final vertical in controller.homeVerticals) {
      final slug = vertical['slug']?.toString() ?? '';
      if (vertical['parentId'] != null && slug != 'local_store') continue;
      final remote = vertical['icon']?.toString() ?? '';
      tiles.add({
        'label': (vertical['label']?.toString().isNotEmpty ?? false)
            ? vertical['label'].toString()
            : slug,
        'slug': slug,
        'icon': remote.startsWith('http')
            ? remote
            : (icons[slug] ?? 'lib/assets/images/All.png'),
        'gradient': _verticalGradient(slug),
      });
    }
    final expressIndex = tiles.indexWhere((tile) => tile['slug'] == 'express');
    final localIndex = tiles.indexWhere(
      (tile) => tile['slug'] == 'local_store',
    );
    if (expressIndex >= 0 && localIndex >= 0 && localIndex != expressIndex + 1) {
      final local = tiles.removeAt(localIndex);
      final insertAt = tiles.indexWhere((tile) => tile['slug'] == 'express');
      tiles.insert(insertAt + 1, local);
    }
    return tiles;
  }

  LinearGradient _verticalGradient(String slug) {
    const soft = <String, Color>{
      'food': Color.fromARGB(255, 247, 176, 114),
      'grocery': Color.fromARGB(255, 161, 229, 82),
      'pharmacy': Color.fromARGB(255, 184, 235, 255),
      'water': Color.fromARGB(255, 118, 212, 255),
      'courier': Color.fromARGB(255, 245, 173, 239),
      'express': Color.fromARGB(255, 255, 165, 10),
      'local_store': Color.fromARGB(255, 177, 159, 137),
      'services': Color.fromARGB(255, 196, 176, 245),
    };
    if (slug == 'all') {
      return const LinearGradient(
        colors: [Color(0xFFFE5102), Color(0xFFFFAE00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors: [soft[slug] ?? const Color(0xFFE7DDD4), Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  Widget _verticalIcon(Map<String, dynamic> cat) {
    final icon = (cat['icon'] ?? '').toString();
    if (icon.startsWith('http')) {
      return Image.network(
        icon,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.category_outlined),
      );
    }
    return Image.asset(icon, fit: BoxFit.contain);
  }

  void _openHomeVertical(String slug, String label) {
    final controller = Get.find<HomeController>();
    switch (slug) {
      case 'grocery':
        Get.to(() => const GroceryScreen());
      case 'pharmacy':
        Get.to(() => const PharmacyScreen());
      case 'water':
        Get.to(() => const WaterScreen());
      case 'express':
        Get.to(() => const ExpressScreen());
      case 'courier':
        Get.to(() => const CourierScreen());
      case 'local_store':
        Get.to(() => const LocalStoreScreen());
      case 'services':
        controller.selectNavigation(HomeController.navServices);
      case 'food':
        controller.selectSubcategory(0);
        Get.to(() => const CategoryScreen(categoryName: 'Food'));
      case 'all':
        Get.to(() => const CategoryScreen(categoryName: 'All'));
      default:
        if (label.isEmpty) return;
        Get.to(() => CategoryScreen(categoryName: label));
    }
  }

  void _openSeeAll(HomeController controller, String target) {
    switch (target) {
      case 'orders':
        controller.goToOrdersTab();
      case 'grocery':
        Get.to(() => const GroceryScreen());
      case 'pharmacy':
        Get.to(() => const PharmacyScreen());
      case 'water':
        Get.to(() => const WaterScreen());
      case 'food':
        controller.selectSubcategory(0);
        Get.to(
          () => const CategoryScreen(
            categoryName: 'Food',
            showUnder30Minutes: false,
          ),
        );
      default:
        break;
    }
  }

  Widget _vendorSection(
    HomeController controller, {
    required String sectionKey,
    required List<Map<String, dynamic>> items,
    bool under30 = false,
  }) {
    final title = controller.sectionTitle(sectionKey);
    final seeAll = controller.sectionSeeAll(sectionKey);
    if (title.isEmpty && items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        if (title.isNotEmpty)
          _buildSectionHeader(
            title,
            seeAll.isEmpty ? null : () => _openSeeAll(controller, seeAll),
          ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: under30 ? 230 : 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                return under30
                    ? _buildUnder30MinCard(controller, item)
                    : _buildRestaurantCard(controller, item);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _apiBanner(HomeController controller, String section) {
    final banner = controller.bannerFor(section);
    if (banner == null) return const SizedBox.shrink();
    final title = (banner['title'] ?? '').toString();
    final subtitle = (banner['subtitle'] ?? '').toString();
    final cta = (banner['cta'] ?? '').toString();
    final image = banner['image']?.toString() ?? '';
    return GestureDetector(
      onTap: () => _openHomeVertical((banner['link'] ?? '').toString(), ''),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A3D), Color(0xFFFF5E00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image.startsWith('http'))
              Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (cta.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        cta,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Save More Today Section
  Widget _buildSaveMoreToday() {
    return Obx(() {
      final home = Get.find<HomeController>();
      if (_homeBusy(home)) return const SizedBox.shrink();
      if (home.homeLoaded.value) {
        if (home.homePromos.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: home.homePromos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final image = (home.homePromos[index]['image'] ?? '').toString();
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  image,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              );
            },
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  // Section header builder utility
  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
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
          if (onSeeAll != null) SeeAllButton(onTap: onSeeAll),
        ],
      ),
    );
  }

  // Trending Section
  Widget _buildTrendingSection(HomeController controller) {
    return Obx(() {
      if (_homeBusy(controller)) return const SizedBox.shrink();
      if (controller.homeLoaded.value) {
        return _vendorSection(
          controller,
          sectionKey: 'trending',
          items: controller.homeTrending.toList(),
        );
      }
      return const SizedBox.shrink();
    });
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
                if ((item['discount'] ?? '').toString().trim().isNotEmpty)
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
                      onTap: () => controller.toggleLike(
                        (item['id'] ?? '').toString(),
                        item,
                      ),
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
                if ((item['points'] ?? '').toString().trim().isNotEmpty)
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
          ColoredBox(
            color: (isClosed || isTemporarilyClosed)
                ? const Color(0xFFC4BBB3)
                : Colors.white,
            child: Opacity(
              opacity: (isClosed || isTemporarilyClosed) ? 0.85 : 1.0,
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
                          Icons.timer_outlined,
                          color: Color(0xFFFF5E00),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (item['time'] ?? '').toString(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF4A453F),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFFF5E00),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (item['dist'] ?? '').toString(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF4A453F),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
    final controller = Get.find<HomeController>();
    return Obx(() {
      if (_homeBusy(controller)) return const SizedBox.shrink();
      if (controller.homeLoaded.value) {
        final title = controller.sectionTitle('recent_orders');
        final orders = controller.homeRecentOrders.toList();
        final seeAll = controller.sectionSeeAll('recent_orders');
        if (title.isEmpty && orders.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (seeAll.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openSeeAll(controller, seeAll),
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
            if (orders.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return _buildRecentOrderCard(orders[index]);
                  },
                ),
              ),
            ],
          ],
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildRecentOrderCard(Map order) {
    String textOf(String key) => (order[key] ?? '').toString();
    final image = textOf('image');
    return Container(
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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: image.startsWith('http')
                    ? Image.network(
                        image,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 54,
                          height: 54,
                          color: const Color(0xFFF3EFEA),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ),
                      )
                    : Container(
                        width: 54,
                        height: 54,
                        color: const Color(0xFFF3EFEA),
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
                            textOf('title'),
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
                          textOf('rating'),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: textOf('itemPrefix'),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF7A6A60),
                              fontSize: 10,
                            ),
                          ),
                          TextSpan(
                            text: textOf('qty'),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: textOf('itemSuffix'),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF7A6A60),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                          textOf('date'),
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
                textOf('itemsCount'),
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
    );
  }

  // Under 30 Minutes
  Widget _buildUnder30MinSection(HomeController controller) {
    return Obx(() {
      if (_homeBusy(controller)) return const SizedBox.shrink();
      if (controller.homeLoaded.value) {
        return _vendorSection(
          controller,
          sectionKey: 'under_30_minutes',
          items: controller.homeUnder30.toList(),
          under30: true,
        );
      }
      return const SizedBox.shrink();
    });
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
                if ((item['discount'] ?? '').toString().trim().isNotEmpty)
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
                      if ((item['points'] ?? '').toString().trim().isNotEmpty)
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

  // Mid-page Grocery Promo Banner (slider)
  Widget _buildGroceryPromoBanner(HomeController controller) {
    return Obx(() {
      if (_homeBusy(controller)) return const SizedBox.shrink();
      if (controller.homeLoaded.value) {
        return _apiBanner(controller, 'grocery');
      }
      return const SizedBox.shrink();
    });
  }

  // Top Grocery Stores
  Widget _buildTopGroceryStores(HomeController controller) {
    return Obx(() {
      if (_homeBusy(controller)) return const SizedBox.shrink();
      if (controller.homeLoaded.value) {
        return _vendorSection(
          controller,
          sectionKey: 'top_grocery',
          items: controller.homeTopGrocery.toList(),
        );
      }
      return const SizedBox.shrink();
    });
  }

  // Mid-page Pharmacy Promo Banner (slider)
  Widget _buildPharmacyPromoBanner(HomeController controller) {
    return Obx(() {
      if (_homeBusy(controller)) return const SizedBox.shrink();
      if (controller.homeLoaded.value) {
        return _apiBanner(controller, 'pharmacy');
      }
      return const SizedBox.shrink();
    });
  }

  // Mid-page Water Promo Banner (slider)
  Widget _buildWaterPromoBanner(HomeController controller) {
    return Obx(() {
      if (_homeBusy(controller)) return const SizedBox.shrink();
      if (controller.homeLoaded.value) {
        return _apiBanner(controller, 'water');
      }
      return const SizedBox.shrink();
    });
  }


  // Trusted Pharmacies
  Widget _buildTrustedPharmacies(HomeController controller) {
    return Obx(() {
      if (_homeBusy(controller)) return const SizedBox.shrink();
      if (controller.homeLoaded.value) {
        return _vendorSection(
          controller,
          sectionKey: 'trusted_pharmacies',
          items: controller.homeTrusted.toList(),
        );
      }
      return const SizedBox.shrink();
    });
  }


  // Top Rated Suppliers (Water)
  Widget _buildTopRatedSuppliers(HomeController controller) {
    return Obx(() {
      if (_homeBusy(controller)) return const SizedBox.shrink();
      if (controller.homeLoaded.value) {
        return _vendorSection(
          controller,
          sectionKey: 'top_rated_suppliers',
          items: controller.homeSuppliers.toList(),
        );
      }
      return const SizedBox.shrink();
    });
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar(HomeController controller) {
    return Obx(
      () => AppBottomNavBar(
        selectedIndex: controller.currentNavIndex.value,
        onTap: (index) {
          if (index == 0) {
            controller.selectNavigation(0);
            return;
          }
          // Standalone home — jump into shell at the chosen tab
          controller.selectNavigation(index);
          Get.offAll(
            () => const MainShellScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }
}

class _HomeTopBannerCarousel extends StatefulWidget {
  const _HomeTopBannerCarousel();

  @override
  State<_HomeTopBannerCarousel> createState() => _HomeTopBannerCarouselState();
}

class _HomeTopBannerCarouselState extends State<_HomeTopBannerCarousel> {
  static const _dotCount = 4;

  final PageController _pageController = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.animateToPage(
        _index + 1,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return Obx(() {
      if (home.homeLoading.value && !home.homeLoaded.value) {
        return const SizedBox.shrink();
      }
      if (home.homeLoaded.value) {
        final slides = home.homeSliders;
        if (slides.isEmpty) return const SizedBox.shrink();
        if (slides.length == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                (slides.first['image'] ?? '').toString(),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(height: 140),
              ),
            ),
          );
        }
      }
      return const SizedBox.shrink();
    });
  }
}

class _HomeAvatar extends StatelessWidget {
  const _HomeAvatar();

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return Obx(() {
      final imageUrl = ApiConstants.mediaUrl(home.profileImage.value);
      if (imageUrl == null) return const _HomePersonIcon();
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _HomePersonIcon(),
        ),
      );
    });
  }
}

class _HomePersonIcon extends StatelessWidget {
  const _HomePersonIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFF5E00), width: 1.5),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFFFF5E00),
        size: 22,
      ),
    );
  }
}
