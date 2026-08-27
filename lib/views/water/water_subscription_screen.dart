import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterSubscriptionScreen extends StatelessWidget {
  const WaterSubscriptionScreen({super.key});

  static const _steps = [
    {
      'image': 'lib/assets/images/supplier.png',
      'title': 'Choose Supplier',
      'subtitle': 'Browse top-rated local water providers in your location',
    },
    {
      'image': 'lib/assets/images/water_glass.png',
      'title': 'Select Products',
      'subtitle': 'Pick your preferred bottle sizes and water mineral balance',
    },
    {
      'image': 'lib/assets/images/star.png',
      'title': 'Choose a Delivery Plan',
      'subtitle':
          'Select any subscription plan like daily, weekly or monthly',
    },
    {
      'image': 'lib/assets/images/schedule.png',
      'title': 'Choose Schedule',
      'subtitle':
          'Set your delivery days and preferred morning or evening slots.',
    },
    {
      'title': 'Enjoy Delivery',
      'subtitle': 'Relax as your water arrives automatically on schedule.',
      'highlight': true,
    },
  ];

  static const _benefits = [
    {
      'icon': Icons.sync_rounded,
      'title': 'Automatic Deliveries',
      'subtitle': 'Set it once and never think about ordering water again',
    },
    {
      'icon': Icons.local_offer_outlined,
      'title': 'Save More',
      'subtitle': 'Subscribers get up to 50% off compared to one-time orders',
    },
    {
      'icon': Icons.calendar_month_outlined,
      'title': 'Flexible Plans',
      'subtitle': 'Pause, resume, or cancel your subscription whenever needed',
    },
    {
      'icon': Icons.apartment_outlined,
      'title': 'Home & Office',
      'subtitle': 'Tailored solutions for families and corporate workspace',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFF9F5),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9F5),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  children: [
                    _buildHeroBanner(),
                    const SizedBox(height: 16),
                    _buildFindSupplierButton(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('How It Works'),
                    const SizedBox(height: 20),
                    _buildHowItWorks(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Why Subscribe?'),
                    const SizedBox(height: 20),
                    _buildWhySubscribeGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        12,
      ),
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
                border: Border.all(
                  color: const Color(0xFFFF5E00).withValues(alpha: 0.25),
                  width: 0.8,
                ),
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
              'Subscription',
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

  Widget _buildHeroBanner() {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'lib/assets/images/water_subscription_banner.jpg',
        width: double.infinity,
        height: 168,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF0A3D6E),
                Color(0xFF1565A8),
                Color(0xFF1BA4B8),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.water_drop_outlined,
            color: Colors.white.withValues(alpha: 0.5),
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildFindSupplierButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        height: 48,
        width: double.infinity,
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
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'Find Supplier',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFFFF5E00),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 120,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2520),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    const double iconSize = 46.0;
    const double colWidth = 52.0;

    return Stack(
      children: [
        Positioned(
          left: (colWidth - 2) / 2,
          top: iconSize / 2,
          bottom: iconSize / 2,
          child: Container(width: 2, color: const Color(0xFFFF5E00)),
        ),
        Column(
          children: List.generate(_steps.length, (index) {
            final step = _steps[index];
            final isLast = index == _steps.length - 1;
            final highlight = step['highlight'] == true;
            final image = step['image'] as String?;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: colWidth,
                    child: Center(
                      child: highlight
                          ? Container(
                              width: iconSize,
                              height: iconSize,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5E00),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.sentiment_satisfied_alt_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                          : Image.asset(
                              image!,
                              width: iconSize,
                              height: iconSize,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title'] as String,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['subtitle'] as String,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF4A453F),
                              fontSize: 11,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWhySubscribeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _benefits.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 130,
      ),
      itemBuilder: (context, index) {
        final item = _benefits[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEAD8C9),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: const Color(0xFFFF5E00),
                  size: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] as String,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['subtitle'] as String,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 10,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
