import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/api_exception.dart';
import '../../models/courier_repository.dart';
import '../../models/order_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/payment_page.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/app_back_button.dart';

import 'courier_booking_success_screen.dart';
import '../../utils/wallet_balance.dart';
import '../../utils/payment_methods.dart';
import '../../widgets/no_payment_method_note.dart';

class CourierReviewBookingScreen extends StatefulWidget {
  final String pickupAddress;
  final String dropOffAddress;
  final String recipientName;
  final String recipientPhone;
  final String vehicleLabel;
  final String vehicleTime;
  final String vehiclePrice;
  final String vehicleImage;
  final int deliveryFee;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropOffLatitude;
  final double dropOffLongitude;
  final bool isExpress;

  const CourierReviewBookingScreen({
    super.key,
    required this.pickupAddress,
    required this.dropOffAddress,
    required this.recipientName,
    required this.recipientPhone,
    required this.vehicleLabel,
    required this.vehicleTime,
    required this.vehiclePrice,
    required this.vehicleImage,
    required this.deliveryFee,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropOffLatitude,
    required this.dropOffLongitude,
    required this.isExpress,
  });

  @override
  State<CourierReviewBookingScreen> createState() =>
      _CourierReviewBookingScreenState();
}

class _CourierReviewBookingScreenState
    extends State<CourierReviewBookingScreen> {
  // Courier orders have no points, coupon or tax step on the server: the
  // amount charged is the quoted delivery fee.
  static const _extrasAvailable = false;
  bool usePoints = false;
  int selectedPaymentIndex = 0; // mandatory — Wallet selected by default
  bool _noPaymentMethod = false;
  static const _paymentTypes = [
    paymentTypeWallet,
    paymentTypeOnline,
    paymentTypeCash,
  ];

  @override
  void initState() {
    super.initState();
    _applyPaymentMethods();
    PaymentMethods.refresh().then((changed) {
      if (changed && mounted) setState(_applyPaymentMethods);
    });
  }

  /// Keeps the choice on a method Admin has switched on.
  void _applyPaymentMethods() {
    final type = PaymentMethods.keepOrFirstOn(
      _paymentTypes[selectedPaymentIndex],
      _paymentTypes,
    );
    _noPaymentMethod = type == null;
    if (type != null) selectedPaymentIndex = _paymentTypes.indexOf(type);
  }

  bool _placingBooking = false;
  final int redeemedPointsDiscount = 0;
  final int tax = 0;
  // Booked with online payment but not paid yet: paying again reuses this
  // order (orders/{id}/payOnline) instead of booking a second one.
  int? _unpaidOrderId;

  /// Opens the payment page; on success shows the success screen, otherwise
  /// keeps the order for another try.
  Future<void> _payOnline(int orderId, String? url) async {
    final page = paymentPageUrl(url);
    if (page == null) {
      _unpaidOrderId = orderId;
      showAppToast(
        'payment_page_failed'.tr,
        backgroundColor: const Color(0xFFEF4444),
      );
      return;
    }
    final paid = await openPaymentPage(page);
    if (!mounted) return;
    if (paid == true) {
      _unpaidOrderId = null;
      Get.off(() => const CourierBookingSuccessScreen());
      return;
    }
    _unpaidOrderId = orderId;
    showAppToast(
      'courier_payment_retry'.tr,
      backgroundColor: const Color(0xFFEF4444),
    );
  }

  /// Books the delivery with courier/create, then shows the success screen.
  Future<void> _placeBooking() async {
    if (_noPaymentMethod) {
      showAppToast(
        'payment_no_method'.tr,
        backgroundColor: const Color(0xFFEF4444),
      );
      return;
    }
    if (_placingBooking) return;
    setState(() => _placingBooking = true);
    try {
      final unpaid = _unpaidOrderId;
      if (unpaid != null) {
        final url = await Get.find<OrderRepository>().payOnline(
          orderId: unpaid,
          language: apiLanguageCode(),
        );
        if (!mounted) return;
        await _payOnline(unpaid, url);
        return;
      }
      // Wallet 3 (paid at booking), online 2 (payment page), cash 1.
      final paymentType = switch (selectedPaymentIndex) {
        0 => paymentTypeWallet,
        1 => paymentTypeOnline,
        _ => paymentTypeCash,
      };
      final result = await Get.find<CourierRepository>().create(
        pickup: CourierStop(
          address: widget.pickupAddress,
          latitude: widget.pickupLatitude,
          longitude: widget.pickupLongitude,
        ),
        dropoff: CourierStop(
          address: widget.dropOffAddress,
          latitude: widget.dropOffLatitude,
          longitude: widget.dropOffLongitude,
          contactName: widget.recipientName,
          contactPhone: _formattedPhone,
        ),
        isExpress: widget.isExpress,
        paymentType: paymentType,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      showAppToast(result.message, backgroundColor: const Color(0xFFFF5E00));
      final orderId = result.orderId;
      if (paymentType == paymentTypeOnline && orderId != null) {
        await _payOnline(orderId, result.paymentUrl);
        return;
      }
      Get.off(() => const CourierBookingSuccessScreen());
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _placingBooking = false);
    }
  }

  int get toPay => widget.deliveryFee;

  String get _displayDropOff {
    final address = widget.dropOffAddress;
    if (address.contains(',')) {
      final parts = address.split(',');
      if (parts.length >= 2) {
        return '${parts[0].trim()}, ${parts[1].trim()}';
      }
    }
    return address;
  }

  String get _formattedPhone {
    final phone = widget.recipientPhone.trim();
    // Numbers from the details screen already carry their country code
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('222')) return '+$phone';
    return '+222 $phone';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
            stops: [0.0, 0.28, 1.0],
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
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          100 + bottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildRouteAndContactCard(),
                            const SizedBox(height: 18),
                            Text(
                              'st_otp_verification'.tr,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildOtpCard(),
                            const SizedBox(height: 14),
                            _buildVehicleCard(),
                            const SizedBox(height: 14),
                            _buildScheduleCard(),
                            const SizedBox(height: 18),
                            if (_extrasAvailable) ...[
                              _buildSaveMoreSection(),
                              const SizedBox(height: 18),
                            ],
                            Text(
                              'st_payment'.tr,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (PaymentMethods.isOn(_paymentTypes[0]))
                              _buildPaymentOption(
                                index: 0,
                                icon: Icons.account_balance_wallet_outlined,
                                title: 'wallet_title'.tr,
                                subtitle: walletBalanceSubtitle(),
                              ),
                            if (PaymentMethods.isOn(_paymentTypes[1]))
                              _buildPaymentOption(
                                index: 1,
                                icon: Icons.payments_outlined,
                                title: 'st_online_payment'.tr,
                                subtitle: 'st_card_mobile_money'.tr,
                              ),
                            if (PaymentMethods.isOn(_paymentTypes[2]))
                              _buildPaymentOption(
                                index: 2,
                                icon: Icons.monetization_on_outlined,
                                title: 'st_cash_on_delivery'.tr,
                                subtitle: 'st_pay_driver'.tr,
                              ),
                            if (_noPaymentMethod) const NoPaymentMethodNote(),
                            const SizedBox(height: 14),
                            _buildPaymentDetails(),
                            const SizedBox(height: 12),
                            Text(
                              'st_terms_note'.tr,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 10,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
                  child: _buildPayButton(),
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
            'st_review_booking'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteAndContactCard() {
    // Keep this contact icon exactly as-is (do not restyle).
    final contactIcon = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5E00),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
    );

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
      padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 14, 18),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        title: widget.pickupAddress,
                      ),
                      const SizedBox(height: 18),
                      _buildRouteRow(
                        label: 'st_drop_off'.tr,
                        title: _displayDropOff,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFE8E0D8), height: 1, thickness: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'st_receiver_contact'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'st_edit'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              contactIcon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipientName,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formattedPhone,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildRouteRow({required String label, required String title}) {
    return Row(
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildOtpCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0EA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFFF5E00),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'st_otp_share_hint'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: const Color(0xFFD9D0C8),
                borderRadius: 24,
              ),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (index) {
                    const digits = ['3', '4', '5', '6', '7', '8'];
                    return Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: index == 5 ? 0 : 10,
                      ),
                      child: Text(
                        digits[index],
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              widget.vehicleImage,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.two_wheeler_outlined),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vehicleLabel.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.vehicleTime,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.vehiclePrice,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFE03A3A),
                size: 18,
              ),
              const SizedBox(height: 2),
              Text(
                'st_km'.trParams({'km': '10'}),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF7A6A60),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBEAC5), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFCEF5DA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF00B25C),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'st_schedule_later'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0E5A2A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'st_select_pickup_time'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF3BA162),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF00B25C),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveMoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'st_save_more'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'st_view_coupons'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                color: Color(0xFFFF5E00),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: GoogleFonts.outfit(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'st_enter_coupon'.tr,
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Text(
                'st_apply'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => usePoints = !usePoints),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Image.asset(
                  'lib/assets/images/Coin.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.monetization_on_outlined,
                    color: Color(0xFFFF5E00),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'cart_use_points'.trParams({'points': '500'}),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'cart_points_off'.trParams({'amount': '50'}),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: usePoints
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFA59A94),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: usePoints
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5E00),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selectedPaymentIndex == index;

    return GestureDetector(
      onTap: () => setState(() {
        // Payment type is mandatory — switch between options, never clear.
        selectedPaymentIndex = index;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFEAD8C9),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFFF5E00), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFA59A94),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: isSelected
                  ? Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5E00),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2520),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'st_payment_details'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _paymentRow(
            'cart_delivery_fee'.tr,
            'mru'.trParams({'amount': '${widget.deliveryFee}'}),
          ),
          if (_extrasAvailable) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'cart_redeemed_points'.tr,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '-${'mru'.trParams({'amount': '$redeemedPointsDiscount'})}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (usePoints) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'st_points_discount'.tr,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '-${'mru'.trParams({'amount': '50'})}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            _paymentRow('cart_tax'.tr, 'mru'.trParams({'amount': '$tax'})),
          ],
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF423B36), height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'st_to_pay'.tr,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'mru'.trParams({'amount': '$toPay'}),
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

  Widget _paymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return GestureDetector(
      onTap: _placingBooking ? null : _placeBooking,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
          ),
          borderRadius: BorderRadius.circular(28),
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
          'st_pay_amount'.trParams({'amount': '$toPay'}),
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, this.borderRadius = 24});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    const dashLength = 4.0;
    const gap = 3.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
