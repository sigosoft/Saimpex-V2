import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../models/order_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import 'order_detail_screen.dart';
import 'pharmacy/pharmacy_item_order_detail_screen.dart';
import 'widgets/scheduled_for_banner.dart';

/// The customer's open pre-orders (GET customer/preorders), soonest first.
class MySchedulesScreen extends StatefulWidget {
  const MySchedulesScreen({super.key});

  @override
  State<MySchedulesScreen> createState() => _MySchedulesScreenState();
}

class _MySchedulesScreenState extends State<MySchedulesScreen> {
  int _selectedFilter = 0;

  // Filter chips: label key and the order types it shows (null = all).
  static const _filters = <(String, Set<int>?)>[
    ('orders_filter_all', null),
    ('search_vertical_food', {1}),
    ('search_vertical_grocery', {2, 11}),
    ('search_vertical_pharmacy', {3}),
  ];

  static const _typeIcons = <int, IconData>{
    1: Icons.restaurant_rounded,
    2: Icons.shopping_basket_rounded,
    3: Icons.local_pharmacy_rounded,
    4: Icons.water_drop_rounded,
    11: Icons.storefront_rounded,
  };

  static const _typeLabels = <int, String>{
    1: 'search_vertical_food',
    2: 'search_vertical_grocery',
    3: 'search_vertical_pharmacy',
    4: 'search_vertical_water',
    11: 'search_vertical_local_store',
  };

  List<Map<String, dynamic>> _schedules = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Get.find<OrderRepository>().preorders(
        apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        _schedules = rows;
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

  List<Map<String, dynamic>> get _filtered {
    final types = _filters[_selectedFilter].$2;
    if (types == null) return _schedules;
    return _schedules.where((s) => types.contains(_orderType(s))).toList();
  }

  static int _orderType(Map<String, dynamic> item) =>
      int.tryParse('${item['order_type'] ?? ''}') ?? 0;

  static int _orderId(Map<String, dynamic> item) =>
      int.tryParse('${item['order_id'] ?? ''}') ?? 0;

  static Map<String, dynamic> _vendor(Map<String, dynamic> item) {
    final value = item['vendor'];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  Future<void> _cancel(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('orders_cancel_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('orders_no'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('orders_yes_cancel'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final message = await Get.find<OrderRepository>().cancelOrder(
        orderId: _orderId(item),
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      showAppToast(
        message.isEmpty ? 'orders_cancelled_title'.tr : message,
        backgroundColor: const Color(0xFFFF5216),
      );
      _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  Future<void> _openDetails(Map<String, dynamic> item) async {
    final orderId = _orderId(item);
    final code = '${item['order_code'] ?? ''}';
    if (orderId < 1) {
      showAppToast('orders_details_unavailable'.tr);
      return;
    }
    // Food orders have their own detail call; every other type uses
    // orderDetails through the shared item-order screen.
    if (_orderType(item) != 1) {
      await Get.to(
        () => PharmacyItemOrderDetailScreen(
          orderId: code,
          apiOrderId: orderId,
          isDelivery: '${item['is_self_pickup']}' != '1',
          storeName: '${_vendor(item)['name'] ?? ''}',
        ),
      );
      _load();
      return;
    }
    try {
      final detail = await Get.find<OrderRepository>().catalogOrderDetail(
        orderId: orderId,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      await Get.to(
        () => OrderDetailScreen(
          orderId: '${detail['order_code'] ?? code}',
          detail: detail,
        ),
      );
      _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Column(
          children: [
            _buildHeader(context),
            _buildFilters(),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5216),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFFF5216),
                      onRefresh: _load,
                      child: list.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                return _buildScheduleCard(list[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 320,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error ?? 'schedules_empty'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'orders_my_schedules'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFF5216) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: selected
                    ? null
                    : Border.all(color: const Color(0xFFE8DFD6)),
              ),
              child: Text(
                _filters[index].$1.tr,
                style: GoogleFonts.outfit(
                  color: selected ? Colors.white : const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> item) {
    final type = _orderType(item);
    final vendor = _vendor(item);
    final image = ApiConstants.mediaUrl('${vendor['image'] ?? ''}');
    final icon = Icon(
      _typeIcons[type] ?? Icons.event_rounded,
      color: Colors.white,
      size: 22,
    );
    final status = int.tryParse('${item['status'] ?? ''}') ?? 0;
    final statusKey = 'core_status_$status';
    final statusLabel = statusKey.tr == statusKey
        ? 'orders_scheduled'.tr
        : statusKey.tr;
    final total = num.tryParse('${item['total'] ?? ''}');
    final code = '${item['order_code'] ?? ''}'.trim();
    final subtitle = [
      if (code.isNotEmpty) '#$code',
      if (total != null)
        '${total % 1 == 0 ? total.toInt() : total.toStringAsFixed(2)} '
            '${'orders_currency'.tr}',
    ].join(' · ');
    // Only an order the store hasn't started on can still be cancelled.
    final canCancel = status <= 1;
    final typeLabel = _typeLabels[type];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  color: const Color(0xFFFF5216),
                  child: image == null
                      ? icon
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => icon,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vendor['name'] ?? ''}'.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8A7E76),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1FAF5A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1FAF5A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (typeLabel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1ECFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    typeLabel.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6B4BD8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFFFF5216),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          formatScheduledFor('${item['scheduled_for'] ?? ''}'),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5216),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (canCancel) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => _cancel(item),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F1EC),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: () => _openDetails(item),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5216), Color(0xFFFFAE00)],
                        begin: AlignmentDirectional.centerStart,
                        end: AlignmentDirectional.centerEnd,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF5216,
                          ).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'orders_view_order'.tr,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
