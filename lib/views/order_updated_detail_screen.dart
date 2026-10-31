import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../models/order_repository.dart';
import '../utils/api_language.dart';
import '../utils/payment_page.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import 'help_support_screen.dart';

/// Grocery substitution: what the store proposed for each order line
/// (customer/orders/{id}/substitutions), answered one by one before the
/// countdown ends (no answer = accepted, except a pricier substitute, which
/// is removed). An `amount_due` from a pricier substitute on a prepaid order
/// is paid in cash at the door, or online with "Pay online now" (payDue).
/// Layout follows the Figma "Order Changes" screen.
class OrderUpdatedDetailScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;
  final String storeName;

  const OrderUpdatedDetailScreen({
    super.key,
    required this.orderId,
    this.orderCode = '',
    this.storeName = '',
  });

  @override
  State<OrderUpdatedDetailScreen> createState() =>
      _OrderUpdatedDetailScreenState();
}

class _OrderUpdatedDetailScreenState extends State<OrderUpdatedDetailScreen> {
  List<Map<String, dynamic>> _rows = const [];
  num _orderTotal = 0;
  num _amountDue = 0;
  bool _loading = true;
  int? _answeringId;
  bool _payingDue = false;
  // Seconds left per pending substitution, counted down locally.
  final _secondsLeft = <int, int>{};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _secondsLeft.isEmpty) return;
    var expired = false;
    setState(() {
      for (final id in _secondsLeft.keys.toList()) {
        final left = _secondsLeft[id]! - 1;
        _secondsLeft[id] = left < 0 ? 0 : left;
        if (left == 0) expired = true;
      }
    });
    // The server decides what happens at zero; show its answer.
    if (expired) _load(quiet: true);
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    try {
      final data = await Get.find<OrderRepository>().substitutions(
        orderId: widget.orderId,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      final raw = data['substitutions'];
      final rows = raw is List
          ? raw.whereType<Map>().map(Map<String, dynamic>.from).toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _rows = rows;
        _orderTotal = num.tryParse('${data['order_total'] ?? ''}') ?? 0;
        _amountDue = num.tryParse('${data['amount_due'] ?? ''}') ?? 0;
        _secondsLeft
          ..clear()
          ..addEntries(
            rows
                .where((row) => row['status'] == 'pending')
                .map(
                  (row) => MapEntry(_int(row['id']), _int(row['seconds_left'])),
                ),
          );
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted && !quiet) setState(() => _loading = false);
    }
  }

  Future<void> _answer(int id, bool accept) async {
    if (_answeringId != null) return;
    setState(() => _answeringId = id);
    try {
      final result = await Get.find<OrderRepository>().respondSubstitution(
        substitutionId: id,
        accept: accept,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      final message = '${result['message'] ?? ''}'.trim();
      if (message.isNotEmpty) {
        showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _answeringId = null);
    }
    await _load(quiet: true);
  }

  Future<void> _payDueOnline() async {
    if (_payingDue) return;
    setState(() => _payingDue = true);
    try {
      final url = paymentPageUrl(
        await Get.find<OrderRepository>().payDue(
          orderId: widget.orderId,
          language: apiLanguageCode(),
        ),
      );
      if (!mounted) return;
      if (url == null) {
        showAppToast(
          'payment_page_failed'.tr,
          backgroundColor: const Color(0xFFEF4444),
        );
        return;
      }
      final paid = await openPaymentPage(url);
      if (!mounted) return;
      showAppToast(
        paid == true ? 'pad_paid'.tr : 'payment_not_completed'.tr,
        backgroundColor: paid == true
            ? const Color(0xFFFF5E00)
            : const Color(0xFFEF4444),
      );
      await _load(quiet: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _payingDue = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFF7F2),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F2),
        body: Column(
          children: [
            SizedBox(height: topInset + 10),
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5E00),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFFF5E00),
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          24 + bottomInset,
                        ),
                        children: [
                          _buildUpdatesBanner(),
                          const SizedBox(height: 20),
                          Text(
                            'subs_changes'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_rows.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'subs_none'.tr,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF8C7D73),
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            for (final row in _rows) ...[
                              _buildSubstitution(row),
                              const SizedBox(height: 10),
                            ],
                          const SizedBox(height: 10),
                          _buildTotalsCard(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final code = widget.orderCode.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppBackButton(onTap: () => Navigator.pop(context)),
          ),
          Text(
            'subs_order'.trParams({
              'code': code.isEmpty ? '#${widget.orderId}' : code,
            }),
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GestureDetector(
              onTap: () => Get.to(() => const HelpSupportScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE0D6CC)),
                ),
                child: Text(
                  'subs_help'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesBanner() {
    final store = widget.storeName.trim();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: const Color(0xFFFF5E00)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'subs_updates'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'subs_banner'.trParams({
                        'store': store.isEmpty ? 'subs_the_store'.tr : store,
                      }),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF6F655C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstitution(Map<String, dynamic> row) {
    final id = _int(row['id']);
    final status = '${row['status'] ?? ''}';
    final pending = status == 'pending';
    final original = row['original'] is Map
        ? Map<String, dynamic>.from(row['original'] as Map)
        : <String, dynamic>{};
    final substitute = row['substitute'] is Map
        ? Map<String, dynamic>.from(row['substitute'] as Map)
        : null;
    final change = num.tryParse('${row['amount_change'] ?? ''}') ?? 0;
    final note = '${row['note'] ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _productRow(original, faded: true),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (substitute == null)
                _badge(
                  label: 'subs_unavailable'.tr,
                  color: const Color(0xFFE03A3A),
                  bg: const Color(0xFFFFEBEE),
                  dot: true,
                )
              else
                _badge(
                  label: 'subs_suggested'.tr,
                  color: const Color(0xFF3B6FE8),
                  bg: const Color(0xFFEAF0FF),
                  icon: Icons.swap_vert_rounded,
                ),
              _statusBadge(status),
            ],
          ),
          if (substitute != null) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: Color(0xFFE03A3A),
                  size: 18,
                ),
              ),
            ),
            _productRow(substitute),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: GoogleFonts.outfit(
                color: const Color(0xFF6F655C),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
          if (change != 0) ...[
            const SizedBox(height: 8),
            Text(
              change > 0
                  ? 'subs_costs_more'.trParams({'amount': _money(change)})
                  : 'subs_costs_less'.trParams({'amount': _money(-change)}),
              style: GoogleFonts.outfit(
                color: change > 0
                    ? const Color(0xFFE03A3A)
                    : const Color(0xFF00B25C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (pending) ...[
            const SizedBox(height: 10),
            Text(
              'subs_answer_within'.trParams({
                'time': _countdown(_secondsLeft[id] ?? 0),
              }),
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (_answeringId == id)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _button(
                      'subs_reject'.tr,
                      outlined: true,
                      onTap: () => _answer(id, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _button(
                      'subs_accept'.tr,
                      onTap: () => _answer(id, true),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _productRow(Map<String, dynamic> product, {bool faded = false}) {
    final language = apiLanguageCode();
    final name = '${product['name_$language'] ?? product['name_en'] ?? ''}'
        .trim();
    final image = ApiConstants.mediaUrl('${product['image'] ?? ''}') ?? '';
    final quantity = num.tryParse('${product['quantity'] ?? ''}') ?? 0;
    final price = num.tryParse('${product['unit_price'] ?? ''}') ?? 0;
    return Opacity(
      opacity: faded ? 0.6 : 1,
      child: Row(
        children: [
          _thumb(image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'mru'.trParams({'amount': _money(price)}),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'X${_money(quantity)}',
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return switch (status) {
      'accepted' => _badge(
        label: 'subs_accepted'.tr,
        color: const Color(0xFF00B25C),
        bg: const Color(0xFFE8F8EE),
        dot: true,
      ),
      'auto_accepted' => _badge(
        label: 'subs_auto_accepted'.tr,
        color: const Color(0xFF00B25C),
        bg: const Color(0xFFE8F8EE),
        dot: true,
      ),
      'rejected' => _badge(
        label: 'subs_rejected'.tr,
        color: const Color(0xFF8C7D73),
        bg: const Color(0xFFF3EFEA),
        dot: true,
      ),
      _ => _badge(
        label: 'subs_waiting'.tr,
        color: const Color(0xFFFF5E00),
        bg: const Color(0xFFFFF0EA),
        dot: true,
      ),
    };
  }

  Widget _buildTotalsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'subs_updated_order'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFFAE00),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 14),
          _darkRow(
            'subs_order_total'.tr,
            'mru'.trParams({'amount': _money(_orderTotal)}),
          ),
          if (_amountDue > 0) ...[
            const SizedBox(height: 8),
            _darkRow(
              'subs_amount_due'.tr,
              'mru'.trParams({'amount': _money(_amountDue)}),
            ),
            const SizedBox(height: 10),
            Text(
              'subs_due_hint'.tr,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            if (_payingDue)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
              )
            else
              _button('subs_pay_due_online'.tr, onTap: _payDueOnline),
          ],
        ],
      ),
    );
  }

  Widget _button(
    String label, {
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? const Color(0xFFF3EFEA) : null,
          gradient: outlined
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: outlined ? const Color(0xFF2C2520) : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _darkRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _thumb(String url) {
    Widget fallback() => Container(
      width: 52,
      height: 52,
      color: const Color(0xFFF3EFEA),
      child: const Icon(Icons.image_not_supported_outlined, size: 20),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url.isEmpty
          ? fallback()
          : Image.network(
              url,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback(),
            ),
    );
  }

  Widget _badge({
    required String label,
    required Color color,
    required Color bg,
    IconData? icon,
    bool dot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ] else if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static int _int(dynamic value) => int.tryParse('${value ?? ''}') ?? 0;

  static String _money(num value) =>
      value == value.roundToDouble() ? '${value.toInt()}' : '$value';

  static String _countdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}
