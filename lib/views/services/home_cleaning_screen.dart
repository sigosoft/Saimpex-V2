import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import '../../navigation/bottom_nav_router.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../select_location_screen.dart';
import 'home_cleaning_provider_detail_screen.dart';

class HomeCleaningScreen extends StatelessWidget {
  const HomeCleaningScreen({super.key});

  static const _categories = [
    {
      'label': 'Deep\nCleaning',
      'image': 'lib/assets/images/Deep Cleaning.png',
    },
    {
      'label': 'Kitchen\nCleaning',
      'image': 'lib/assets/images/Kitchen Cleaning.png',
    },
    {
      'label': 'Bedroom\nCleaning',
      'image': 'lib/assets/images/bedroom_cleaning.png',
    },
    {
      'label': 'Sofa Care',
      'image': 'lib/assets/images/Sofa Cleaning.png',
    },
  ];

  static const _nearbyServices = [
    {
      'name': 'CleanPro Elite',
      'rating': '4.8',
      'distance': '2.4 km away',
      'price': '450',
      'points': '200 Points Available',
      'image': 'lib/assets/images/cleanproelitee.jpg',
    },
    {
      'name': 'Elite Shine',
      'rating': '4.6',
      'distance': '3.1 km away',
      'price': '450',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=600&h=360&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 120 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBannerSection(),
                    const SizedBox(height: 36),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPageTitle(),
                          const SizedBox(height: 22),
                          _buildExploreCategories(),
                          const SizedBox(height: 18),
                          _buildSearchBar(),
                          const SizedBox(height: 22),
                          _buildNearbySection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNavBar(
                selectedIndex: HomeController.navServices,
                onTap: BottomNavRouter.go,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          'lib/assets/images/Home_cleaning_banner.png',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 240,
            color: const Color(0xFFFF5E00),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -30,
          child: _buildLocationCard(),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return GestureDetector(
      onTap: () => Get.to(() => const SelectLocationScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFF2E6DC)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFFF5E00),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT LOCATION',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF9A8E86),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    SelectLocationController.selectedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF2C2520),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title + small orange star as superscript on "Cleaning"
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'Home Cleaning',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A202C),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              const Positioned(
                top: -1,
                right: -2,
                child: Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFF8A65),
                  size: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Soft peach line under title — full width, fades at both edges
          SizedBox(
            width: double.infinity,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFA07A).withValues(alpha: 0),
                    const Color(0xFFFFA07A),
                    const Color(0xFFFFA07A).withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Professional cleaning services at your doorstep',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF718096),
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCategories() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
                'Explore Categories',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'See All',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _categories.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _buildCategoryItem(_categories[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, String> cat) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            cat['image']!,
            width: 66,
            height: 66,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 58,
              height: 58,
              color: const Color(0xFFFFF3EB),
              alignment: Alignment.center,
              child: const Icon(
                Icons.cleaning_services_rounded,
                color: Color(0xFFFF5E00),
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          cat['label']!,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF9A8E86),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: GoogleFonts.outfit(color: Colors.black, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search cleaning services...',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFF9A8E86),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFF0E6),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'lib/assets/images/Voice.png',
              width: 16,
              height: 16,
              color: const Color(0xFFFF5E00),
              errorBuilder: (_, __, ___) => const Icon(
                Icons.settings_voice_rounded,
                color: Color(0xFFFF5E00),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cleaning Services Near You',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'See All',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _nearbyServices.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _buildServiceCard(_nearbyServices[i]),
        ],
      ],
    );
  }

  Widget _providerImageFallback() {
    return Container(
      color: const Color(0xFFFFF3EB),
      alignment: Alignment.center,
      child: Image.asset(
        'lib/assets/images/Home_cleaning.png',
        height: 80,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildServiceCard(Map<String, String> item) {
    return GestureDetector(
      onTap: () => Get.to(
        () => HomeCleaningProviderDetailScreen(provider: item),
      ),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: item['image']!.startsWith('http')
                    ? Image.network(
                        item['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _providerImageFallback(),
                      )
                    : Image.asset(
                        item['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _providerImageFallback(),
                      ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'lib/assets/images/Coin.png',
                        width: 12,
                        height: 12,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.monetization_on,
                          color: Color(0xFFFFAE00),
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['points']!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['name']!,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB800),
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item['rating']!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['distance']!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7A6A60),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Starting from',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF9A8E86),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontWeight: FontWeight.w800,
                              ),
                              children: [
                                TextSpan(
                                  text: item['price'],
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const TextSpan(
                                  text: ' MRU',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(
                        () => HomeCleaningProviderDetailScreen(provider: item),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E00),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5E00)
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'View Services',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}
