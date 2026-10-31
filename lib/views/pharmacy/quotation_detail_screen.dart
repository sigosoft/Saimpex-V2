import 'dart:async';
import '../../widgets/app_back_button.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/order_repository.dart';
import '../../models/pharmacy_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../chat_screen.dart';
import '../order_success_screen.dart';
import '../payment_webview_screen.dart';
import 'prescription_checkout_screen.dart';
import 'widgets/pharmacy_background.dart';

/// Asks the customer to confirm, then declines the quotation on the server.
/// Returns true once it is declined.
Future<bool> declineQuotation(BuildContext context, int prescriptionId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'pw_decline_quotation_q'.tr,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'pw_decline_quotation_body'.tr,
        style: GoogleFonts.outfit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('pw_keep'.tr, style: GoogleFonts.outfit()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            'pw_decline'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    final message = await Get.find<PharmacyRepository>().declinePrescription(
      prescriptionId: prescriptionId,
      language: apiLanguageCode(),
    );
    showAppToast(
      message.isEmpty ? 'pw_quotation_declined'.tr : message,
      backgroundColor: const Color(0xFFFF5E00),
    );
    return true;
  } on ApiException catch (error) {
    showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    return false;
  }
}

class QuotationDetailScreen extends StatefulWidget {
  final String orderId;
  final String pharmacyName;
  final Duration expiresIn;
  final int? prescriptionId;
  final String amount;

  const QuotationDetailScreen({
    super.key,
    required this.orderId,
    required this.pharmacyName,
    required this.expiresIn,
    this.prescriptionId,
    this.amount = '',
  });

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  late Duration _remaining;
  Timer? _timer;
  var _loading = false;
  var _paying = false;
  // Server status of the prescription (uploaded, quoted, accepted, ...)
  String _status = '';
  String _pharmacyName = '';
  String _fileName = '';
  String _amountText = '';
  num _quoteAmount = 0;
  final _availableItems = <Map<String, dynamic>>[];
  final _alternativeItems = <Map<String, dynamic>>[];
  // Alternatives still waiting for accept/reject; accept and pay are refused
  // by the server until this is 0.
  int _pendingAlternatives = 0;
  int? _decidingItemId;

  Future<void> _decideAlternative(int itemId, bool accept) async {
    final id = widget.prescriptionId;
    if (id == null || _decidingItemId != null) return;
    setState(() => _decidingItemId = itemId);
    try {
      await Get.find<PharmacyRepository>().decideAlternatives(
        prescriptionId: id,
        decisions: {itemId: accept},
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      // The server recomputes the quote total; show its numbers.
      await _loadPrescription();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _decidingItemId = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _pharmacyName = widget.pharmacyName;
    _amountText = widget.amount;
    _remaining = widget.expiresIn;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
    _loadPrescription();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrescription() async {
    final id = widget.prescriptionId;
    if (id == null || id < 1 || !Get.isRegistered<PharmacyRepository>()) {
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await Get.find<PharmacyRepository>().fetchPrescription(
        prescriptionId: id,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      final pharmacy = '${data['mapped_pharmacy_name'] ?? ''}'.trim();
      final fileName = '${data['mapped_file_name'] ?? ''}'.trim();
      final quote = data['quote_amount'] ?? data['total'] ?? data['payable'];
      final quoteNumber = quote is num ? quote : num.tryParse('$quote');
      final seconds = data['quote_expires_in_seconds'];
      final items = data['mapped_items'];
      _availableItems.clear();
      _alternativeItems.clear();
      if (items is List) {
        for (final entry in items) {
          final item = entry is Map<String, dynamic> ? entry : null;
          if (item == null) continue;
          if (item['isAlternative'] == true) {
            _alternativeItems.add(item);
          } else {
            _availableItems.add(item);
          }
        }
      }
      setState(() {
        _status = '${data['status'] ?? ''}'.trim();
        _pendingAlternatives =
            int.tryParse('${data['pending_alternatives'] ?? 0}') ?? 0;
        if (pharmacy.isNotEmpty) _pharmacyName = pharmacy;
        if (fileName.isNotEmpty) _fileName = fileName;
        if (quoteNumber != null) {
          _quoteAmount = quoteNumber;
          _amountText = _moneyText(quoteNumber);
        }
        if (seconds is int && seconds > 0) {
          _remaining = Duration(seconds: seconds);
        }
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  Future<void> _payPrescription() async {
    final id = widget.prescriptionId;
    if (_paying) return;
    if (id == null || id < 1 || !Get.isRegistered<PharmacyRepository>()) {
      return;
    }
    if (_pendingAlternatives > 0) {
      showAppToast(
        'quote_decide_alternatives'.tr,
        backgroundColor: const Color(0xFFEF4444),
      );
      return;
    }
    _paying = true;
    try {
      final repository = Get.find<PharmacyRepository>();
      final language = apiLanguageCode();
      // Review first: the customer confirms delivery or pickup on the checkout page
      final choice = await Get.to<PrescriptionCheckoutChoice>(
        () => PrescriptionCheckoutScreen(
          pharmacyName: _pharmacyName,
          quoteAmount: _quoteAmount,
        ),
      );
      if (choice == null || !mounted) return;
      // Accepting twice fails on the server, so only accept a quote not yet accepted
      if (_status != 'accepted') {
        await repository.acceptPrescription(
          prescriptionId: id,
          language: language,
        );
        if (mounted) setState(() => _status = 'accepted');
      }
      final location = SelectLocationController.selectedSubtitle.trim().isEmpty
          ? SelectLocationController.deliveryLabel.value
          : SelectLocationController.selectedSubtitle;
      final placed = await repository.payPrescription(
        prescriptionId: id,
        selfPickup: !choice.delivery,
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        location: location,
        paymentType: choice.paymentType,
        language: language,
        couponCode: choice.couponCode,
        note: choice.note,
      );
      if (!mounted) return;
      await _finishPaidPrescription(placed);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      _paying = false;
    }
  }

  Future<void> _finishPaidPrescription(Map<String, dynamic> placed) async {
    final message = '${placed['message'] ?? ''}'.trim();
    if (message.isNotEmpty) {
      showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
    }
    // Paid from the wallet: the order is placed and paid already.
    if (placed['payment_required'] == false) {
      Get.to(() => const OrderSuccessScreen());
      return;
    }
    var paymentUrl = _paymentPageUrlFrom(placed);
    final payable =
        placed['payable'] ??
        placed['to_pay'] ??
        placed['quote_amount'] ??
        _quoteAmount;
    final orderId = _positiveId(placed['order_id'] ?? placed['id']);
    if (orderId != null && Get.isRegistered<OrderRepository>()) {
      final startedUrl = await _startMasrviPayment(orderId, payable);
      if (startedUrl != null) paymentUrl = startedUrl;
    }
    if (!mounted) return;
    final needsOnlinePayment =
        placed['payment_required'] == true ||
        placed['payment_required'] == 1 ||
        paymentUrl != null ||
        message.toLowerCase().contains('complete online payment');
    final url =
        paymentUrl ??
        (needsOnlinePayment && orderId != null
            ? _paymentPageUrl(
                'https://dev.saimpexenterprise.com/pay/masrvi/payment/session?order_id=$orderId',
              )
            : null);
    if (needsOnlinePayment) {
      if (url == null) return;
      Get.closeAllSnackbars();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final paid = await Get.to<bool>(() => PaymentWebViewScreen(url: url));
      if (!mounted || paid != true) return;
    }
    Get.to(() => const OrderSuccessScreen());
  }

  Future<String?> _startMasrviPayment(int orderId, dynamic payable) async {
    final orders = Get.find<OrderRepository>();
    final language = apiLanguageCode();
    try {
      await orders.masrviSession(language);
    } on ApiException catch (error) {
      if (!mounted) return null;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      return null;
    }
    try {
      final started = await orders.masrviInit(
        orderId: orderId,
        amount: _moneyArgument(payable),
        language: language,
      );
      if (!mounted) return null;
      final message = '${started['message'] ?? ''}'.trim();
      if (message.isNotEmpty) {
        showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      }
      return _paymentPageUrlFrom(started);
    } on ApiException catch (error) {
      if (!mounted) return null;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      return null;
    }
  }

  String? _paymentPageUrlFrom(Map<String, dynamic> data) {
    for (final key in [
      'payment_url',
      'url',
      'redirect_url',
      'checkout_url',
      'session_url',
    ]) {
      final url = _paymentPageUrl(data[key]);
      if (url != null) return url;
    }
    return null;
  }

  String? _paymentPageUrl(dynamic value) {
    final raw = '$value'.trim();
    if (raw.isEmpty || raw == 'null') return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    final wrongHost =
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == 'api.saimpexenterprise.com';
    if (wrongHost && uri.path.contains('/pay/')) {
      return Uri(
        scheme: 'https',
        host: 'dev.saimpexenterprise.com',
        path: uri.path,
        query: uri.hasQuery ? uri.query : null,
      ).toString();
    }
    return uri.toString();
  }

  int? _positiveId(dynamic value) {
    final number = value is int ? value : int.tryParse('$value');
    if (number == null || number < 1) return null;
    return number;
  }

  String _moneyArgument(dynamic value) {
    final number = value is num ? value : num.tryParse('$value');
    if (number == null) return '0';
    if (number == number.roundToDouble()) return '${number.toInt()}';
    return '$number';
  }

  String _moneyText(dynamic value) {
    final number = value is num ? value : num.tryParse('$value');
    if (number == null) {
      final text = '$value'.trim();
      if (text.isEmpty || text == 'null') return widget.amount;
      return text.toUpperCase().contains('MRU')
          ? text
          : 'mru'.trParams({'amount': text});
    }
    final text = number == number.roundToDouble()
        ? '${number.toInt()}'
        : number.toStringAsFixed(2);
    return 'mru'.trParams({'amount': text});
  }

  String get _timerText {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PharmacyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppBackButton(onTap: () => Navigator.pop(context)),
                  ),
                  Text(
                    'pw_order_id'.trParams({'id': widget.orderId}),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPharmacyCard(),
                    const SizedBox(height: 12),
                    _buildExpiryBanner(),
                    const SizedBox(height: 12),
                    _buildPrescriptionCard(),
                    const SizedBox(height: 20),
                    Text(
                      'pw_medicines_in_quotation'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAvailableItemsCard(),
                    if (_alternativeItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      for (var i = 0; i < _alternativeItems.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _buildAlternativeCard(_alternativeItems[i]),
                      ],
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'pw_order_status'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOrderStatusCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 12),
                    _buildPayButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPharmacyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pharmacyName,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'pw_delivery_prescription_order'.trParams({
                    'id': widget.orderId,
                  }),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF7E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'pw_quotation_ready_caps'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFF00A854),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.alarm_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'pw_quote_expires_in'.tr,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            _timerText,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              color: Colors.white,
              alignment: Alignment.center,
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFFA59A94),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName.isEmpty ? 'pw_prescription'.tr : _fileName,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'pw_view_full_prescription'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: Color(0xFFFF5E00),
                      size: 13,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableItemsCard() {
    if (_availableItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'pw_no_quoted_items'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFFA59A94),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < _availableItems.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFEFE8E1)),
              ),
            _quotedItemRow(_availableItems[i]),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEFE8E1)),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              _amountText,
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One quoted line: available, partial (less than requested) or
  /// unavailable (shown, costs nothing).
  Widget _quotedItemRow(Map<String, dynamic> item) {
    final availability = '${item['availability'] ?? 'available'}';
    final requested = item['requestedQty'];
    final unavailable = availability == 'unavailable';
    final meta = switch (availability) {
      'unavailable' => 'quote_unavailable'.tr,
      'partial' => 'quote_partial'.trParams({
        'qty': '${item['qty']}',
        'requested': '${requested ?? item['qty']}',
        'unit': '${item['unitText']}',
      }),
      _ => 'quote_line'.trParams({
        'qty': '${item['qty']}',
        'unit': '${item['unitText']}',
      }),
    };
    return Opacity(
      opacity: unavailable ? 0.55 : 1,
      child: _medicineRow(
        title: '${item['name']}',
        meta: meta,
        price: unavailable
            ? 'mru'.trParams({'amount': '0'})
            : '${item['totalText']}',
        metaColor: availability == 'available' ? null : const Color(0xFFE53935),
      ),
    );
  }

  Widget _medicineRow({
    required String title,
    required String meta,
    required String price,
    Color? metaColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                meta,
                style: GoogleFonts.outfit(
                  color: metaColor ?? const Color(0xFFA59A94),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeCard(Map<String, dynamic> item) {
    final originalName = '${item['originalName'] ?? ''}'.trim();
    final alternativeName = '${item['alternativeName'] ?? ''}'.trim();
    final title = alternativeName.isEmpty ? '${item['name']}' : alternativeName;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    originalName.isEmpty ? '${item['name']}' : originalName,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: const Color(0xFFA59A94),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'quote_not_available'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFE53935),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              const Divider(height: 1, thickness: 1, color: Color(0xFFEFE8E1)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0EC),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: Color(0xFF8A7F77),
                  size: 16,
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'quote_suggested_alternative'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'quote_line'.trParams({
                              'qty': '${item['alternativeQty']}',
                              'unit': '${item['alternativeUnitText']}',
                            }),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item['alternativeTotalText']}',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _alternativeDecision(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Accept / Reject while the quote is open; afterwards, what was decided.
  Widget _alternativeDecision(Map<String, dynamic> item) {
    final itemId = item['itemId'] is int ? item['itemId'] as int : 0;
    final decision = '${item['decision'] ?? ''}';
    if (decision == 'accepted' || decision == 'rejected') {
      final accepted = decision == 'accepted';
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
          accepted ? 'quote_alt_accepted'.tr : 'quote_alt_rejected'.tr,
          style: GoogleFonts.outfit(
            color: accepted ? const Color(0xFF00B25C) : const Color(0xFF8A7F77),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (_status != 'quoted' || itemId <= 0) return const SizedBox.shrink();
    if (_decidingItemId == itemId) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
      );
    }
    Widget button(String label, bool accept) => Expanded(
      child: GestureDetector(
        onTap: () => _decideAlternative(itemId, accept),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accept ? null : Colors.white,
            gradient: accept
                ? const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            border: accept ? null : Border.all(color: const Color(0xFFE0D6CC)),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: accept ? Colors.white : const Color(0xFF2C2520),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
    return Row(
      children: [
        button('quote_alt_reject'.tr, false),
        const SizedBox(width: 10),
        button('quote_alt_accept'.tr, true),
      ],
    );
  }

  Widget _buildOrderStatusCard() {
    const steps = [
      _StatusStep(
        label: 'pw_step2_prescription_sent',
        time: '22 Oct 2023,\n10:30 AM',
        done: true,
        icon: Icons.check_rounded,
      ),
      _StatusStep(
        label: 'pw_step2_under_review',
        time: '22 Oct 2023,\n10:35 AM',
        done: true,
        icon: Icons.description_outlined,
      ),
      _StatusStep(
        label: 'pw_step2_quotation_ready',
        time: '22 Oct 2023,\n10:40 AM',
        done: true,
        icon: Icons.request_quote_outlined,
      ),
      _StatusStep(
        label: 'pw_step2_review_pay',
        time: '',
        done: false,
        icon: Icons.check_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const circle = 34.0;
          final usable = constraints.maxWidth - circle;
          final segment = usable / 3;

          return Column(
            children: [
              SizedBox(
                height: circle,
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    Positioned(
                      left: circle / 2,
                      right: circle / 2,
                      child: Row(
                        children: List.generate(3, (i) {
                          final active = i < 2;
                          return Container(
                            width: segment,
                            height: 3,
                            color: active
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFFE5DDD4),
                          );
                        }),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: steps.map((step) {
                        return Container(
                          width: circle,
                          height: circle,
                          decoration: BoxDecoration(
                            color: step.done
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFFEFE8E1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step.icon,
                            color: step.done
                                ? Colors.white
                                : const Color(0xFFB0A59C),
                            size: 18,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: steps.map((step) {
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          step.label.tr,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        if (step.time.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            step.time,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'pw_quotation_summary_caps'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'pw_item_total'.tr,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _amountText,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFF3A434E)),
          ),
          Row(
            children: [
              Text(
                'pw_to_pay'.tr,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _amountText,
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final id = widget.prescriptionId;
              if (id == null || _status != 'quoted') {
                Navigator.pop(context);
                return;
              }
              final declined = await declineQuotation(context, id);
              if (declined && mounted) Navigator.pop(context, true);
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFEA),
                borderRadius: BorderRadius.circular(23),
              ),
              alignment: Alignment.center,
              child: Text(
                'pw_decline_quotation'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Get.to(
                () => ChatScreen(
                  restaurant: {'title': _pharmacyName, 'image': ''},
                ),
              );
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5E00),
                borderRadius: BorderRadius.circular(23),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'pw_chat_with_pharmacy'.tr,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return GestureDetector(
      onTap: _paying ? null : _payPrescription,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              'pw_review_and_pay'.tr,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              _amountText,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStep {
  final String label;
  final String time;
  final bool done;
  final IconData icon;

  const _StatusStep({
    required this.label,
    required this.time,
    required this.done,
    required this.icon,
  });
}
