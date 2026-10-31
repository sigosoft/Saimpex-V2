import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_exception.dart';
import '../../models/pharmacy_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/app_back_button.dart';
import 'quotation_detail_screen.dart';
import 'widgets/pharmacy_background.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> {
  static const _filters = <(String, String?)>[
    ('All', null),
    ('Under Review', 'uploaded'),
    ('Quoted', 'quoted'),
    ('Accepted', 'accepted'),
    ('Ordered', 'ordered'),
    ('Rejected', 'rejected'),
  ];

  int _filterIndex = 0;
  bool _loading = false;
  int _requestId = 0;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Get.isRegistered<PharmacyRepository>()) return;
    final requestId = ++_requestId;
    setState(() => _loading = true);
    try {
      final result = await Get.find<PharmacyRepository>()
          .fetchPrescriptionsList(
            language: apiLanguageCode(),
            status: _filters[_filterIndex].$2,
            limit: 50,
          );
      if (!mounted || requestId != _requestId) return;
      setState(() => _items = result.prescriptions);
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectFilter(int index) {
    if (index == _filterIndex) return;
    setState(() => _filterIndex = index);
    _load();
  }

  Duration _expiresIn(String quoteExpiresAt) {
    final expiry = DateTime.tryParse(quoteExpiresAt);
    if (expiry == null) return Duration.zero;
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _openItem(Map<String, dynamic> item) async {
    if (item['status'] != 'quoted') return;
    final id = item['prescriptionId'] as int;
    final declined = await Get.to<bool>(
      () => QuotationDetailScreen(
        orderId: '#$id',
        pharmacyName: '${item['pharmacyName']}',
        expiresIn: _expiresIn('${item['quoteExpiresAt']}'),
        prescriptionId: id,
        amount: '${item['quoteAmountText']}',
      ),
    );
    if (declined == true && mounted) _load();
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
                    alignment: Alignment.centerLeft,
                    child: AppBackButton(onTap: () => Navigator.pop(context)),
                  ),
                  Text(
                    'My Prescriptions',
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
        body: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = index == _filterIndex;
                  return GestureDetector(
                    onTap: () => _selectFilter(index),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFF5E00)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE8DFD6)),
                      ),
                      child: Text(
                        _filters[index].$1,
                        style: GoogleFonts.outfit(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF2C2520),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList(bottomInset)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(double bottomInset) {
    if (_loading && _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No prescriptions found',
          style: GoogleFonts.outfit(
            color: const Color(0xFFA59A94),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + bottomInset),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildCard(_items[index]),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final quoted = item['status'] == 'quoted';
    final amount = '${item['quoteAmountText']}';
    final pharmacy = '${item['pharmacyName']}'.trim();

    return GestureDetector(
      onTap: quoted ? () => _openItem(item) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.isEmpty ? 'Pharmacy' : pharmacy,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prescription #${item['prescriptionId']} • ${item['createdAt']}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item['statusLabel'] ?? ''}'.isEmpty
                        ? '${item['status']}'
                        : '${item['statusLabel']}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (amount.isNotEmpty)
              Text(
                amount,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (quoted) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFA59A94)),
            ],
          ],
        ),
      ),
    );
  }
}
