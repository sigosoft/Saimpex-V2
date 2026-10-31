import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/water_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/app_back_button.dart';

import 'water_subscription_success_screen.dart';

/// Review and confirm a water subscription. Subscribing (water/subscribe)
/// charges nothing: the supplier confirms it, then each delivery is its own
/// cash-on-delivery order.
class WaterSubscriptionCartScreen extends StatefulWidget {
  final int planId;
  final String storeName;
  final String itemName;
  final String itemSize;
  final String itemImage;
  final int pricePerDelivery;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final String startDateLabel;
  final String endDateLabel;
  final String timeSlot;
  final String subscriptionType;

  const WaterSubscriptionCartScreen({
    super.key,
    required this.planId,
    required this.storeName,
    required this.itemName,
    required this.itemSize,
    required this.itemImage,
    required this.pricePerDelivery,
    required this.quantity,
    required this.startDate,
    required this.endDate,
    required this.startDateLabel,
    required this.endDateLabel,
    required this.timeSlot,
    required this.subscriptionType,
  });

  @override
  State<WaterSubscriptionCartScreen> createState() =>
      _WaterSubscriptionCartScreenState();
}

class _WaterSubscriptionCartScreenState
    extends State<WaterSubscriptionCartScreen> {
  late int quantity;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    quantity = widget.quantity < 1 ? 1 : widget.quantity;
  }

  String get _address {
    final subtitle = SelectLocationController.selectedSubtitle.trim();
    return subtitle.isEmpty
        ? SelectLocationController.deliveryLabel.value
        : subtitle;
  }

  Future<void> _subscribe() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final message = await Get.find<WaterRepository>().subscribe(
        planId: widget.planId,
        quantity: quantity,
        startDate: widget.startDate,
        endDate: widget.endDate,
        deliverySlot: widget.timeSlot,
        address: _address,
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      if (message.isNotEmpty) {
        showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      }
      Get.off(() => const WaterSubscriptionSuccessScreen());
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFFBF5),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        body: Column(
          children: [
            _buildHeader(),
            if (widget.storeName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'From ${widget.storeName}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C7E75),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductCard(),
                    const SizedBox(height: 18),
                    _buildSubscriptionDetails(),
                    const SizedBox(height: 14),
                    _buildAddressCard(),
                    const SizedBox(height: 16),
                    _buildPaymentDetails(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GestureDetector(
                  onTap: _subscribe,
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF5E00,
                          ).withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            'Subscribe',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        8,
      ),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
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

  Widget _buildProductCard() {
    final image = widget.itemImage;
    final isAsset = !image.startsWith('http');

    return Container(
      padding: const EdgeInsets.all(14),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 64,
              height: 64,
              color: const Color(0xFFEAF6FB),
              child: isAsset
                  ? Image.asset(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.water_drop_outlined,
                        color: Color(0xFF2E9FE6),
                      ),
                    )
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.water_drop_outlined,
                        color: Color(0xFF2E9FE6),
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
                  widget.itemName,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.itemSize.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.itemSize,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${widget.pricePerDelivery} MRU / delivery',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (quantity > 1) setState(() => quantity--);
                  },
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.remove,
                      color: Color(0xFF2C2520),
                      size: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => quantity++),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5E00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Subscription Details',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Get.back(),
              child: Text(
                'Edit',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
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
            children: [
              Row(
                children: [
                  Expanded(
                    child: _detailBox(
                      label: 'Start Date',
                      value: widget.startDateLabel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _detailBox(
                      label: 'End Date',
                      value: widget.endDateLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _detailBox(
                      label: 'Time Slot',
                      value: widget.timeSlot,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _detailBox(
                      label: 'Type',
                      value: widget.subscriptionType,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailBox({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5E00),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deliver to',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _payRow('Price per delivery', '${widget.pricePerDelivery} MRU'),
          const SizedBox(height: 10),
          _payRow('Quantity', '$quantity'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0xFF3A434E), height: 1),
          ),
          Text(
            'Nothing is charged now. The supplier confirms your subscription, '
            'then you pay cash to the driver for each delivery.',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _payRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
