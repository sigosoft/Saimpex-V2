import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../utils/payment_methods.dart';
import '../../utils/toast_helper.dart';
import '../../utils/wallet_balance.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/no_payment_method_note.dart';
import '../select_location_screen.dart';
import 'home_cleaning_booking_success_screen.dart';
import 'home_cleaning_choose_slot_sheet.dart';
import 'service_booking_submit.dart';

/// Orders gas from the supplier and product picked on [GasProviderScreen]
/// (ServiceBookingDraft). Gas is booked through customer/service/book with
/// vertical gas: `quantity` is the number of cylinders, and the customer must
/// confirm they hand back one empty cylinder per refill
/// (`return_empty_cylinder`, API §6.17). Prices come from service/quote.
class GasOrderScreen extends StatefulWidget {
  const GasOrderScreen({
    super.key,
    required this.providerName,
    required this.productTitle,
    this.productImage = '',
  });

  final String providerName;
  final String productTitle;
  final String productImage;

  @override
  State<GasOrderScreen> createState() => _GasOrderScreenState();
}

class _GasOrderScreenState extends State<GasOrderScreen> {
  static const _maxCylinders = 20;
  static const _paymentTypes = [
    paymentTypeCash,
    paymentTypeOnline,
    paymentTypeWallet,
  ];

  int _quantity = 1;
  bool _returnsEmpty = false;
  DateTime? _slotDate;
  String? _slotLabel;
  String _paymentType = paymentTypeCash;
  bool _noPaymentMethod = false;
  bool _booking = false;

  /// The server's price (customer/service/quote): `subtotal`, `tax`, `total`.
  Map<String, dynamic>? _quote;
  String? _quoteError;

  @override
  void initState() {
    super.initState();
    _applyPaymentMethods();
    PaymentMethods.refresh().then((changed) {
      if (changed && mounted) setState(_applyPaymentMethods);
    });
    _loadQuote();
  }

  /// Keeps the choice on a method Admin has switched on.
  void _applyPaymentMethods() {
    final type = PaymentMethods.keepOrFirstOn(_paymentType, _paymentTypes);
    _noPaymentMethod = type == null;
    if (type != null) _paymentType = type;
  }

  Future<void> _loadQuote() async {
    setState(() {
      _quote = null;
      _quoteError = null;
    });
    try {
      final quote = await quoteServiceBooking(
        slotDate: _slotDate ?? DateTime.now(),
        slotLabel: _slotLabel ?? '',
        paymentType: _paymentType,
        quantity: _quantity,
        returnEmptyCylinder: true,
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

  num? _quoted(String key) => num.tryParse('${_quote?[key] ?? ''}');

  void _changeQuantity(int by) {
    final next = (_quantity + by).clamp(1, _maxCylinders);
    if (next == _quantity) return;
    setState(() => _quantity = next);
    _loadQuote();
  }

  Future<void> _pickSlot() async {
    final result = await HomeCleaningChooseSlotSheet.show(context);
    if (result == null || !mounted) return;
    setState(() {
      _slotDate = result['date'] as DateTime;
      _slotLabel = formatServiceSlotLabel(result['slot'] as String);
    });
  }

  Future<void> _pickAddress() async {
    await Get.to(() => const SelectLocationScreen());
    if (mounted) setState(() {});
  }

  /// Why the order can't be placed yet, or null when it can.
  String? get _blocker {
    if (_noPaymentMethod) return 'payment_no_method'.tr;
    if (!_returnsEmpty) return 'gas_confirm_needed'.tr;
    if (_slotDate == null || _slotLabel == null) return 'gas_pick_time'.tr;
    if (_quote == null) return _quoteError;
    return null;
  }

  Future<void> _placeOrder() async {
    if (_booking) return;
    final blocker = _blocker;
    if (blocker != null) {
      showAppToast(blocker, backgroundColor: const Color(0xFFEF4444));
      return;
    }
    setState(() => _booking = true);
    final booking = await placeServiceBooking(
      shownTotal: _quoted('total'),
      slotDate: _slotDate!,
      slotLabel: _slotLabel!,
      paymentType: _paymentType,
      quantity: _quantity,
      returnEmptyCylinder: true,
    );
    if (!mounted) return;
    setState(() => _booking = false);
    if (booking == null) return;
    Get.off(() => const HomeCleaningBookingSuccessScreen());
  }

  String _mru(num? amount) =>
      amount == null ? '…' : 'mru'.trParams({'amount': '${amount.round()}'});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  Text(
                    'svc_from_provider'.trParams({
                      'provider': widget.providerName,
                    }),
                    style: _style(12.5, FontWeight.w500, _muted),
                  ),
                  const SizedBox(height: 12),
                  _buildProductCard(),
                  const SizedBox(height: 14),
                  _buildExchangeConfirm(),
                  const SizedBox(height: 22),
                  _sectionTitle('gas_delivery'.tr),
                  const SizedBox(height: 10),
                  _buildRow(
                    icon: Icons.location_on_outlined,
                    title: SelectLocationController.deliveryLabel.value,
                    subtitle: SelectLocationController.selectedSubtitle,
                    onTap: _pickAddress,
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    icon: Icons.calendar_month_outlined,
                    title: _slotDate == null
                        ? 'gas_pick_time'.tr
                        : _slotLabel ?? '',
                    subtitle: _slotDate == null
                        ? ''
                        : '${_slotDate!.day}/${_slotDate!.month}/${_slotDate!.year}',
                    onTap: _pickSlot,
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('svc_payment'.tr),
                  const SizedBox(height: 10),
                  if (PaymentMethods.isOn(paymentTypeCash))
                    _buildPaymentOption(
                      paymentTypeCash,
                      Icons.payments_outlined,
                      'gas_pay_cash'.tr,
                      'gas_pay_cash_hint'.tr,
                    ),
                  if (PaymentMethods.isOn(paymentTypeOnline))
                    _buildPaymentOption(
                      paymentTypeOnline,
                      Icons.credit_card_rounded,
                      'svc_online_payment'.tr,
                      'svc_card_mobile_money'.tr,
                    ),
                  if (PaymentMethods.isOn(paymentTypeWallet))
                    _buildPaymentOption(
                      paymentTypeWallet,
                      Icons.account_balance_wallet_outlined,
                      'wallet_title'.tr,
                      walletBalanceSubtitle(),
                    ),
                  if (_noPaymentMethod) const NoPaymentMethodNote(),
                  const SizedBox(height: 18),
                  _buildSummary(),
                ],
              ),
            ),
            _buildBottomBar(bottomInset),
          ],
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
              style: _style(17, FontWeight.w800, _ink),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: _style(15, FontWeight.w800, _ink));

  Widget _buildProductCard() {
    final image = widget.productImage;
    final icon = Container(
      width: 60,
      height: 60,
      color: const Color(0xFFFFF0E5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.propane_tank_rounded,
        color: Color(0xFFFF5E00),
        size: 28,
      ),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: image.startsWith('http')
                ? Image.network(
                    image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => icon,
                  )
                : icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productTitle,
                  style: _style(14.5, FontWeight.w800, _ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'gas_cylinders'.trParams({'count': '$_quantity'}),
                  style: _style(12, FontWeight.w500, _muted),
                ),
              ],
            ),
          ),
          _stepButton(Icons.remove_rounded, () => _changeQuantity(-1)),
          SizedBox(
            width: 30,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: _style(15, FontWeight.w800, _ink),
            ),
          ),
          _stepButton(Icons.add_rounded, () => _changeQuantity(1)),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Color(0xFFFF5E00),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  /// The required confirmation: one empty cylinder back per refill.
  Widget _buildExchangeConfirm() {
    return GestureDetector(
      onTap: () => setState(() => _returnsEmpty = !_returnsEmpty),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _returnsEmpty
              ? const Color(0xFFE8F8EE)
              : const Color(0xFFFFF0E5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _returnsEmpty
                ? const Color(0xFF00B25C)
                : const Color(0xFFFFC9A6),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _returnsEmpty
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: _returnsEmpty
                  ? const Color(0xFF00B25C)
                  : const Color(0xFFFF5E00),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'gas_confirm_empty'.trParams({'count': '$_quantity'}),
                style: _style(12.5, FontWeight.w600, const Color(0xFF3E3229)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration,
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF5E00), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(13.5, FontWeight.w700, _ink),
                  ),
                  if (subtitle.trim().isNotEmpty &&
                      subtitle.trim() != title.trim()) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _style(11.5, FontWeight.w500, _muted),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              'gas_change'.tr,
              style: _style(12.5, FontWeight.w700, const Color(0xFFFF5E00)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String type,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = _paymentType == type;
    return GestureDetector(
      onTap: () => setState(() => _paymentType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFFF5E00) : const Color(0xFFEAD8C9),
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF5E00), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _style(13, FontWeight.w800, _ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _style(11, FontWeight.w500, _muted)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? const Color(0xFFFF5E00)
                  : const Color(0xFFD9D0C8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: _style(13, FontWeight.w500, Colors.white70)),
          const Spacer(),
          Text(value, style: _style(13, FontWeight.w700, Colors.white)),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2520),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('svc_total'.tr, _mru(_quoted('subtotal'))),
          row('svc_tax'.tr, _mru(_quoted('tax'))),
          const Divider(color: Color(0xFF4A4038), height: 14),
          Row(
            children: [
              Text(
                'svc_to_pay'.tr,
                style: _style(16, FontWeight.w700, Colors.white),
              ),
              const Spacer(),
              Text(
                _mru(_quoted('total')),
                style: _style(19, FontWeight.w800, Colors.white),
              ),
            ],
          ),
          if (_quoteError != null) ...[
            const SizedBox(height: 10),
            Text(
              _quoteError!,
              style: _style(12, FontWeight.w500, const Color(0xFFFF8A80)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    final ready = _blocker == null;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: GestureDetector(
        onTap: _placeOrder,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: ready
                  ? const [Color(0xFFFF5E00), Color(0xFFFFAE00)]
                  : const [Color(0xFFD9D0C8), Color(0xFFD9D0C8)],
            ),
          ),
          child: Text(
            _booking
                ? 'svc_booking_in_progress'.tr
                : 'svc_pay_amount'.trParams({
                    'amount': '${(_quoted('total') ?? 0).round()}',
                  }),
            style: _style(15.5, FontWeight.w700, Colors.white),
          ),
        ),
      ),
    );
  }

  static const _ink = Color(0xFF2C2520);
  static const _muted = Color(0xFF9A8E86);

  static final _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  TextStyle _style(double size, FontWeight weight, Color color) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: weight, color: color);
}
