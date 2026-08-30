import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'laundry_cart_screen.dart';
import 'laundry_choose_pickup_sheet.dart';

class LaundryServiceConfigureScreen extends StatefulWidget {
  final Map<String, String> service;
  final String providerName;

  const LaundryServiceConfigureScreen({
    super.key,
    required this.service,
    this.providerName = 'CleanPro Laundry',
  });

  @override
  State<LaundryServiceConfigureScreen> createState() =>
      _LaundryServiceConfigureScreenState();
}

class _LaundryServiceConfigureScreenState
    extends State<LaundryServiceConfigureScreen> {
  int _kg = 3;

  String get _title => widget.service['title'] ?? 'Wash & Fold';

  String get _heroImage =>
      widget.service['image'] ?? 'lib/assets/images/wash&fold_detail.png';

  int get _pricePerKg {
    final raw = widget.service['price'] ?? '150';
    return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 150;
  }

  String get _durationLabel {
    final raw = widget.service['duration'] ?? '1 Day';
    if (raw.toLowerCase().contains('day')) return '24 hours';
    return raw;
  }

  int get _estimatedPrice => _kg * _pricePerKg;

  String _slotRangeFromLabel(String label) {
    final match = RegExp(
      r'(\d+)\s*[–-]\s*(\d+)\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(label);
    if (match == null) return label;
    final start = match.group(1)!;
    final end = match.group(2)!;
    final period = match.group(3)!.toUpperCase();
    return '$start:00 $period – $end:00 $period';
  }

  Future<void> _openPickupAndCart() async {
    final result = await LaundryChoosePickupSheet.show(context);
    if (result == null || !mounted) return;
    final date = result['date'] as DateTime;
    final slot = _slotRangeFromLabel(result['slot'] as String);
    Get.to(
      () => LaundryCartScreen(
        providerName: widget.providerName,
        serviceTitle: _title,
        serviceImage: _heroImage,
        estimateLabel: 'Estimated $_kg kg',
        basePrice: _estimatedPrice,
        durationLabel: _durationLabel == '24 hours' ? '24 hour' : _durationLabel,
        slotDate: date,
        slotLabel: slot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 20),
                      Text(
                        'How much laundry do you have?',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1B2B4A),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildQuantityCard(),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(bottomInset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF5E00),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFF5E00),
                size: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.asset(
          _heroImage,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFFFF3EB),
            alignment: Alignment.center,
            child: const Icon(
              Icons.local_laundry_service_rounded,
              color: Color(0xFFFF5E00),
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
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
      child: Column(
        children: [
          Text(
            _title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _buildStepper(),
          const SizedBox(height: 16),
          _buildEstimatedPriceBox(),
          const SizedBox(height: 12),
          _buildInfoNote(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EB),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _stepperButton(
            icon: Icons.remove_rounded,
            filled: false,
            onTap: () {
              if (_kg > 1) setState(() => _kg--);
            },
          ),
          Expanded(
            child: Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$_kg',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1B2B4A),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' kg',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1B2B4A),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _stepperButton(
            icon: Icons.add_rounded,
            filled: true,
            onTap: () => setState(() => _kg++),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF5E00) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : const Color(0xFFFF5E00),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildEstimatedPriceBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.outfit(
            color: const Color(0xFF4A5A6A),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
          children: [
            const TextSpan(text: 'Estimated Price: '),
            TextSpan(
              text: '$_kg kg × $_pricePerKg MRU/kg = ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: '$_estimatedPrice',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const TextSpan(
              text: ' MRU',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF1A6BB5),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Final price will be updated after your laundry is weighed during pickup',
              style: GoogleFonts.outfit(
                color: const Color(0xFF5A6A7A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_estimatedPrice MRU',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'DURATION',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _durationLabel,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1B2B4A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _openPickupAndCart,
            child: Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
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
              child: Text(
                'Choose Pickup Time',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
