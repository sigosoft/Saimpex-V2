import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'laundry_booking_success_screen.dart';
import 'laundry_choose_pickup_sheet.dart';
import 'service_booking_submit.dart';
import '../../core/network/api_exception.dart';
import '../../widgets/app_back_button.dart';
import '../../utils/toast_helper.dart';
import '../../utils/wallet_balance.dart';
import '../../utils/payment_methods.dart';
import '../../widgets/no_payment_method_note.dart';

class LaundryCartScreen extends StatefulWidget {
  final String providerName;
  final String serviceTitle;
  final String serviceImage;
  final String estimateLabel;
  final int basePrice;
  final String durationLabel;
  final DateTime slotDate;
  final String slotLabel;

  /// Per-piece services: `{name, quantity}` for each garment picked.
  final List<Map<String, dynamic>> garments;

  /// Pieces or kg to book; null reads it from [estimateLabel].
  final num? quantity;

  const LaundryCartScreen({
    super.key,
    this.providerName = 'CleanPro Laundry',
    this.serviceTitle = 'Wash & Fold',
    this.serviceImage = 'lib/assets/images/wash&fold_detail.png',
    this.estimateLabel = 'Estimated 3 kg',
    this.basePrice = 450,
    this.durationLabel = '24 hour',
    required this.slotDate,
    required this.slotLabel,
    this.garments = const [],
    this.quantity,
  });

  @override
  State<LaundryCartScreen> createState() => _LaundryCartScreenState();
}

class _LaundryCartScreenState extends State<LaundryCartScreen> {
  late DateTime _slotDate;
  late String _slotLabel;
  int _paymentIndex = 0; // mandatory — Wallet selected by default
  bool _noPaymentMethod = false;
  bool _booking = false;

  /// The server's price for this booking (customer/service/quote):
  /// `subtotal`, `tax`, `total`. Null while loading or when it failed.
  Map<String, dynamic>? _quote;
  String? _quoteError;

  String get _paymentType =>
      _paymentIndex == 1 ? paymentTypeOnline : paymentTypeWallet;

  /// Pieces for per-item services; otherwise the "Estimated 3 kg" → 3 the
  /// customer chose (the server re-prices after weighing at pickup).
  num? get _quantity =>
      widget.quantity ??
      num.tryParse(
        RegExp(r'[\d.]+').firstMatch(widget.estimateLabel)?.group(0) ?? '',
      );

  Future<void> _loadQuote() async {
    setState(() {
      _quote = null;
      _quoteError = null;
    });
    try {
      final quote = await quoteServiceBooking(
        slotDate: _slotDate,
        slotLabel: _slotLabel,
        paymentType: _paymentType,
        garments: widget.garments,
        quantity: _quantity,
      );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        if (quote == null) _quoteError = 'svc_choose_service_again'.tr;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _quoteError = error.message);
    }
  }

  Future<void> _placeBooking() async {
    if (_noPaymentMethod) {
      showAppToast(
        'payment_no_method'.tr,
        backgroundColor: const Color(0xFFEF4444),
      );
      return;
    }
    if (_booking) return;
    if (_quote == null) {
      if (_quoteError != null) {
        showAppToast(_quoteError!, backgroundColor: const Color(0xFFEF4444));
      }
      return;
    }
    setState(() => _booking = true);
    final booking = await placeServiceBooking(
      shownTotal: _toPay,
      slotDate: _slotDate,
      slotLabel: _slotLabel,
      paymentType: _paymentType,
      garments: widget.garments,
      quantity: _quantity,
    );
    if (!mounted) return;
    setState(() => _booking = false);
    if (booking == null) return;
    Get.off(() => const LaundryBookingSuccessScreen());
  }

  // Translation keys.
  static const _months = [
    'svc_month_1',
    'svc_month_2',
    'svc_month_3',
    'svc_month_4',
    'svc_month_5',
    'svc_month_6',
    'svc_month_7',
    'svc_month_8',
    'svc_month_9',
    'svc_month_10',
    'svc_month_11',
    'svc_month_12',
  ];

  /// Keeps the choice on a method Admin has switched on (wallet or online).
  void _applyPaymentMethods() {
    final type = PaymentMethods.keepOrFirstOn(
      _paymentIndex == 1 ? paymentTypeOnline : paymentTypeWallet,
      const [paymentTypeWallet, paymentTypeOnline],
    );
    _noPaymentMethod = type == null;
    if (type != null) _paymentIndex = type == paymentTypeOnline ? 1 : 0;
  }

  @override
  void initState() {
    super.initState();
    _applyPaymentMethods();
    PaymentMethods.refresh().then((changed) {
      if (changed && mounted) setState(_applyPaymentMethods);
    });
    _slotDate = widget.slotDate;
    _slotLabel = widget.slotLabel;
    _loadQuote();
  }

  num? _quoted(String key) => num.tryParse('${_quote?[key] ?? ''}');

  /// The provider's price before tax; the cart's own estimate until the
  /// server answers.
  int get _subtotal => (_quoted('subtotal') ?? widget.basePrice).round();
  int? get _tax => _quoted('tax')?.round();
  int get _toPay => (_quoted('total') ?? _subtotal).round();

  /// "…" until the server has priced the booking.
  String _mruOrPending(int? amount) =>
      amount == null ? '…' : 'mru'.trParams({'amount': '$amount'});

  String get _slotDisplay {
    final d = _slotDate;
    return '${d.day} ${_months[d.month - 1].tr} ${d.year}, $_slotLabel';
  }

  String get _estimatedDelivery {
    final d = _slotDate.add(const Duration(days: 1));
    final dayLabel = 'svc_tomorrow'.tr;
    // Prefer tomorrow label when next day; otherwise date
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final isTomorrow =
        d.year == tomorrow.year &&
        d.month == tomorrow.month &&
        d.day == tomorrow.day;
    final prefix = isTomorrow
        ? dayLabel
        : '${d.day} ${_months[d.month - 1].tr} ${d.year}';
    return '$prefix, $_slotLabel';
  }

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

  Future<void> _changeSlot() async {
    final result = await LaundryChoosePickupSheet.show(context);
    if (result == null) return;
    setState(() {
      _slotDate = result['date'] as DateTime;
      _slotLabel = _slotRangeFromLabel(result['slot'] as String);
    });
    _loadQuote();
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFromClearRow(),
                      const SizedBox(height: 12),
                      _buildServiceCard(),
                      const SizedBox(height: 22),
                      _buildPickupSlotCard(),
                      const SizedBox(height: 10),
                      _buildEstimatedDeliveryCard(),
                      const SizedBox(height: 22),
                      _sectionTitle('svc_pickup_delivery'.tr),
                      const SizedBox(height: 12),
                      _buildPickupDeliveryCard(),
                      const SizedBox(height: 22),
                      _sectionTitle('svc_payment'.tr),
                      const SizedBox(height: 12),
                      if (PaymentMethods.isOn(paymentTypeWallet)) ...[
                        _buildPaymentOption(
                          index: 0,
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'wallet_title'.tr,
                          subtitle: walletBalanceSubtitle(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (PaymentMethods.isOn(paymentTypeOnline))
                        _buildPaymentOption(
                          index: 1,
                          icon: Icons.credit_card_rounded,
                          title: 'svc_online_payment'.tr,
                          subtitle: 'svc_card_mobile_money'.tr,
                        ),
                      if (_noPaymentMethod) const NoPaymentMethodNote(),
                      const SizedBox(height: 20),
                      _buildPaymentDetails(),
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
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'svc_cart'.tr,
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

  void _clearAll() {
    Get.back();
  }

  Widget _buildFromClearRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'svc_from_provider'.trParams({'provider': widget.providerName}),
            style: GoogleFonts.outfit(
              color: const Color(0xFF9A8E86),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        GestureDetector(
          onTap: _clearAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFE53935),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                'svc_clear_all'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFE53935),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildServiceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  widget.serviceImage,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFFFF3EB),
                    child: const Icon(
                      Icons.local_laundry_service_rounded,
                      color: Color(0xFFFF5E00),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      widget.serviceTitle,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Get.back(),
                child: Text(
                  'svc_edit'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.estimateLabel,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF5A6A7A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'mru'.trParams({'amount': '${widget.basePrice}'}),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedDeliveryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const _CalendarClockIcon(
            size: 24,
            color: Color(0xFF007AFF),
            cutoutColor: Color(0xFFEAF2F8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'svc_estimated_delivery'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _estimatedDelivery,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF5A6A7A),
                    fontSize: 12.5,
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

  Widget _buildPickupDeliveryCard() {
    const iconSize = 22.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: iconSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Line sits between icons — touches outer edges only
                  Positioned(
                    top: iconSize,
                    bottom: iconSize,
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFD0C8C0),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.radio_button_checked,
                      color: Color(0xFFFF5E00),
                      size: iconSize,
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF00B25C),
                      size: iconSize,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  _addressContent(
                    label: 'svc_pickup_upper'.tr,
                    labelColor: const Color(0xFFFF5E00),
                    title: 'Sahara View Home',
                    subtitle: 'Near Marhaba Supermarket, Nouakchott',
                  ),
                  const SizedBox(height: 18),
                  _addressContent(
                    label: 'svc_delivery_upper'.tr,
                    labelColor: const Color(0xFF00B25C),
                    title: 'Sahara View Home',
                    subtitle: 'Near Marhaba Supermarket, Nouakchott',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressContent({
    required String label,
    required Color labelColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: labelColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1B2B4A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8A7E76),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          'svc_edit'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFFFF5E00),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPickupSlotCard() {
    return GestureDetector(
      onTap: _changeSlot,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF5E00), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE0CC),
                shape: BoxShape.circle,
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
                    'svc_pickup_slot'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _slotDisplay,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF5A5A5A),
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
      ),
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _paymentIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        // Payment type is mandatory — switch between options, never clear.
        _paymentIndex = index;
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? const Color(0xFFFF5E00) : const Color(0xFFE8DFD6),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFFF5E00), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1B2B4A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? const Color(0xFFFF5E00)
                  : const Color(0xFFB0A59C),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2520),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'svc_payment_details'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _payRow('svc_total'.tr, 'mru'.trParams({'amount': '$_subtotal'})),
          const SizedBox(height: 10),
          _payRow('svc_tax'.tr, _mruOrPending(_tax)),
          if (_quoteError != null) ...[
            const SizedBox(height: 10),
            Text(
              _quoteError!,
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF8A80),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF4A4038), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'svc_to_pay'.tr,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'mru'.trParams({'amount': '$_toPay'}),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
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
            color: const Color(0xFFD4CBC3),
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

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
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
                      'svc_total_upper'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'mru'.trParams({'amount': '$_toPay'}),
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
                      'svc_duration_upper'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.durationLabel == '24 hour'
                          ? 'svc_24_hours'.tr
                          : widget.durationLabel,
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
            onTap: _placeBooking,
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
                _booking
                    ? 'svc_booking_in_progress'.tr
                    : 'svc_pay_amount'.trParams({'amount': '$_toPay'}),
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

/// Calendar with clock overlay matching the Estimated Delivery mock icon.
class _CalendarClockIcon extends StatelessWidget {
  final double size;
  final Color color;
  final Color cutoutColor;

  const _CalendarClockIcon({
    required this.size,
    required this.color,
    required this.cutoutColor,
  });

  @override
  Widget build(BuildContext context) {
    final clockSize = size * 0.46;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: size * 0.02,
            child: Icon(
              Icons.calendar_today_outlined,
              size: size * 0.88,
              color: color,
            ),
          ),
          Positioned(
            right: -1.5,
            bottom: -1.5,
            child: Container(
              width: clockSize,
              height: clockSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: cutoutColor, width: 1.5),
              ),
              child: CustomPaint(
                painter: _ClockHandsPainter(color: cutoutColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockHandsPainter extends CustomPainter {
  final Color color;

  _ClockHandsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final handLen = size.width * 0.28;

    // 12 o'clock
    canvas.drawLine(center, Offset(center.dx, center.dy - handLen), paint);
    // 3 o'clock
    canvas.drawLine(center, Offset(center.dx + handLen, center.dy), paint);
  }

  @override
  bool shouldRepaint(covariant _ClockHandsPainter oldDelegate) =>
      oldDelegate.color != color;
}
