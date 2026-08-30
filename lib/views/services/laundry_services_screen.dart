import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import '../../navigation/bottom_nav_router.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../select_location_screen.dart';
import 'laundry_provider_detail_screen.dart';

class LaundryServicesScreen extends StatelessWidget {
  const LaundryServicesScreen({super.key});

  static const _quickServices = [
    {
      'label': 'Wash & Fold',
      'image': 'lib/assets/images/Wash & Fold.png',
    },
    {
      'label': 'Ironing',
      'image': 'lib/assets/images/Ironing.png',
    },
    {
      'label': 'Dry Cleaning',
      'image': 'lib/assets/images/Dry Cleaning.png',
    },
    {
      'label': 'Wash & Iron',
      'image': 'lib/assets/images/Wash & Iron.png',
    },
  ];

  static const _nearbyServices = [
    {
      'name': 'CleanPro Laundry',
      'rating': '4.4',
      'distance': '2.4 km away',
      'ready': 'Ready in 24 hours',
      'points': '200 Points Available',
      'tag1': 'Wash & Fold',
      'price1': '150 MRU/kg',
      'tag2': 'Wash & Iron',
      'price2': '200 MRU/kg',
      'image':
          'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=800&h=480&fit=crop',
    },
    {
      'name': 'Oasis Laundry Hub',
      'rating': '4.6',
      'distance': '3.4 km away',
      'ready': 'Ready in 24 hours',
      'points': '200 Points Available',
      'tag1': 'Dry Cleaning',
      'price1': '180 MRU/kg',
      'tag2': 'Ironing',
      'price2': '120 MRU/kg',
      'image':
          'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=800&h=480&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
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
                          const SizedBox(height: 18),
                          _buildQuickServices(),
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
        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 0.72,
            child: Image.asset(
              'lib/assets/images/laundryservices_banner.png',
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                height: 240,
                color: const Color(0xFFFF5E00),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -28,
          child: _buildLocationCard(),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return GestureDetector(
      onTap: () => Get.to(() => const SelectLocationScreen()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5E00).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFFF5E00),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT LOCATION',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF9A8E86),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          SelectLocationController.selectedTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF5A5048),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildFadeLine(fadeTowardStart: true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Laundry Services',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1B2B4A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset(
                    'lib/assets/images/star_icon.png',
                    width: 14,
                    height: 14,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildFadeLine(fadeTowardStart: false)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Professional laundry care delivered to your doorstep',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF7A6A60),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildFadeLine({required bool fadeTowardStart}) {
    const lineColor = Color(0xFFFF8A5C);
    return Container(
      height: 1.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: fadeTowardStart
              ? [
                  lineColor.withValues(alpha: 0),
                  lineColor,
                ]
              : [
                  lineColor,
                  lineColor.withValues(alpha: 0),
                ],
        ),
      ),
    );
  }

  Widget _buildQuickServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Services',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _quickServices.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _buildQuickServiceItem(_quickServices[i])),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickServiceItem(Map<String, String> item) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            item['image']!,
            width: 66,
            height: 66,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 66,
              height: 66,
              color: const Color(0xFFFFF3EB),
              alignment: Alignment.center,
              child: const Icon(
                Icons.local_laundry_service_rounded,
                color: Color(0xFFFF5E00),
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item['label']!,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
                hintText: 'Search services...',
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
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFF1E6),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'lib/assets/images/Voice.png',
              width: 15,
              height: 15,
              color: const Color(0xFFFF5E00),
              errorBuilder: (_, __, ___) => const Icon(
                Icons.mic_rounded,
                color: Color(0xFFFF5E00),
                size: 16,
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
            Expanded(
              child: Text(
                'Laundry Services Near You',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
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
          _buildProviderCard(_nearbyServices[i]),
        ],
      ],
    );
  }

  Widget _providerImageFallback() {
    return Container(
      color: const Color(0xFFFFF3EB),
      alignment: Alignment.center,
      child: Image.asset(
        'lib/assets/images/laundry.png',
        height: 80,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildProviderCard(Map<String, String> item) {
    return GestureDetector(
      onTap: () => Get.to(
        () => LaundryProviderDetailScreen(provider: item),
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
                child: Image.network(
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
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF9A8E86),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item['ready']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _serviceTag(item['tag1']!, item['price1']!),
                    _serviceTag(item['tag2']!, item['price2']!),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Get.to(
                      () => LaundryProviderDetailScreen(provider: item),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E00),
                        borderRadius: BorderRadius.circular(30),
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
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _serviceTag(String label, String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(color: Color(0xFF5A5048)),
            ),
            const TextSpan(
              text: '  •  ',
              style: TextStyle(color: Color(0xFFFF5E00)),
            ),
            TextSpan(
              text: price,
              style: const TextStyle(color: Color(0xFF5A5048)),
            ),
          ],
        ),
      ),
    );
  }
}
