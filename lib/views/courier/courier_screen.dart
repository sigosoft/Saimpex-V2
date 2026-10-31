import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/api_exception.dart';
import '../../models/courier_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/app_back_button.dart';

import 'courier_select_recipient_location_screen.dart';
import 'courier_delivery_details_screen.dart';

class CourierScreen extends StatefulWidget {
  const CourierScreen({super.key});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  final _courier = Get.find<CourierRepository>();
  int selectedVehicleIndex = 0;
  String? pickupAddress;
  double? pickupLatitude;
  double? pickupLongitude;
  String? dropOffAddress;
  double? dropOffLatitude;
  double? dropOffLongitude;
  // Fees from courier/quote, keyed by is_express. Null until the quote loads.
  final Map<bool, double> _fees = {};
  double? _distanceKm;
  bool _quoteLoading = false;

  // Standard and Express are the two options the quote API prices (is_express).
  final vehicles = [
    {
      'label': 'st_standard',
      'isExpress': false,
      'image': 'lib/assets/images/bike.png',
    },
    {
      'label': 'st_express',
      'isExpress': true,
      'image': 'lib/assets/images/minivan.png',
    },
  ];

  String _priceText(bool isExpress) {
    final fee = _fees[isExpress];
    return fee == null
        ? 'mru'.trParams({'amount': '—'})
        : 'mru'.trParams({'amount': '${fee.round()}'});
  }

  String get _timeText => _distanceKm == null
      ? ''
      : 'st_km'.trParams({'km': _distanceKm!.toStringAsFixed(1)});

  Future<void> _loadQuote() async {
    final latitude = dropOffLatitude;
    final longitude = dropOffLongitude;
    final address = dropOffAddress;
    final fromLatitude = pickupLatitude;
    final fromLongitude = pickupLongitude;
    final fromAddress = pickupAddress;
    if (latitude == null || longitude == null || address == null) return;
    if (fromLatitude == null || fromLongitude == null || fromAddress == null) {
      return;
    }
    setState(() {
      _quoteLoading = true;
      _fees.clear();
      _distanceKm = null;
    });
    try {
      final language = apiLanguageCode();
      final pickup = CourierStop(
        address: fromAddress,
        latitude: fromLatitude,
        longitude: fromLongitude,
      );
      final dropoff = CourierStop(
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      final standard = await _courier.quote(
        pickup: pickup,
        dropoff: dropoff,
        isExpress: false,
        language: language,
      );
      final express = await _courier.quote(
        pickup: pickup,
        dropoff: dropoff,
        isExpress: true,
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _fees[false] = standard.deliveryFee;
        _fees[true] = express.deliveryFee;
        _distanceKm = standard.distanceKm;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _quoteLoading = false);
    }
  }

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
            colors: [Color(0xFFFFDDCF), Color(0xFFFFEEE5), Color(0xFFFAF6F0)],
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
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          92 + bottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            _buildTopBanner(),
                            const SizedBox(height: 16),
                            _buildPickupDropCard(),
                            const SizedBox(height: 22),
                            Text(
                              'st_choose_vehicle'.tr,
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
                              'st_exclusive_offers'.tr,
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
            alignment: AlignmentDirectional.centerStart,
            child: AppBackButton(onTap: () => Get.back()),
          ),
          Text(
            'st_courier'.tr,
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
          errorBuilder: (_, _, _) => Container(
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 14, 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline: halo dots + dashed connector
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  _routeDot(
                    fill: const Color(0xFF2F80ED),
                    halo: const Color(0xFFD6E6FB),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: CustomPaint(
                        painter: _VerticalDashedLinePainter(
                          color: const Color(0xFFD0C8C0),
                        ),
                      ),
                    ),
                  ),
                  _routeDot(
                    fill: const Color(0xFFFF5E00),
                    halo: const Color(0xFFFFE0CC),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _buildRouteRow(
                    label: 'st_pickup'.tr,
                    title: pickupAddress ?? 'st_add_pickup'.tr,
                    isPlaceholder: pickupAddress == null,
                    onTap: _openPickupLocation,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),
                  _buildRouteRow(
                    label: 'st_drop_off'.tr,
                    title: dropOffAddress ?? 'st_add_destination'.tr,
                    isPlaceholder: dropOffAddress == null,
                    onTap: _openDropOffLocation,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeDot({required Color fill, required Color halo}) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: halo, shape: BoxShape.circle),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      ),
    );
  }

  Future<void> _openPickupLocation() async {
    final result = await Get.to<Map<String, dynamic>>(
      () => const CourierSelectRecipientLocationScreen(
        title: 'st_select_pickup_location',
      ),
    );
    if (!mounted || result == null) return;

    final title = result['title']?.toString();
    final subtitle = result['subtitle']?.toString();
    final latitude = double.tryParse('${result['latitude']}');
    final longitude = double.tryParse('${result['longitude']}');
    if (title != null &&
        title.isNotEmpty &&
        latitude != null &&
        longitude != null) {
      setState(() {
        pickupAddress = _formatDropOffAddress(title, subtitle);
        pickupLatitude = latitude;
        pickupLongitude = longitude;
      });
      _loadQuote();
    }
  }

  Future<void> _openDropOffLocation() async {
    final result = await Get.to<Map<String, dynamic>>(
      () => const CourierSelectRecipientLocationScreen(),
    );
    if (!mounted || result == null) return;

    final title = result['title']?.toString();
    final subtitle = result['subtitle']?.toString();
    if (title != null && title.isNotEmpty) {
      setState(() {
        dropOffAddress = _formatDropOffAddress(title, subtitle);
        dropOffLatitude = double.tryParse('${result['latitude']}');
        dropOffLongitude = double.tryParse('${result['longitude']}');
      });
      _loadQuote();
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: isPlaceholder
                        ? const Color(0xFF8C7D73)
                        : const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: isPlaceholder
                        ? FontWeight.w500
                        : FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFB8AFA8),
            size: 22,
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
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: index == 0 ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() => selectedVehicleIndex = index),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 98,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
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
                            errorBuilder: (_, _, _) => const Icon(
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
                                vehicle['label']!.toString().tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _timeText,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _priceText(vehicle['isExpress']! as bool),
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
                    PositionedDirectional(
                      top: -4,
                      end: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E00),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
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
        padding: const EdgeInsetsDirectional.only(end: 16),
        itemCount: offers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              offers[index],
              width: bannerWidth,
              height: bannerHeight,
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => Container(
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
    final isExpress = vehicle['isExpress']! as bool;

    return GestureDetector(
      onTap: () {
        final fee = _fees[isExpress];
        if (pickupAddress == null || pickupLatitude == null) {
          showAppToast(
            'st_pickup_first'.tr,
            backgroundColor: const Color(0xFFEF4444),
          );
          return;
        }
        if (dropOffAddress == null || dropOffLatitude == null) {
          showAppToast(
            'st_drop_off_first'.tr,
            backgroundColor: const Color(0xFFEF4444),
          );
          return;
        }
        if (fee == null) {
          showAppToast(
            _quoteLoading ? 'st_getting_price'.tr : 'st_price_failed'.tr,
            backgroundColor: const Color(0xFFEF4444),
          );
          if (!_quoteLoading) _loadQuote();
          return;
        }
        Get.to(
          () => CourierDeliveryDetailsScreen(
            pickupAddress: pickupAddress!,
            dropOffAddress: dropOffAddress!,
            pickupLatitude: pickupLatitude!,
            pickupLongitude: pickupLongitude!,
            dropOffLatitude: dropOffLatitude!,
            dropOffLongitude: dropOffLongitude!,
            vehicleLabel: vehicle['label']!.toString(),
            vehicleTime: _timeText,
            vehiclePrice: _priceText(isExpress),
            vehicleImage: vehicle['image']!.toString(),
            isExpress: isExpress,
            deliveryFee: fee.round(),
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
          'st_confirm_pickup'.tr,
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
