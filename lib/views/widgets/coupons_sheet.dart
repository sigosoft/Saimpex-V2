import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_exception.dart';
import '../../models/order_repository.dart';
import '../../utils/api_language.dart';

/// Lists the coupons the customer can use with their current cart
/// (customer/coupons) and returns the code they pick.
Future<String?> showCouponsSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CouponsSheet(),
  );
}

class _CouponsSheet extends StatefulWidget {
  const _CouponsSheet();

  @override
  State<_CouponsSheet> createState() => _CouponsSheetState();
}

class _CouponsSheetState extends State<_CouponsSheet> {
  List<Map<String, dynamic>> _coupons = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final coupons = await Get.find<OrderRepository>().coupons(
        apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        _coupons = coupons;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'core_coupons_sheet_title'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
        ),
      );
    }
    if (_error != null || _coupons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            _error ?? 'core_coupons_sheet_empty'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF8C7D73),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _coupons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final coupon = _coupons[index];
        final subtitle = '${coupon['subtitle']}';
        final discount = '${coupon['discount']}';
        return GestureDetector(
          onTap: () => Navigator.pop(context, '${coupon['code']}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: Color(0xFFFF5E00),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${coupon['code']}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      if ('${coupon['title']}' != '${coupon['code']}')
                        Text(
                          '${coupon['title']}',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF5C5048),
                            fontSize: 12,
                          ),
                        ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (discount.isNotEmpty)
                  Text(
                    discount,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
