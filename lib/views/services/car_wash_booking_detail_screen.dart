import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cancel_booking_bottom_sheet.dart';
import '../../widgets/app_back_button.dart';

class CarWashBookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const CarWashBookingDetailScreen({
    super.key,
    required this.booking,
  });

  String get _bookingId => (booking['id'] as String?) ?? '22789002';

  String get _service {
    final raw = (booking['service'] as String?) ??
        (booking['serviceTitle'] as String?) ??
        'Exterior Wash';
    // Avoid old sample labels like "Basic Wash x2".
    if (raw.toLowerCase().contains('basic')) {
      return 'Full Wash';
    }
    return raw.contains(' x') ? raw.split(' x').first : raw;
  }

  String get _serviceDescription {
    final fromBooking = booking['serviceDescription'] as String?;
    if (fromBooking != null && fromBooking.isNotEmpty) return fromBooking;
    switch (_service) {
      case 'Interior Wash':
        return 'Deep antimicrobial vacuum, UV dashboard polish & crystal glass cleaning';
      case 'Full Wash':
        return 'Complete interior & exterior detailing with premium ceramic tire gloss';
      default:
        return 'High pressure snow foam, detailed rim cleaning & streak-free hand dry';
    }
  }

  String get _serviceImage {
    final fromBooking = booking['serviceImage'] as String?;
    if (fromBooking != null && fromBooking.isNotEmpty) return fromBooking;
    switch (_service) {
      case 'Interior Wash':
        return 'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?w=300&h=300&fit=crop';
      case 'Full Wash':
        return 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=300&h=300&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=300&h=300&fit=crop';
    }
  }

  String get _servicePrice {
    final fromBooking = (booking['servicePrice'] as String?) ??
        (booking['vehiclePrice'] as String?);
    if (fromBooking != null && fromBooking.isNotEmpty) return fromBooking;
    switch (_service) {
      case 'Full Wash':
        return '1000 MRU';
      default:
        return '550 MRU';
    }
  }

  List<Map<String, dynamic>> get _washServices {
    final raw = booking['washServices'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['isAddon'] != true)
          .toList();
    }
    return [
      {
        'title': _service,
        'description': _serviceDescription,
        'price': _servicePrice,
        'image': _serviceImage,
      },
    ];
  }

  String get _slot =>
      (booking['slot'] as String?) ??
      (booking['datetime'] as String?) ??
      '15 Aug 2026, 2:00 - 4:00 PM';

  String get _location =>
      (booking['location'] as String?) ??
      'CleanRide Car Wash, Near Nouakchott, Mauritania';

  String get _vehicleLabel => (booking['vehicleLabel'] as String?) ?? 'Sedan';

  String get _vehicleImage {
    final fromBooking = (booking['vehicleImage'] as String?) ??
        (booking['image'] as String?);
    if (fromBooking != null &&
        fromBooking.isNotEmpty &&
        !fromBooking.startsWith('http')) {
      return fromBooking;
    }
    final label = _vehicleLabel.toLowerCase();
    if (label.contains('suv') || label.contains('4x4')) {
      return 'lib/assets/images/SUV.png';
    }
    if (label.contains('pickup')) {
      return 'lib/assets/images/Pickup.png';
    }
    if (label.contains('mini') || label.contains('bus')) {
      return 'lib/assets/images/MiniBus.png';
    }
    return 'lib/assets/images/Sedan.png';
  }

  String get _plateNumber =>
      (booking['plateNumber'] as String?) ?? '1234 AB 01';

  String get _total => (booking['total'] as String?) ?? '550 MRU';
  String get _redeemed => (booking['redeemed'] as String?) ?? '-50 MRU';
  String get _tax => (booking['tax'] as String?) ?? '10 MRU';
  String get _totalPaid => (booking['totalPaid'] as String?) ?? '510 MRU';

  List<Map<String, dynamic>> get _addons {
    final raw = booking['addons'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [
      {
        'title': 'Engine Wash',
        'description':
            'Safe hydraulic degreasing and rinse for bay components without water damage.',
        'price': '+50 MRU',
        'image':
            'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=200&h=200&fit=crop',
      },
    ];
  }

  static const _statusSteps = [
    {
      'label': 'Booking\nConfirmed',
      'time': '15 Aug 2026,\n10:00 AM',
      'icon': Icons.check_rounded,
      'done': true,
    },
    {
      'label': 'Vehicle\nReceived',
      'time': '15 Aug 2026,\n10:05 AM',
      'icon': Icons.directions_car_filled_rounded,
      'done': true,
    },
    {
      'label': 'Ready for\nPickup',
      'time': '15 Aug 2026,\n10:10 AM',
      'icon': Icons.check_rounded,
      'done': true,
    },
    {
      'label': 'Completed',
      'time': '',
      'icon': Icons.check_rounded,
      'done': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFDFBF7),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFDFBF7),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      EdgeInsets.fromLTRB(16, 10, 16, 20 + bottomInset + 72),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 22),
                      _sectionTitle('Vehicles'),
                      const SizedBox(height: 12),
                      _buildVehicleCard(),
                      const SizedBox(height: 22),
                      _sectionTitle('Washing Details'),
                      const SizedBox(height: 12),
                      _buildLocationCard(),
                      const SizedBox(height: 10),
                      _buildSlotCard(),
                      const SizedBox(height: 22),
                      _buildPaymentDetails(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildCancelBar(bottomInset),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'Booking #$_bookingId',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFF5E00).withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'Help',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF1A1A1A),
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildStatusCard() {
    const circleSize = 36.0;
    const lineTop = 18.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Text(
            'Booking Status',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = _statusSteps.length;
              final stepWidth = constraints.maxWidth / count;
              final lineLeft = stepWidth / 2;
              final lineWidth = constraints.maxWidth - stepWidth;
              final doneCount =
                  _statusSteps.where((s) => s['done'] == true).length;
              final progress =
                  doneCount <= 1 ? 0.0 : (doneCount - 1) / (count - 1);

              return SizedBox(
                height: 118,
                child: Stack(
                  children: [
                    Positioned(
                      top: lineTop - 1.5,
                      left: lineLeft,
                      width: lineWidth,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8DFD6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      top: lineTop - 1.5,
                      left: lineLeft,
                      width: lineWidth * progress,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E00),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final step in _statusSteps)
                          Expanded(child: _statusStep(step, circleSize)),
                      ],
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

  Widget _statusStep(Map<String, dynamic> step, double circleSize) {
    final done = step['done'] as bool;
    final time = step['time'] as String;

    return Column(
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: done ? const Color(0xFFFF5E00) : const Color(0xFFF0EAE4),
            shape: BoxShape.circle,
            boxShadow: done
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            step['icon'] as IconData,
            color: done ? Colors.white : const Color(0xFFB0A8A0),
            size: 18,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          step['label'] as String,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            time,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF9A8E86),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 78,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFFECECEC)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 22),
                        child: Image.asset(
                          _vehicleImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: Color(0xFFFF5E00),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          color: Colors.black.withValues(alpha: 0.55),
                          alignment: Alignment.center,
                          child: Text(
                            _vehicleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plateNumber,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0D1B2A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _service,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF5A6B7D),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _washServices.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _nestedServiceRow(
              image: (_washServices[i]['image'] as String?) ?? _serviceImage,
              title: (_washServices[i]['title'] as String?) ?? _service,
              description:
                  (_washServices[i]['description'] as String?) ??
                  _serviceDescription,
              priceLabel:
                  (_washServices[i]['price'] as String?) ?? _servicePrice,
            ),
          ],
          if (_addons.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFEDE8E2),
            ),
            const SizedBox(height: 12),
            Text(
              'Add-On Services',
              style: GoogleFonts.outfit(
                color: const Color(0xFF5A6B7D),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _addons.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _nestedServiceRow(
                image: (_addons[i]['image'] as String?) ?? _serviceImage,
                title: (_addons[i]['title'] as String?) ?? 'Add-On',
                description: (_addons[i]['description'] as String?) ?? '',
                priceLabel: (_addons[i]['price'] as String?) ?? '+0 MRU',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _nestedServiceRow({
    required String image,
    required String title,
    required String description,
    required String priceLabel,
  }) {
    final isNetwork = image.startsWith('http');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isNetwork
                ? Image.network(
                    image,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(),
                  )
                : Image.asset(
                    image,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0D1B2A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            priceLabel,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 54,
      height: 54,
      color: const Color(0xFFFFF3EB),
      child: const Icon(
        Icons.local_car_wash_rounded,
        color: Color(0xFFFF5E00),
        size: 22,
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFFFF5E00),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFFF5E00),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF5E00), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFFFF5E00),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Slot',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _slot,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF6B6560),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFFF5E00),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _payRow('Total', _total),
          const SizedBox(height: 10),
          _payRow(
            'Redeemed points',
            _redeemed,
            valueColor: const Color(0xFFFF5E00),
          ),
          const SizedBox(height: 10),
          _payRow('Tax', _tax),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFF4A4A4A)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Total paid',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _totalPaid,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      color: const Color(0xFFFDFBF7),
      child: GestureDetector(
        onTap: () => showCancelBookingBottomSheet(
          Get.context!,
          bookingId: _bookingId,
        ),
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF2ECE4),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
