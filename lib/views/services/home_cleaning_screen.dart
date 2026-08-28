import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/select_location_controller.dart';
import '../select_location_screen.dart';

class HomeCleaningScreen extends StatelessWidget {
  const HomeCleaningScreen({super.key});

  static const _categories = [
    {
      'label': 'Deep Cleaning',
      'image':
          'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=200&h=200&fit=crop',
    },
    {
      'label': 'Kitchen Cleaning',
      'image':
          'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=200&h=200&fit=crop',
    },
    {
      'label': 'Bedroom Cleaning',
      'image':
          'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=200&h=200&fit=crop',
    },
    {
      'label': 'Sofa Care',
      'image':
          'https://images.unsplash.com/photo-1555041469-a586c12e1942?w=200&h=200&fit=crop',
    },
  ];

  static const _nearbyServices = [
    {
      'name': 'CleanPro Elite',
      'rating': '4.6',
      'distance': '2.4 km away',
      'price': '450',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=600&h=360&fit=crop',
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
    final topInset = MediaQuery.viewPaddingOf(context).top;
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
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: 32 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBannerSection(topInset),
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
    );
  }

  Widget _buildBannerSection(double topInset) {
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
          top: topInset + 8,
          left: 16,
          child: _buildBackButton(),
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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
    );
  }

  Widget _buildLocationCard() {
    return GestureDetector(
      onTap: () => Get.to(() => const SelectLocationScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
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
                Icons.location_on_rounded,
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildFadeLine(fadeFromStart: true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Home Cleaning',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
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
                      Icons.star_rounded,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildFadeLine(fadeFromStart: false)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Professional cleaning services at your doorstep',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF7A6A60),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFadeLine({required bool fadeFromStart}) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: fadeFromStart
              ? [
                  Colors.transparent,
                  const Color(0xFFEAD8C9),
                ]
              : [
                  const Color(0xFFEAD8C9),
                  Colors.transparent,
                ],
        ),
      ),
    );
  }

  Widget _buildExploreCategories() {
    return Column(
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _categories.map((cat) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFE0CC),
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(cat['image']!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                        color: const Color(0xFFFFF3EB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['label']!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
        border: Border.all(color: const Color(0xFFEAD8C9), width: 1.2),
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
                hintText: 'Search cleaning services...',
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF5E00),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'lib/assets/images/Voice.png',
              width: 15,
              height: 15,
              color: Colors.white,
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

  Widget _buildServiceCard(Map<String, String> item) {
    return Container(
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
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFFFF3EB),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'lib/assets/images/Home_cleaning.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E00),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5E00).withValues(alpha: 0.25),
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
