import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'courier_select_recipient_location_screen.dart';
import 'courier_delivery_details_screen.dart';

class CourierScreen extends StatefulWidget {
  const CourierScreen({super.key});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  int selectedVehicleIndex = 0;
  String? dropOffAddress;

  final vehicles = [
    {
      'label': 'Bike',
      'time': '30-35 min',
      'price': '50 MRU',
      'image': 'lib/assets/images/bike.png',
    },
    {
      'label': 'Mini Van',
      'time': '30-35 min',
      'price': '100 MRU',
      'image': 'lib/assets/images/minivan.png',
    },
  ];

  final offers = [
    'lib/assets/images/courier_banner1.png',
    'lib/assets/images/courier_banner2.png',
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFDDCF),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFDDCF),
              Color(0xFFFFEEE5),
              Color(0xFFFAF6F0),
            ],
            stops: [0.0, 0.32, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 92 + bottomInset),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            _buildTopBanner(),
                            const SizedBox(height: 16),
                            _buildPickupDropCard(),
                            const SizedBox(height: 22),
                            Text(
                              'Choose Vehicle',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildVehicleCards(),
                            const SizedBox(height: 22),
                            Text(
                              'Exclusive Offers',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildOffersList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: bottomInset + 16,
                  child: _buildConfirmButton(),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
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
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
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
          Text(
            'Courier',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 343 / 130,
        child: Image.asset(
          'lib/assets/images/courier_banner.png',
          width: double.infinity,
          fit: BoxFit.fill,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFE8F0FF),
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_outlined),
          ),
        ),
      ),
    );
  }

  Widget _buildPickupDropCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
      child: SizedBox(
        height: 108,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 14,
              child: Column(
                children: [
                  _routeDot(const Color(0xFF2F80ED)),
                  Expanded(
                    child: CustomPaint(
                      painter: _VerticalDashedLinePainter(
                        color: const Color(0xFFD9D0C8),
                      ),
                    ),
                  ),
                  _routeDot(const Color(0xFFFF5E00)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildRouteRow(
                        label: 'PICKUP',
                        title: 'Marhaba Supermarket, Nouakchott',
                        isPlaceholder: false,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildRouteRow(
                        label: 'DROP-OFF',
                        title: dropOffAddress ?? 'Add destination',
                        isPlaceholder: dropOffAddress == null,
                        onTap: _openDropOffLocation,
                        maxLines: 2,
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

  Widget _routeDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Future<void> _openDropOffLocation() async {
    final result = await Get.to<Map<String, dynamic>>(
      () => const CourierSelectRecipientLocationScreen(),
    );
    if (!mounted || result == null) return;

    final title = result['title']?.toString();
    final subtitle = result['subtitle']?.toString();
    if (title != null && title.isNotEmpty) {
      setState(() => dropOffAddress = _formatDropOffAddress(title, subtitle));
    }
  }

  String _formatDropOffAddress(String title, String? subtitle) {
    if (subtitle == null ||
        subtitle.isEmpty ||
        subtitle.startsWith('Lat:') ||
        subtitle.startsWith('Fetching') ||
        subtitle.startsWith('Please approve')) {
      return title;
    }

    if (subtitle == title) return title;

    final city = title.split(',').first.trim();
    if (subtitle.contains(city)) return subtitle;

    // Prefer the detailed subtitle when search returns both parts.
    if (subtitle.length > title.length) return subtitle;

    return '$subtitle, $city';
  }

  Widget _buildRouteRow({
    required String label,
    required String title,
    required bool isPlaceholder,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: isPlaceholder
                        ? const Color(0xFFA59A94)
                        : const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFA59A94),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCards() {
    return Row(
      children: List.generate(vehicles.length, (index) {
        final vehicle = vehicles[index];
        final isSelected = selectedVehicleIndex == index;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedVehicleIndex = index),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 98,
                  margin: EdgeInsets.only(right: index == 0 ? 10 : 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? Border.all(
                            color: const Color(0xFFFF5E00),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Image.asset(
                          vehicle['image']!.toString(),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.two_wheeler_outlined,
                            color: Color(0xFFA59A94),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              vehicle['label']!.toString(),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              vehicle['time']!.toString(),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vehicle['price']!.toString(),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: -4,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5E00),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOffersList() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Wide banners with the next one peeking on the right, matching the design.
    final bannerWidth = screenWidth - 52;
    const bannerHeight = 132.0;

    return SizedBox(
      height: bannerHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 16),
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              offers[index],
              width: bannerWidth,
              height: bannerHeight,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => Container(
                width: bannerWidth,
                height: bannerHeight,
                color: const Color(0xFFFFF0EA),
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton() {
    final vehicle = vehicles[selectedVehicleIndex];
    final feeStr = vehicle['price']!.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final deliveryFee = int.tryParse(feeStr) ?? 50;

    return GestureDetector(
      onTap: () {
        Get.to(
          () => CourierDeliveryDetailsScreen(
            pickupAddress: 'Marhaba Supermarket, Nouakchott',
            dropOffAddress:
                dropOffAddress ?? 'Saimpex Logistics Hub, Wharf Sector',
            vehicleLabel: vehicle['label']!.toString(),
            vehicleTime: vehicle['time']!.toString(),
            vehiclePrice: vehicle['price']!.toString(),
            vehicleImage: vehicle['image']!.toString(),
            deliveryFee: deliveryFee,
          ),
        );
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
          ),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'Confirm Pickup',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;

  _VerticalDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 3.5;
    const gap = 3.0;
    var y = 0.0;
    final x = size.width / 2;

    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
