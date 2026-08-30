import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../chat_screen.dart';
import 'home_cleaning_service_configure_screen.dart';

class HomeCleaningProviderDetailScreen extends StatefulWidget {
  final Map<String, String> provider;

  const HomeCleaningProviderDetailScreen({
    super.key,
    required this.provider,
  });

  @override
  State<HomeCleaningProviderDetailScreen> createState() =>
      _HomeCleaningProviderDetailScreenState();
}

class _HomeCleaningProviderDetailScreenState
    extends State<HomeCleaningProviderDetailScreen> {
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
      'title': 'Regular Cleaning',
      'description':
          'Standard cleaning for bedrooms, bathrooms, living...',
      'price': '550 MRU',
      'duration': '1 hr 30 min',
      'image': 'lib/assets/images/regular_cleaning.jpg',
      'isNetwork': 'false',
    },
    {
      'title': 'Deep Cleaning',
      'description':
          'Thorough cleaning including inside cabinets, appliances,...',
      'price': '550 MRU',
      'duration': '5 hr 30 min',
      'image': 'lib/assets/images/Deep Cleaning.png',
      'isNetwork': 'false',
    },
    {
      'title': 'Kitchen Cleaning',
      'description':
          'Focused degreasing and sanitizing of all kitchen...',
      'price': '550 MRU',
      'duration': '1 hr 30 min',
      'image': 'lib/assets/images/Kitchen Cleaning.png',
      'isNetwork': 'false',
    },
  ];

  String get _name => widget.provider['name'] ?? 'CleanPro Elite';
  String get _rating => widget.provider['rating'] ?? '4.8';
  String get _distance => widget.provider['distance'] ?? '2.4 km away';
  String get _banner =>
      widget.provider['image'] ??
      'lib/assets/images/cleanproelitee.jpg';

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
          ),
        ),
        Padding(
          // Start header card from the center of the banner (210 / 2)
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
        errorBuilder: (_, __, ___) => Image.asset(
          'lib/assets/images/cleanproelitee.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: 210,
        ),
      );
    }
    return Image.network(
      _banner,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 210,
      errorBuilder: (_, __, ___) => Image.asset(
        'lib/assets/images/cleanproelitee.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: 210,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _name,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
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
                  color: const Color(0xFF2C2520),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFFF5E00),
                size: 15,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  _distance,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF1A3A6B),
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                'Open until 8:00 PM',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A3A6B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                borderRadius: BorderRadius.circular(14),
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
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chat',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: item['isNetwork'] == 'true'
                ? Image.network(
                    item['image']!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _serviceImageFallback(),
                  )
                : Image.asset(
                    item['image']!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _serviceImageFallback(),
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
                    color: const Color(0xFF2C2520),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['description']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Starting from',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item['price']!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF9A8E86),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item['duration']!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: GestureDetector(
              onTap: () => Get.to(
                () => HomeCleaningServiceConfigureScreen(
                  service: item,
                  providerName: _name,
                ),
              ),
              child: _buildAddButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceImageFallback() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFFFF3EB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.cleaning_services_rounded,
        color: Color(0xFFFF5E00),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5E00).withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'ADD',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
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
                    const SizedBox(width: 3),
                    Text(
                      '4.6',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index == 4 ? Icons.star_half_rounded : Icons.star_rounded,
                    color: const Color(0xFFFFAE00),
                    size: 15,
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                '126 Reviews',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF9A8E86),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Container(
            width: 1,
            height: 100,
            color: const Color(0xFFEDE6DF),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < _ratingBreakdown.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _buildBreakdownRow(
                    _ratingBreakdown[i]['star'] as String,
                    _ratingBreakdown[i]['pct'] as double,
                    _ratingBreakdown[i]['count'] as String,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String star, double pct, String count) {
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
          const SizedBox(height: 12),
          Text(
            review['text'] as String,
            style: GoogleFonts.outfit(
              color: const Color(0xFF7A6A60),
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Text(
        '$_name provides professional home cleaning services with trained staff, eco-friendly products, and on-time service. Trusted by hundreds of customers across Nouakchott.',
        style: GoogleFonts.outfit(
          color: const Color(0xFF5A5048),
          fontSize: 13.5,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
