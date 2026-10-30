import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'water_track_order_screen.dart';
import '../help_support_screen.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/api_exception.dart';
import '../../models/order_tracking.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/cancel_order_bottom_sheet.dart';
import '../../widgets/app_back_button.dart';

/// A water order's status, store or delivery address, driver, items and
/// payment, from customer/orderDetails.
class WaterOrderDetailsScreen extends StatefulWidget {
  /// Order code shown to the customer, used until the details load.
  final String orderId;

  /// Numeric order id for customer/orderDetails.
  final int? apiOrderId;

  /// Layout to show until the details say otherwise.
  final bool isSelfPickup;

  const WaterOrderDetailsScreen({
    super.key,
    this.orderId = '',
    this.apiOrderId,
    this.isSelfPickup = false,
  });

  @override
  State<WaterOrderDetailsScreen> createState() =>
      _WaterOrderDetailsScreenState();
}

class _WaterOrderDetailsScreenState extends State<WaterOrderDetailsScreen> {
  OrderTracking? _detail;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await loadOrderDetail(widget.apiOrderId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _error = detail == null ? 'Order details are not available' : null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get isSelfPickup => _detail?.isSelfPickup ?? widget.isSelfPickup;

  String get _displayId {
    final code = _detail?.orderCode.isNotEmpty == true
        ? _detail!.orderCode
        : widget.orderId.trim();
    if (code.isEmpty) return '';
    return code.startsWith('#') ? code : '#$code';
  }

  // Cancel is only accepted before a driver is assigned (status 1–2).
  bool get _canCancel {
    final detail = _detail;
    return detail != null && detail.status <= 2 && !detail.hasDriver;
  }

  bool get _canTrack {
    final detail = _detail;
    return detail != null && !isSelfPickup && !detail.isFinished;
  }

  static String _money(dynamic value, {bool negative = false}) {
    final number = double.tryParse('${value ?? ''}');
    if (number == null) return '— MRU';
    final text = '${number.round()} MRU';
    return negative && number > 0 ? '-$text' : text;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // 1. Header Bar (Back button, Order ID Title, Help button)
              _buildHeader(context),
              const SizedBox(height: 12),

              // Scrollable Order Details Content
              Expanded(
                child: _detail == null
                    ? _buildPlaceholder()
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2. Order Status Timeline Card
                            _buildOrderStatusCard(),
                            const SizedBox(height: 18),

                            // 3. Location / Driver Section
                            _buildLocationDriverSection(),
                            const SizedBox(height: 18),

                            // 4. Order Summary Section
                            _buildOrderSummarySection(),
                            const SizedBox(height: 18),

                            // 5. Dark Receipt Container (PAYMENT DETAILS)
                            _buildDarkReceiptBox(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),

              // 6. Bottom Action Buttons Row
              if (_canCancel || _canTrack)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: _buildActionButtons(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: _loading
          ? const CircularProgressIndicator(color: Color(0xFFFF5E00))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error ?? 'Order details are not available',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  // Header Bar Widget
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppBackButton(onTap: () => Get.back()),
          Text(
            _displayId.isEmpty ? 'Order' : 'Order $_displayId',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              Get.to(() => const HelpSupportScreen());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 1.0),
              ),
              child: Text(
                'Help',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Order Status Timeline Card
  Widget _buildOrderStatusCard() {
    final detail = _detail!;
    final status = detail.status;
    final cancelled = detail.isCancelled;
    String time(int code) => detail.timeOf(code);
    final steps = [
      (
        icon: Icons.check_rounded,
        title: 'Order placed',
        subtitle: detail.placedAt,
        isActive: status >= 1,
      ),
      (
        icon: Icons.shopping_bag_outlined,
        title: 'Picking items',
        subtitle: time(3).isNotEmpty ? time(3) : time(2),
        isActive: !cancelled && status >= 2,
      ),
      isSelfPickup
          ? (
              icon: Icons.storefront_outlined,
              title: 'Ready for pickup',
              subtitle: time(4),
              isActive: !cancelled && status >= 4,
            )
          : (
              icon: Icons.delivery_dining_rounded,
              title: 'On the way',
              subtitle: time(7).isNotEmpty ? time(7) : time(8),
              isActive: !cancelled && status >= 7,
            ),
      cancelled
          ? (
              icon: Icons.close_rounded,
              title: 'Cancelled',
              subtitle: time(10),
              isActive: true,
            )
          : (
              icon: Icons.check_rounded,
              title: isSelfPickup ? 'Picked up' : 'Delivered',
              subtitle: time(9),
              isActive: status >= 9,
            ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Order Status',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                isSelfPickup ? 'Self Pickup' : 'Delivery',
                style: GoogleFonts.outfit(
                  color: isSelfPickup
                      ? const Color(0xFF007DFE)
                      : const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const circle = 36.0;
              final usable = constraints.maxWidth - circle;
              final segment = usable / (steps.length - 1);

              return Column(
                children: [
                  SizedBox(
                    height: circle,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Line through exact vertical center of circles
                        Positioned(
                          left: circle / 2,
                          right: circle / 2,
                          top: (circle - 3) / 2,
                          child: Row(
                            children: List.generate(steps.length - 1, (i) {
                              final segmentActive =
                                  steps[i].isActive && steps[i + 1].isActive;
                              return Container(
                                width: segment,
                                height: 3,
                                color: segmentActive
                                    ? const Color(0xFFFF5E00)
                                    : const Color(0xFFE8E0D8),
                              );
                            }),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final step in steps)
                              Container(
                                width: circle,
                                height: circle,
                                decoration: BoxDecoration(
                                  color: step.isActive
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFFEFEBE7),
                                  shape: BoxShape.circle,
                                  boxShadow: step.isActive
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFF5E00,
                                            ).withValues(alpha: 0.40),
                                            blurRadius: 12,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  step.icon,
                                  color: step.isActive
                                      ? Colors.white
                                      : const Color(0xFFB0A59C),
                                  size: 18,
                                ),
                              ),
                          ],
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
                              step.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1A1A1A),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                            if (step.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                step.subtitle,
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
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF5E00), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C7E75),
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Location / Driver Section
  Widget _buildLocationDriverSection() {
    final detail = _detail!;
    if (isSelfPickup) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Location',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _infoCard(
            icon: Icons.storefront_outlined,
            title: detail.vendorName.isEmpty ? 'Store' : detail.vendorName,
            subtitle: detail.vendorAddress,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Details',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // Location Card
        _infoCard(
          icon: Icons.home_outlined,
          title: 'Delivery address',
          subtitle: detail.deliveryAddress.isEmpty
              ? '—'
              : detail.deliveryAddress,
        ),
        const SizedBox(height: 10),

        // Driver Contact Card
        _buildDriverCard(detail),
      ],
    );
  }

  Widget _buildDriverCard(OrderTracking detail) {
    final avatar = const CircleAvatar(
      radius: 20,
      backgroundColor: Color(0xFFFFF0E6),
      child: Icon(Icons.person_rounded, color: Color(0xFFFF5E00), size: 24),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: !detail.hasDriver
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                detail.isFinished
                    ? 'No driver for this order'
                    : 'A driver will be assigned soon',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8C7E75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Row(
              children: [
                detail.driverImage.isEmpty
                    ? avatar
                    : ClipOval(
                        child: Image.network(
                          detail.driverImage,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => avatar,
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.driverName.isEmpty
                            ? 'Driver'
                            : detail.driverName,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            [
                              detail.driverRating > 0
                                  ? detail.driverRating.toStringAsFixed(1)
                                  : 'New',
                              if (detail.driverReviews > 0)
                                '(${detail.driverReviews} reviews)',
                            ].join(' '),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8C7E75),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Phone Call Icon Button
                GestureDetector(
                  // The scope calls for a masked number, which needs a
                  // calling provider the backend doesn't have yet.
                  onTap: () => showAppToast(
                    'Calling your driver from the app is coming soon',
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5E00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Order Summary Section
  Widget _buildOrderSummarySection() {
    final items = _detail!.items;
    final language = apiLanguageCode();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: items.isEmpty
              ? Text(
                  'No items',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8C7E75),
                    fontSize: 12,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Color(0xFFF3EFEA), height: 1),
                        ),
                      _buildOrderItemRow(items[i], language),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildOrderItemRow(Map<String, dynamic> item, String language) {
    final localized = '${item['name_$language'] ?? ''}'.trim();
    final title = localized.isNotEmpty
        ? localized
        : '${item['name_en'] ?? 'Item'}'.trim();
    final images = item['images'];
    final imagePath = images is List && images.isNotEmpty
        ? '${images.first}'
        : '${item['image'] ?? ''}';
    final imageUrl = ApiConstants.mediaUrl(imagePath) ?? '';
    const fallback = Icon(Icons.water_drop, color: Color(0xFF007BFF), size: 24);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 55,
            height: 55,
            color: const Color(0xFFEBF4FE),
            padding: const EdgeInsets.all(6),
            child: imageUrl.isEmpty
                ? fallback
                : Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => fallback,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'x${item['quantity'] ?? 1}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          _money(item['total_price']),
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Dark Receipt Container (PAYMENT DETAILS)
  Widget _buildDarkReceiptBox() {
    final detail = _detail!;
    final payment = detail.payment;
    final redeemed = double.tryParse('${payment['redeemed_points'] ?? ''}');
    final tax = double.tryParse('${payment['tax'] ?? ''}') ?? 0;
    final discount = double.tryParse('${payment['discount'] ?? ''}') ?? 0;
    final isCash = '${payment['payment_type'] ?? ''}'.toLowerCase() == 'cash';
    final totalLabel = isCash && !detail.isDelivered ? 'To pay' : 'Total paid';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _buildReceiptRow('Item total', _money(payment['item_total'])),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _buildReceiptRow(
              'Discount',
              _money(discount, negative: true),
              isOrange: true,
            ),
          ],
          if (redeemed != null && redeemed > 0) ...[
            const SizedBox(height: 8),
            _buildReceiptRow(
              'Redeemed points',
              '-${redeemed.round()} pts',
              isOrange: true,
            ),
          ],
          if (!isSelfPickup) ...[
            const SizedBox(height: 8),
            _buildReceiptRow('Delivery fee', _money(payment['delivery_fee'])),
          ],
          if (tax > 0) ...[
            const SizedBox(height: 8),
            _buildReceiptRow('Tax', _money(tax)),
          ],
          const SizedBox(height: 8),
          _buildReceiptRow('Payment', isCash ? 'Cash' : 'Online'),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalLabel,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _money(payment['total_bill']),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isOrange = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFFD4CDC5),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isOrange ? const Color(0xFFFF5E00) : Colors.white,
            fontSize: 12,
            fontWeight: isOrange ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Cancel (before a driver is assigned) and Track Order (delivery only)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (_canCancel)
          Expanded(
            child: GestureDetector(
              onTap: () {
                showCancelOrderBottomSheet(
                  context,
                  orderId: _displayId,
                  apiOrderId: widget.apiOrderId,
                  onCancelled: _load,
                );
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EFE6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_canCancel && _canTrack) const SizedBox(width: 12),
        if (_canTrack)
          Expanded(
            child: GestureDetector(
              onTap: () {
                Get.to(
                  () => WaterTrackOrderScreen(
                    orderId: _displayId,
                    apiOrderId: widget.apiOrderId,
                  ),
                );
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Track Order',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
