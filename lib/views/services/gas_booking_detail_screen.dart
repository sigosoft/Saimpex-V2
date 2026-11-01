import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../models/service_booking_detail.dart';
import '../../utils/app_fonts.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/cancel_booking_bottom_sheet.dart';
import '../../widgets/help_sheet.dart';
import '../chat_screen.dart';

/// Gas Booking Details (Figma V2 Additions → Gas Booking Details), from
/// customer/service/booking: cylinders, empties to hand over, status, payment.
class GasBookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const GasBookingDetailScreen({super.key, required this.booking});

  @override
  State<GasBookingDetailScreen> createState() => _GasBookingDetailScreenState();
}

class _GasBookingDetailScreenState extends State<GasBookingDetailScreen> {
  static const _orange = Color(0xFFFF5216);
  static const _ink = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF7A6A60);
  ServiceBookingDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await loadServiceBooking(
        widget.booking['apiOrderId'] as int?,
      );
      if (!mounted || detail == null) return;
      setState(() => _detail = detail);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  String _fromList(String key) => '${widget.booking[key] ?? ''}'.trim();

  String get _code {
    final code = _detail?.orderCode ?? '';
    return code.isNotEmpty ? code : _fromList('id');
  }

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0E6DC)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _row(String label, String value, {bool bold = true}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.outfit(color: _muted, fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppFonts.outfit(
              color: _ink,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _pill(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: AppFonts.outfit(
        color: fg,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _step(String label, String time, bool done) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done ? const Color(0xFFE3F6EA) : const Color(0xFFF1EEEA),
            shape: BoxShape.circle,
          ),
          child: Icon(
            done ? Icons.check_rounded : Icons.circle,
            size: done ? 14 : 5,
            color: done ? const Color(0xFF16A34A) : const Color(0xFFB8AFA8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            time.isEmpty ? label : '$label • $time',
            style: AppFonts.outfit(
              color: done ? _ink : const Color(0xFFA59A94),
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );

  /// "16:00" from the timeline's "31 Oct 2026,\n4:00 PM" style text.
  String _time(int status) {
    final text = _detail?.timeOf(status) ?? '';
    final parts = text.split('\n');
    return parts.length > 1 ? parts.last : text;
  }

  Widget _button(String label, VoidCallback onTap) => Expanded(
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        side: const BorderSide(color: _orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: AppFonts.outfit(
          color: _orange,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final status = detail?.status ?? 0;
    final cancelled = detail?.isCancelled ?? false;
    final statusLabel = detail?.statusLabel.isNotEmpty == true
        ? detail!.statusLabel
        : _fromList('status');
    final quantity = detail?.quantity ?? 1;
    final name = detail?.serviceName ?? '';
    final empties = detail?.emptyCylinders ?? 0;
    final steps = [
      (1, 'svc_gas_booked'.tr),
      (2, 'svc_gas_accepted'.tr),
      (8, 'svc_gas_on_way'.tr),
      (9, 'svc_gas_delivered'.tr),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F1),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: AppBackButton(onTap: () => Get.back()),
        ),
        centerTitle: true,
        title: Text(
          'svc_gas_title'.tr,
          style: AppFonts.outfit(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _orange,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _card([
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'svc_gas_booking'.trParams({'code': _code}),
                      style: AppFonts.outfit(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (statusLabel.isNotEmpty)
                    cancelled
                        ? _pill(
                            statusLabel,
                            const Color(0xFFDC2626),
                            const Color(0xFFFDECEC),
                          )
                        : _pill(
                            statusLabel,
                            const Color(0xFF2563EB),
                            const Color(0xFFEAF1FE),
                          ),
                ],
              ),
              const SizedBox(height: 8),
              _row(
                'svc_gas_supplier'.tr,
                detail?.providerName ?? _fromList('provider'),
              ),
              _row('svc_gas_slot'.tr, detail?.slot ?? _fromList('slot')),
            ]),
            const SizedBox(height: 12),
            _card([
              Text(
                'svc_gas_items'.tr,
                style: AppFonts.outfit(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              _row(
                name.isEmpty ? _fromList('service') : '$quantity × $name',
                detail == null ? '' : serviceMru(detail.subtotal),
                bold: true,
              ),
              if (empties > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'svc_gas_empties'.tr,
                        style: AppFonts.outfit(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _pill(
                      'svc_gas_cylinders'.trParams({'count': '$empties'}),
                      _orange,
                      const Color(0xFFFFEFE3),
                    ),
                  ],
                ),
              ],
            ]),
            const SizedBox(height: 12),
            _card([
              Text(
                'svc_gas_status'.tr,
                style: AppFonts.outfit(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              for (final (code, label) in steps)
                if (!cancelled || code == 1)
                  _step(
                    label,
                    _time(code),
                    detail != null && (detail.reached(code) || status == code),
                  ),
              if (cancelled) _step('svc_gas_cancelled'.tr, _time(10), true),
            ]),
            const SizedBox(height: 12),
            _card([
              _row(
                'svc_gas_payment'.tr,
                detail?.paymentLabel ?? _fromList('payment'),
              ),
              _row(
                'svc_gas_total'.tr,
                detail == null ? _fromList('price') : serviceMru(detail.total),
              ),
            ]),
            const SizedBox(height: 16),
            Row(
              children: [
                _button('svc_gas_chat'.tr, () {
                  final vendorId = detail?['vendor_id'];
                  if (vendorId == null) return;
                  Get.to(
                    () => ChatScreen(
                      restaurant: {
                        'vendor_id': vendorId,
                        'title': detail?.providerName ?? '',
                      },
                    ),
                  );
                }),
                const SizedBox(width: 10),
                _button(
                  'svc_gas_help'.tr,
                  () => HelpSheet.show(orderCode: _code),
                ),
              ],
            ),
            if (detail?.canCancel ?? widget.booking['canCancel'] == true) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => showCancelBookingBottomSheet(
                    context,
                    bookingId: _code,
                    apiOrderId: widget.booking['apiOrderId'] as int?,
                    onCancelled: () => Get.back(result: true),
                  ),
                  child: Text(
                    'cancel'.tr,
                    style: AppFonts.outfit(
                      color: _muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
