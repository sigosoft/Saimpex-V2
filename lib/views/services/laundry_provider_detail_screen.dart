import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../chat_screen.dart';
import '../../widgets/bottom_chat_icon.dart';
import 'laundry_dry_cleaning_screen.dart';
import 'laundry_service_configure_screen.dart';

class LaundryProviderDetailScreen extends StatefulWidget {
  final Map<String, String> provider;

  const LaundryProviderDetailScreen({
    super.key,
    required this.provider,
  });

  @override
  State<LaundryProviderDetailScreen> createState() =>
      _LaundryProviderDetailScreenState();
}

class _LaundryProviderDetailScreenState
    extends State<LaundryProviderDetailScreen> {
  int _selectedTab = 0;
  int _reviewFilter = 0;

  static const _tabs = ['Services', 'Reviews', 'About'];
  static const _reviewFilters = ['All Reviews', 'Most Recent', 'Highest Rated'];

  static const _ratingBreakdown = [
    {'star': '5', 'pct': 0.75, 'count': '7,542'},
    {'star': '4', 'pct': 0.32, 'count': '1,210'},
    {'star': '3', 'pct': 0.14, 'count': '452'},
    {'star': '2', 'pct': 0.06, 'count': '190'},
    {'star': '1', 'pct': 0.03, 'count': '86'},
  ];

  static const _reviews = [
    {
      'name': 'Aicha Mint Ahmed',
      'time': '2 days ago',
      'rating': 5,
      'avatar':
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&h=100&fit=crop',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    },
    {
      'name': 'Aicha Mint Ahmed',
      'time': '2 days ago',
      'rating': 5,
      'avatar':
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&h=100&fit=crop',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    },
  ];

  static const _services = [
    {
      'title': 'Wash & Fold',
      'description': 'Fresh washing, drying and folding',
      'price': '150 MRU/kg',
      'duration': '1 Day',
      'action': 'ADD',
      'image': 'lib/assets/images/wash&fold_detail.png',
    },
    {
      'title': 'Wash & Iron',
      'description': 'Clean, pressed and ready to wear',
      'price': '200 MRU/kg',
      'duration': '1 Day',
      'action': 'ADD',
      'image': 'lib/assets/images/Wash & Iron.png',
    },
    {
      'title': 'Dry Cleaning',
      'description': 'Professional care for delicate garments',
      'price': 'Starting from 30 MRU',
      'duration': '',
      'action': 'View Prices',
      'image': 'lib/assets/images/drycleaning_detail.png',
    },
    {
      'title': 'Ironing',
      'description': 'Professional ironing service',
      'price': '150 MRU/kg',
      'duration': '1 Day',
      'action': 'ADD',
      'image': 'lib/assets/images/Ironing.png',
    },
  ];

  String get _name => widget.provider['name'] ?? 'CleanPro Laundry';
  String get _rating => widget.provider['rating'] ?? '4.8';
  String get _distance => widget.provider['distance'] ?? '2.4 km away';
  String get _banner =>
      widget.provider['image'] ??
      'lib/assets/images/wash&fold_detail.png';

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
          padding: EdgeInsets.only(bottom: 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(topInset),
              const SizedBox(height: 14),
              _buildTabs(),
              if (_selectedTab == 0) _buildServicesList(),
              if (_selectedTab == 1) _buildReviewsTab(),
              if (_selectedTab == 2) _buildAbout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double topInset) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 210,
          width: double.infinity,
          child: _buildBannerImage(),
        ),
        Positioned(
          top: topInset + 8,
          left: 16,
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 105, 16, 0),
          child: _buildInfoCard(),
        ),
      ],
    );
  }

  Widget _buildBannerImage() {
    final isAsset = _banner.startsWith('lib/');
    if (isAsset) {
      return Image.asset(
        _banner,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 210,
        errorBuilder: (_, __, ___) => _bannerFallback(),
      );
    }
    return Image.network(
      _banner,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 210,
      errorBuilder: (_, __, ___) => _bannerFallback(),
    );
  }

  Widget _bannerFallback() {
    return Container(
      color: const Color(0xFFFFE8DC),
      alignment: Alignment.center,
      child: Image.asset(
        'lib/assets/images/laundry.png',
        height: 80,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.local_laundry_service_rounded,
          color: Color(0xFFFF5E00),
          size: 48,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _name,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFB800),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$_rating (126 Reviews)',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF7A6A60),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFFF5E00),
                size: 15,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  _distance,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF1A6BB5),
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                'Open until 11:00 PM',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A6BB5),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Get.to(
              () => ChatScreen(
                restaurant: {
                  'name': _name,
                  'title': _name,
                  'image': _banner,
                },
              ),
            ),
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BottomChatIcon(
                    size: 17,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Chat',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

  Widget _buildTabs() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            _tabs[i],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: _selectedTab == i
                                  ? const Color(0xFFFF5E00)
                                  : const Color(0xFF9A8E86),
                              fontSize: 14,
                              fontWeight: _selectedTab == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 2.5,
                          width: _selectedTab == i ? 64 : 0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5E00),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFEDE4DA),
        ),
      ],
    );
  }

  Widget _buildServicesList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          for (var i = 0; i < _services.length; i++) ...[
            _buildServiceItem(_services[i]),
            if (i < _services.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFEDE4DA),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, String> item) {
    final isViewPrices = item['action'] == 'View Prices';
    final duration = item['duration'] ?? '';

    void openConfigure() {
      if (isViewPrices || item['title'] == 'Dry Cleaning') {
        Get.to(
          () => LaundryDryCleaningScreen(
            service: {
              ...item,
              'image': 'lib/assets/images/drycleaning_detail.png',
            },
            providerName: _name,
          ),
        );
        return;
      }
      Get.to(
        () => LaundryServiceConfigureScreen(
          service: item,
          providerName: _name,
        ),
      );
    }

    return GestureDetector(
      onTap: openConfigure,
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              item['image']!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: const Color(0xFFFFF3EB),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.local_laundry_service_rounded,
                  color: Color(0xFFFF5E00),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']!,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['description']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['price']!,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (duration.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF9A8E86),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        duration,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF9A8E86),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isViewPrices)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFFF5E00),
                  width: 1.3,
                ),
              ),
              child: Text(
                'View Prices',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: openConfigure,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'ADD',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildReviewsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingSummaryCard(),
          const SizedBox(height: 14),
          _buildReviewFilters(),
          const SizedBox(height: 14),
          for (var i = 0; i < _reviews.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildReviewCard(_reviews[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B25C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _rating,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '9,480 Reviews',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF9A8E86),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final row in _ratingBreakdown) ...[
                  _ratingBar(
                    row['star'] as String,
                    row['pct'] as double,
                    row['count'] as String,
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(String star, double pct, String count) {
    return Row(
      children: [
        Text(
          star,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1B2B4A),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFFFE8DC)),
                  FractionallySizedBox(
                    widthFactor: pct.clamp(0.0, 1.0),
                    child: Container(color: const Color(0xFFFF5E00)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            count,
            textAlign: TextAlign.end,
            style: GoogleFonts.outfit(
              color: const Color(0xFF9A8E86),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < _reviewFilters.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _reviewFilter = i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: _reviewFilter == i
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _reviewFilters[i],
                  style: GoogleFonts.outfit(
                    color: _reviewFilter == i
                        ? Colors.white
                        : const Color(0xFFFF5E00),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] as int;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.network(
                  review['avatar'] as String,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40,
                    height: 40,
                    color: const Color(0xFFFFF3EB),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFFFF5E00),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'] as String,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1B2B4A),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review['time'] as String,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < rating
                        ? const Color(0xFFFF5E00)
                        : const Color(0xFFE0D6CC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review['text'] as String,
            style: GoogleFonts.outfit(
              color: const Color(0xFF5A5048),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About $_name',
              style: GoogleFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$_name offers professional wash & fold, wash & iron, dry cleaning, and ironing services with doorstep pickup and delivery. Fresh laundry, expert care, and reliable turnaround times.',
              style: GoogleFonts.outfit(
                color: const Color(0xFF5A5048),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
