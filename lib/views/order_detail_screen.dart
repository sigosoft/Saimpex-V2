import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/network/api_constants.dart';
import 'track_order_screen.dart';
import '../widgets/app_back_button.dart';
import '../widgets/cancel_order_bottom_sheet.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  /// Food order from customer/catalog/orderDetail.
  final Map<String, dynamic> detail;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final orderId = '${detail['order_code'] ?? this.orderId}';
    // Numeric id for the cancel API.
    final apiOrderId = int.tryParse('${detail['id'] ?? detail['order_id']}');
    final isSelfPickup =
        '${detail['is_self_pickup']}' == '1' ||
        detail['is_self_pickup'] == true;

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

            // 1. App Bar Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppBackButton(onTap: () => Navigator.pop(context)),
                  ),
                  Text(
                    'orders_order_code'.trParams({'code': orderId}),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'orders_help_opened'.tr,
                              style: GoogleFonts.outfit(),
                            ),
                            backgroundColor: const Color(0xFFFF5E00),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFFF5E00,
                            ).withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          'subs_help'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 2. Order Status Stepper Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'orders_order_status'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isSelfPickup
                                    ? 'orders_self_pickup'.tr
                                    : 'orders_delivery'.tr,
                                style: GoogleFonts.outfit(
                                  color: isSelfPickup
                                      ? const Color(0xFF007DFE)
                                      : const Color(0xFFFF5E00),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Custom Stepper Progress Row
                          Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              // Connector Lines
                              Positioned(
                                top: 18,
                                left: 30,
                                right: 30,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: const Color(0xFFFF5E00),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: const Color(0xFFFF5E00),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: const Color(0xFFEAD8C9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Nodes
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _stepperNodes(isSelfPickup),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 3. Delivery Details Header & Card
                    Text(
                      isSelfPickup
                          ? 'orders_pickup_location'.tr
                          : 'orders_delivery_details'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (isSelfPickup)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF0EA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFFFF5E00),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _apiText(
                                      'vendor_name',
                                      'Salam Supermarket',
                                    ),
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2C2520),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _apiText(
                                      'location',
                                      'Salam Supermarket, Near Nouakchott, Mauritania',
                                    ),
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF8C7D73),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Address Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF0EA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.home_outlined,
                                color: Color(0xFFFF5E00),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _apiText('location', ''),
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2C2520),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'orders_from_vendor'.trParams({
                                      'name': _apiText(
                                        'vendor_name',
                                        'orders_the_restaurant'.tr,
                                      ),
                                    }),
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF8C7D73),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // 4. Order Summary Section
                    Text(
                      'orders_order_summary'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(children: _apiSummaryRows()),
                    ),

                    const SizedBox(height: 18),

                    // 5. Payment Details Card (Dark Container)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2520),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'orders_payment_details'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildPaymentRow(
                            'orders_item_total'.tr,
                            _amount('sub_total', ''),
                          ),
                          if (!isSelfPickup) ...[
                            const SizedBox(height: 8),
                            _buildPaymentRow(
                              'cart_delivery_fee'.tr,
                              _amount('delivery_fee', ''),
                            ),
                          ],
                          const SizedBox(height: 8),
                          _buildPaymentRow('cart_tax'.tr, _amount('tax', '')),
                          const SizedBox(height: 14),
                          Container(height: 1, color: Colors.white12),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'orders_total_paid'.tr,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _amount('total', ''),
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
                    ),

                    const SizedBox(height: 20),

                    // 6. Action Buttons — Cancel only for self pickup; Cancel + Track for delivery
                    if (isSelfPickup)
                      GestureDetector(
                        onTap: () {
                          showCancelOrderBottomSheet(
                            context,
                            orderId: orderId,
                            apiOrderId: apiOrderId,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6ECE5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'cancel'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showCancelOrderBottomSheet(
                                  context,
                                  orderId: orderId,
                                  apiOrderId: apiOrderId,
                                );
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6ECE5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'cancel'.tr,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Get.to(
                                  () => TrackOrderScreen(
                                    orderId: orderId,
                                    apiOrderId: apiOrderId,
                                  ),
                                );
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5E00),
                                      Color(0xFFFFAE00),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF5E00,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'orders_track_order_btn'.tr,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _apiText(String key, String fallback) {
    final value = detail[key]?.toString().trim() ?? '';
    return value.isEmpty || value == 'null' ? fallback : value;
  }

  String _amount(String key, String fallback) =>
      detail.containsKey(key) ? _money(detail[key]) : fallback;

  static String _money(dynamic value) {
    final number = double.tryParse('${value ?? ''}') ?? 0;
    return 'mru'.trParams({'amount': '${number.round()}'});
  }

  /// 0 placed, 1 preparing, 2 on the way (or ready for pickup), 3 delivered.
  int get _stage {
    final label = _apiText('status_label', '').toLowerCase();
    if (label.contains('deliver') || label.contains('complete')) return 3;
    if (label.contains('way') || label.contains('ready')) return 2;
    if (label.contains('prepar') || label.contains('accept')) return 1;
    return 0;
  }

  List<Widget> _stepperNodes(bool pickup) {
    final stage = _stage;
    final placedAt = _apiText('placed_at', '');
    final titles = [
      'orders_step_placed'.tr,
      'orders_step_preparing'.tr,
      pickup ? 'orders_step_ready'.tr : 'orders_step_on_the_way'.tr,
      'orders_step_delivered'.tr,
    ];
    final assets = [
      null,
      'lib/assets/images/preparingfood.png',
      pickup
          ? 'lib/assets/images/readyforpickup.png'
          : 'lib/assets/images/ontheway.png',
      null,
    ];
    return [
      for (var i = 0; i < titles.length; i++)
        _buildStepperNode(
          isActive: i <= stage,
          icon: Icons.check,
          iconAsset: assets[i],
          title: titles[i],
          time: i == 0 ? placedAt : '',
        ),
    ];
  }

  /// One row per food item: name, portion and chosen options, quantity and line total.
  List<Widget> _apiSummaryRows() {
    final items = detail['items'] is List
        ? (detail['items'] as List).whereType<Map>().toList()
        : const <Map>[];
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final options = (item['options'] as List? ?? const []).whereType<Map>();
      final extras = (item['extras'] as List? ?? const []).whereType<Map>();
      final variant = '${item['variant_name'] ?? ''}';
      final parts = [
        if (variant.isNotEmpty && variant != 'null') variant,
        for (final option in options) '${option['option_name']}',
        for (final extra in extras) '${extra['name_en']}',
      ];
      if (i > 0) {
        rows.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFF3E7DC), height: 1),
          ),
        );
      }
      rows.add(
        _buildSummaryItem(
          title: '${item['name_en'] ?? ''}',
          weight: parts.join(' • '),
          quantity: 'x${item['quantity'] ?? 1}',
          price: _money(item['total_price']),
          imageUrl: ApiConstants.mediaUrl(item['image']?.toString()),
        ),
      );
    }
    return rows;
  }

  // Stepper Node Helper
  Widget _buildStepperNode({
    required bool isActive,
    required IconData icon,
    required String title,
    required String time,
    String? iconAsset,
    bool showGlow = false,
  }) {
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFFF5E00)
                  : const Color(0xFFEAD8C9),
              shape: BoxShape.circle,
              boxShadow: showGlow
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: iconAsset != null
                ? Image.asset(
                    iconAsset,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    icon,
                    color: isActive ? Colors.white : const Color(0xFFC4B8B0),
                    size: 18,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: isActive
                  ? const Color(0xFF2C2520)
                  : const Color(0xFF8C7D73),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                time,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8C7D73),
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Order Summary Item Row Helper
  Widget _buildSummaryItem({
    required String title,
    required String weight,
    required String quantity,
    required String price,
    String? assetPath,
    String? imageUrl,
  }) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 58,
            height: 58,
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF3E7DC),
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: Color(0xFFFF5E00),
                        size: 24,
                      ),
                    ),
                  )
                : Image.asset(
                    assetPath ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF3E7DC),
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: Color(0xFFFF5E00),
                        size: 24,
                      ),
                    ),
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
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                weight,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8C7D73),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                quantity,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Payment Details Row Helper
  Widget _buildPaymentRow(String label, String value, {bool isOrange = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFFA59A94),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isOrange ? const Color(0xFFFF5E00) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
