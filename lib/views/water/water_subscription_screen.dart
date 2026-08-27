import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterSubscriptionScreen extends StatelessWidget {
  const WaterSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 36),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // 1. Header Bar
                _buildHeader(context),
                const SizedBox(height: 16),

                // 2. Banner Graphic
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'lib/assets/images/Sub banner.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0052D4), Color(0xFF4364F7)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Find Supplier Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5E00).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Find Supplier',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 4. How It Works Section
                _buildHowItWorksSection(),
                const SizedBox(height: 32),

                // 5. Why Subscribe? Section
                _buildWhySubscribeSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header Bar
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                border: Border.all(color: const Color(0xFFEAD8C9), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFFFF5E00),
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Subscription',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance header back button
        ],
      ),
    );
  }

  // How It Works Section
  Widget _buildHowItWorksSection() {
    final steps = [
      {
        'title': 'Choose Supplier',
        'subtitle': 'Browse top rated local water providers in your location',
        'icon': Image.asset("lib/assets/images/choose supplier.png"),
        'isFilled': false,
      },
      {
        'title': 'Select Products',
        'subtitle':
            'Pick your preferred bottle sizes and water mineral balance',
        'icon': Image.asset("lib/assets/images/select product.png"),
        'isFilled': false,
      },
      {
        'title': 'Choose a Delivery Plan',
        'subtitle':
            'Select any subscription plan like daily, weekly or monthly',
        'icon': Image.asset("lib/assets/images/delivery plan.png"),
        'isFilled': false,
      },
      {
        'title': 'Choose Schedule',
        'subtitle':
            'Set your delivery days and preferred morning or evening slots',
        'icon': Image.asset("lib/assets/images/schedule.png"),
        'isFilled': false,
      },
      {
        'title': 'Enjoy Delivery',
        'subtitle': 'Relax as your water arrives automatically on schedule',
        'icon': Image.asset("lib/assets/images/Enjoy delivery.png"),
        'isFilled': true,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Section Heading
          Text(
            'How It Works',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2520),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Stepper Timeline
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Line & Circle Icon
                    Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (step['isFilled'] as bool)
                                ? const Color(0xFFFF5E00)
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF5E00),
                              width: (step['isFilled'] as bool) ? 0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF5E00,
                                ).withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: step['icon'] is Widget
                                ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: step['icon'] as Widget,
                                  )
                                : step['icon'] is String
                                ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Image.asset(
                                      step['icon'] as String,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Icon(
                                    step['icon'] as IconData,
                                    color: (step['isFilled'] as bool)
                                        ? Colors.white
                                        : const Color(0xFFFF5E00),
                                    size: 22,
                                  ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: const Color(0xFFFBE6DB),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Card Content
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['subtitle'] as String,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF6B635C),
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Why Subscribe? Section
  Widget _buildWhySubscribeSection() {
    final features = [
      {
        'title': 'Automatic Deliveries',
        'subtitle': 'Set it once and never worry about ordering water again',
        'icon': Icons.autorenew_rounded,
      },
      {
        'title': 'Save More',
        'subtitle': 'Subscribers get up to 20% off compared to one-time orders',
        'icon': Icons.local_offer_outlined,
      },
      {
        'title': 'Flexible Plans',
        'subtitle':
            'Pause, resume, or cancel your subscription whenever needed',
        'icon': Icons.calendar_month_outlined,
      },
      {
        'title': 'Home & Office',
        'subtitle': 'Tailored solutions for homes and corporate workplaces',
        'icon': Icons.domain_outlined,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Section Heading
          Text(
            'Why Subscribe?',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2520),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 2x2 Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final feat = features[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0E6),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: feat['icon'] is Widget
                            ? Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: feat['icon'] as Widget,
                              )
                            : feat['icon'] is String
                            ? Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset(
                                  feat['icon'] as String,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Icon(
                                feat['icon'] as IconData,
                                color: const Color(0xFFFF5E00),
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      feat['title'] as String,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feat['subtitle'] as String,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF6B635C),
                        fontSize: 10,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
