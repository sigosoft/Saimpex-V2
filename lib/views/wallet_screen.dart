import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import '../core/network/api_exception.dart';
import '../models/wallet_repository.dart';
import '../utils/api_language.dart';
import '../utils/payment_page.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';

/// SAIMPEX Wallet: balance, transaction history (GET wallet) and top-up
/// (POST wallet/topup, paid on the Masrvi page). Built without a Figma screen,
/// in the app's style.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  num _balance = 0;
  num _minTopUp = 100;
  num _maxTopUp = 50000;
  final _transactions = <Map<String, dynamic>>[];
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _toppingUp = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more) {
      if (_loadingMore || _page >= _lastPage) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }
    try {
      final data = await Get.find<WalletRepository>().fetch(
        language: apiLanguageCode(),
        page: more ? _page + 1 : 1,
      );
      if (!mounted) return;
      final limits = data['topup_limits'] is Map
          ? Map<String, dynamic>.from(data['topup_limits'] as Map)
          : <String, dynamic>{};
      final pagination = data['pagination'] is Map
          ? Map<String, dynamic>.from(data['pagination'] as Map)
          : <String, dynamic>{};
      final rows = data['transactions'] is List
          ? (data['transactions'] as List).whereType<Map>().map(
              Map<String, dynamic>.from,
            )
          : const <Map<String, dynamic>>[];
      setState(() {
        _balance = num.tryParse('${data['balance'] ?? ''}') ?? _balance;
        _minTopUp = num.tryParse('${limits['min'] ?? ''}') ?? _minTopUp;
        _maxTopUp = num.tryParse('${limits['max'] ?? ''}') ?? _maxTopUp;
        _page = int.tryParse('${pagination['current_page'] ?? ''}') ?? 1;
        _lastPage = int.tryParse('${pagination['last_page'] ?? ''}') ?? 1;
        if (!more) _transactions.clear();
        _transactions.addAll(rows);
      });
      _shareBalance();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  /// Keeps the balance shown on Home and at checkout in step.
  void _shareBalance() {
    if (!Get.isRegistered<HomeController>()) return;
    Get.find<HomeController>().walletBalance.value = _money(_balance);
  }

  Future<void> _topUp() async {
    final amount = await _askAmount();
    if (amount == null || !mounted) return;
    setState(() => _toppingUp = true);
    try {
      final repository = Get.find<WalletRepository>();
      final language = apiLanguageCode();
      final started = await repository.topUp(
        amount: amount,
        language: language,
      );
      final topUpId = int.tryParse('${started['topup_id'] ?? ''}');
      final url = paymentPageUrl(started['payment_url']);
      if (topUpId == null || url == null) {
        showAppToast(
          'payment_page_failed'.tr,
          backgroundColor: const Color(0xFFEF4444),
        );
        return;
      }
      await openPaymentPage(url);
      if (!mounted) return;
      // The Masrvi webhook credits the wallet; ask the server what happened.
      final status = await _waitForTopUp(topUpId);
      if (!mounted) return;
      showAppToast(
        switch (status) {
          'paid' => 'wallet_topup_paid'.tr,
          'failed' => 'wallet_topup_failed'.tr,
          _ => 'wallet_topup_pending'.tr,
        },
        backgroundColor: status == 'paid'
            ? const Color(0xFFFF5E00)
            : const Color(0xFFEF4444),
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _toppingUp = false);
    }
  }

  /// Polls the top-up a few times while the webhook arrives.
  Future<String> _waitForTopUp(int topUpId) async {
    var status = 'pending';
    for (var attempt = 0; attempt < 5; attempt++) {
      final data = await Get.find<WalletRepository>().topUpStatus(
        topUpId: topUpId,
        language: apiLanguageCode(),
      );
      status = '${data['status'] ?? 'pending'}';
      if (status != 'pending') break;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return status;
  }

  Future<num?> _askAmount() {
    final controller = TextEditingController();
    return showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String? error;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void submit() {
              final value = num.tryParse(controller.text.trim());
              if (value == null || value < _minTopUp || value > _maxTopUp) {
                setSheetState(
                  () => error = 'wallet_topup_limits'.trParams({
                    'min': _money(_minTopUp),
                    'max': _money(_maxTopUp),
                  }),
                );
                return;
              }
              Navigator.pop(sheetContext, value);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF6F0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'wallet_topup'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'wallet_topup_limits'.trParams({
                          'min': _money(_minTopUp),
                          'max': _money(_maxTopUp),
                        }),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8C7D73),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: error == null
                                ? const Color(0xFFEAD8C9)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSubmitted: (_) => submit(),
                          style: GoogleFonts.outfit(fontSize: 16),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'wallet_topup_amount'.tr,
                            suffixText: 'orders_currency'.tr,
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          error!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFEF4444),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _primaryButton('wallet_topup_continue'.tr, submit),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppBackButton(onTap: () => Get.back()),
                  ),
                  Text(
                    'wallet_title'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
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
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.extentAfter < 200) {
                            _load(more: true);
                          }
                          return false;
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            _buildBalanceCard(),
                            const SizedBox(height: 22),
                            Text(
                              'wallet_history'.tr,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_transactions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Text(
                                  'wallet_no_history'.tr,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF8C7D73),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              for (final row in _transactions) ...[
                                _buildTransaction(row),
                                const SizedBox(height: 10),
                              ],
                            if (_loadingMore)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFF5E00),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'wallet_balance'.tr,
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'mru'.trParams({'amount': _money(_balance)}),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _toppingUp ? null : _topUp,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: _toppingUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5E00),
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      'wallet_topup'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaction(Map<String, dynamic> row) {
    final credit = row['type'] == 'credit';
    final amount = num.tryParse('${row['amount'] ?? ''}') ?? 0;
    final description = '${row['description'] ?? ''}'.trim();
    final date = DateTime.tryParse('${row['created_at'] ?? ''}')?.toLocal();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: credit ? const Color(0xFFE8F8EE) : const Color(0xFFFFEDEA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: credit ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isEmpty
                      ? (credit ? 'wallet_credit'.tr : 'wallet_debit'.tr)
                      : description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (date != null)
                  Text(
                    _date(date),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${credit ? '+' : '-'}${'mru'.trParams({'amount': _money(amount)})}',
            style: GoogleFonts.outfit(
              color: credit ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  static String _money(num value) => value == value.roundToDouble()
      ? '${value.toInt()}'
      : value.toStringAsFixed(2);

  static String _date(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.day)}/${two(time.month)}/${time.year} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}
