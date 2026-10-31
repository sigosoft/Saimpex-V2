import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_success_screen.dart';
import 'payment_webview_screen.dart';
import '../controllers/home_controller.dart';
import '../controllers/select_location_controller.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../models/cart_repository.dart';
import '../models/order_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../constants/text_styles.dart';
import '../widgets/app_back_button.dart';
import '../widgets/home_background_blend.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../navigation/bottom_nav_router.dart';
import 'pharmacy/widgets/attach_prescription_sheet.dart';
import '../utils/payment_methods.dart';
import '../utils/wallet_balance.dart';
import '../widgets/no_payment_method_note.dart';
import 'widgets/coupons_sheet.dart';
import 'pay_later_screen.dart';

class CartScreen extends StatefulWidget {
  final String? storeName;
  final String? itemName;
  final String? itemPortion;
  final int? basePrice;
  final String? itemImage;
  final bool showBottomNav;
  final bool isFoodOrGrocery;

  const CartScreen({
    super.key,
    this.storeName,
    this.itemName,
    this.itemPortion,
    this.basePrice,
    this.itemImage,
    this.showBottomNav = false,
    this.isFoodOrGrocery = false,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isDelivery = true; // default to Delivery as in reference image 2
  int quantity = 0;
  // Off until the customer chooses to redeem store points.
  bool usePoints = false;
  bool _cartLoading = true;
  bool _placingOrder = false;
  // Order already placed but not yet paid online. Retrying reopens payment for
  // it instead of checking out again, which would create a duplicate order.
  Map<String, dynamic>? _unpaidOrder;
  bool _cartLoaded = false;
  // Restaurant carts use their own line totals, not the general checkout summary
  bool _isCatalogCart = false;
  String _apiVendorName = '';
  List<Map<String, dynamic>> _apiItems = const [];
  int? _vendorId;
  int? _cartId;
  int? _summaryItemTotal;
  int? _summaryDelivery;
  int? _summaryTax;
  int? _summaryToPay;
  // Store points from the checkout summary.
  bool _rewardEnabled = false;
  int _pointsAvailable = 0;
  int _pointsAmount = 0;
  int _pointsDiscount = 0;
  // From the checkout summary: the cart needs a prescription before it can be paid
  bool _needsPrescription = false;
  bool _hasPrescription = false;
  int? _prescriptionId;
  String _appliedCoupon = '';
  final TextEditingController _couponController = TextEditingController();
  Worker? _cartTabWorker;
  // 0 Wallet, 1 Online, 2 Cash on Delivery, 3 Pay After Delivery.
  late int selectedPaymentIndex;
  bool _noPaymentMethod = false;
  static const _indexTypes = [
    paymentTypeWallet,
    paymentTypeOnline,
    paymentTypeCash,
    paymentTypePayAfterDelivery,
  ];

  /// Keeps the choice on a method this checkout offers and Admin has
  /// switched on. Pay After Delivery stays only if it was picked; it is never
  /// the fallback.
  void _applyPaymentMethods() {
    final offered = [
      paymentTypeWallet,
      paymentTypeOnline,
      if (isDelivery) paymentTypeCash,
      if (isDelivery && _padCanUse) paymentTypePayAfterDelivery,
    ];
    final current = _indexTypes[selectedPaymentIndex];
    String? type;
    if (offered.contains(current) && PaymentMethods.isOn(current)) {
      type = current;
    } else {
      for (final option in offered) {
        if (option != paymentTypePayAfterDelivery &&
            PaymentMethods.isOn(option)) {
          type = option;
          break;
        }
      }
    }
    _noPaymentMethod = type == null;
    if (type != null) selectedPaymentIndex = _indexTypes.indexOf(type);
  }

  String scheduleText = "Pick a delivery time";
  // Pre-order delivery time (sent as scheduled_for); null delivers now.
  DateTime? _scheduledFor;
  // customer/payAfterDelivery: whether PAD can be offered, and why not.
  Map<String, dynamic>? _padStatus;

  bool get _padCanUse => _padStatus?['can_use'] == true;
  String? get _padBlockedReason => _padStatus?['blocked_reason']?.toString();

  String get _padSubtitle {
    if (_padCanUse) return 'pad_option_hint'.tr;
    return switch (_padBlockedReason) {
      'unpaid_order' => 'pad_blocked_unpaid'.tr,
      'trust_removed' => 'pad_blocked_removed'.tr,
      _ => 'pad_blocked_not_trusted'.trParams({
        'done': '${_padStatus?['paid_orders'] ?? 0}',
        'needed': '${_padStatus?['paid_orders_needed'] ?? ''}',
      }),
    };
  }

  /// The wallet balance loaded with Home, or null before it has loaded.
  num? get _walletBalance {
    if (!Get.isRegistered<HomeController>()) return null;
    final raw = Get.find<HomeController>().walletBalance.value;
    return num.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  /// True when Wallet is chosen but can't cover [payable]: the wallet pays
  /// what it has and Masrvi charges the rest (split payment).
  bool _walletShort(int payable) {
    final balance = _walletBalance;
    return balance != null && balance < payable;
  }

  String _walletSubtitle(int payable) {
    final balance = _walletBalance;
    if (balance == null || !_walletShort(payable)) {
      return walletBalanceSubtitle();
    }
    String money(num value) =>
        value == value.roundToDouble() ? '${value.toInt()}' : '$value';
    return 'wallet_split'.trParams({
      'wallet': money(balance),
      'online': money(payable - balance),
    });
  }

  Future<void> _loadPayAfterDelivery() async {
    if (!Get.isRegistered<OrderRepository>()) return;
    try {
      final status = await Get.find<OrderRepository>().payAfterDeliveryStatus(
        apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        _padStatus = status;
        _applyPaymentMethods();
      });
    } on ApiException {
      // Guests and failed loads just don't see the option.
    }
  }

  @override
  void initState() {
    super.initState();
    // Wallet by default; Pay After Delivery is never the default.
    selectedPaymentIndex = 0;
    _loadPayAfterDelivery();
    _applyPaymentMethods();
    PaymentMethods.refresh().then((changed) {
      if (changed && mounted) setState(_applyPaymentMethods);
    });
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;
    final savedItem = controller?.lastCartItem;

    final hasDirectParams = widget.itemName != null || widget.storeName != null;
    final hasSavedItem =
        savedItem != null &&
        (savedItem['itemName'] != null || savedItem['storeName'] != null);

    if (hasDirectParams) {
      final saved = controller?.cartItemCount.value ?? 0;
      quantity = saved > 0 ? saved : 1;
    } else if (hasSavedItem) {
      quantity = (controller?.cartItemCount.value ?? 0) > 0
          ? (controller?.cartItemCount.value ?? 1)
          : 1;
    } else {
      quantity = 0;
    }

    _syncHomeCartBadgeCount(quantity);
    _loadCart();
    if (Get.isRegistered<HomeController>()) {
      _cartTabWorker = ever<int>(Get.find<HomeController>().currentNavIndex, (
        index,
      ) {
        if (index == HomeController.navCart) _loadCart();
      });
    }
  }

  Future<void> _loadCart() async {
    if (!Get.isRegistered<CartRepository>()) {
      if (mounted) setState(() => _cartLoading = false);
      return;
    }
    try {
      final cart = await Get.find<CartRepository>().fetchListOrEmpty(
        apiLanguageCode(),
      );
      var shown = cart;
      try {
        final all = await Get.find<CartRepository>().fetchListAll(
          apiLanguageCode(),
        );
        if (all.items.isNotEmpty) shown = all;
      } on ApiException {
        shown = cart;
      }
      // A restaurant cart comes from the catalog endpoint; other carts return nothing here
      var catalogCart = false;
      try {
        final catalog = await Get.find<CartRepository>().fetchCatalogList(
          apiLanguageCode(),
        );
        if (catalog.items.isNotEmpty) {
          shown = catalog;
          catalogCart = true;
        }
      } on ApiException {
        // keep the cart shown above
      }
      if (!mounted) return;
      final items = _withRememberedCaps(shown.items);
      final count = items.fold<int>(
        0,
        (sum, item) => sum + ((item['quantity'] as int?) ?? 0),
      );
      setState(() {
        _cartLoaded = true;
        _isCatalogCart = catalogCart;
        _apiVendorName = shown.vendorName;
        _apiItems = items;
        _vendorId = shown.vendorId ?? cart.vendorId;
        _cartId = shown.cartId ?? cart.cartId;
        quantity = count;
      });
      _syncQuantityFields();
      _syncHomeCartBadgeCount(count);
      if (count > 0) {
        await _loadCheckoutSummary();
        await _checkDelivery();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _cartLoading = false);
    }
  }

  /// Restaurant (catalog) cart totals with the applied coupon. A coupon the
  /// server now refuses (422) is dropped and the totals load without it.
  Future<void> _loadCatalogSummary() async {
    final orders = Get.find<OrderRepository>();
    final location = SelectLocationController.selectedSubtitle.trim().isEmpty
        ? SelectLocationController.deliveryLabel.value
        : SelectLocationController.selectedSubtitle;
    Future<Map<String, dynamic>> load(String coupon) =>
        orders.catalogCheckoutSummary(
          selfPickup: !isDelivery,
          latitude: SelectLocationController.selectedLatitude,
          longitude: SelectLocationController.selectedLongitude,
          location: location,
          language: apiLanguageCode(),
          couponCode: coupon,
        );
    try {
      _applySummary(await load(_appliedCoupon));
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      if (error.statusCode == 422 && _appliedCoupon.isNotEmpty) {
        setState(() {
          _appliedCoupon = '';
          _couponController.clear();
        });
        try {
          _applySummary(await load(''));
        } on ApiException {
          _applySummary(const {});
        }
      } else {
        _applySummary(const {});
      }
    }
  }

  Future<void> _loadCheckoutSummary() async {
    if (!Get.isRegistered<OrderRepository>() || !mounted) return;
    // Restaurant carts have their own summary (catalog/checkoutSummary).
    if (_isCatalogCart) {
      await _loadCatalogSummary();
      return;
    }
    final orders = Get.find<OrderRepository>();
    final location = SelectLocationController.selectedSubtitle.trim().isEmpty
        ? SelectLocationController.deliveryLabel.value
        : SelectLocationController.selectedSubtitle;
    Future<Map<String, dynamic>> load(bool version2) {
      return orders.checkoutSummary(
        selfPickup: !isDelivery,
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        location: location,
        usePoints: usePoints,
        language: apiLanguageCode(),
        couponCode: _appliedCoupon,
        version2: version2,
      );
    }

    try {
      _applySummary(await load(true));
    } on ApiException {
      try {
        _applySummary(await load(false));
      } on ApiException catch (error) {
        if (!mounted) return;
        showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      }
    }
  }

  void _applySummary(Map<String, dynamic> data) {
    int? money(dynamic value) {
      if (value == null) return null;
      final number = value is num
          ? value.toDouble()
          : double.tryParse('$value');
      if (number == null) return null;
      return number.round();
    }

    bool flag(dynamic value) => value == true || value == 1 || value == '1';

    if (!mounted) return;
    setState(() {
      if (_isCatalogCart) {
        // catalog/checkoutSummary; grand_total is after the coupon.
        _summaryItemTotal = money(data['sub_total']);
        _summaryDelivery = money(data['delivery_charge']);
        _summaryTax = money(data['tax']);
        _summaryToPay = money(data['grand_total']);
        _needsPrescription = false;
        _hasPrescription = false;
        _prescriptionId = null;
        // The food cart summary has no store points.
        _rewardEnabled = false;
        _pointsAvailable = 0;
        _pointsAmount = 0;
        _pointsDiscount = 0;
        return;
      }
      _summaryItemTotal = money(data['item_total'] ?? data['sub_total']);
      _summaryDelivery = money(data['delivery_fee']);
      _summaryTax = money(data['tax']);
      _summaryToPay = money(data['to_pay'] ?? data['payable']);
      // Store points: what the customer has here and what they're worth.
      _rewardEnabled = flag(data['is_reward_enabled']);
      _pointsAvailable = money(data['redeem_points_available']) ?? 0;
      _pointsAmount = money(data['redeem_points_amount']) ?? 0;
      _pointsDiscount = money(data['points_discount']) ?? 0;
      if (!_rewardEnabled || _pointsAvailable <= 0) usePoints = false;
      _needsPrescription = flag(data['needs_prescription']);
      _hasPrescription = flag(data['has_prescription']);
      _prescriptionId = _positiveId(data['prescription_id']);
    });
  }

  Future<void> _attachPrescription() async {
    final vendorId = _vendorId;
    if (vendorId == null) {
      showAppToast(
        'orders_rx_pharmacy_missing'.tr,
        backgroundColor: const Color(0xFFEF4444),
      );
      return;
    }
    final attached = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachPrescriptionSheet(pharmacyId: vendorId),
    );
    if (attached == true && mounted) await _loadCheckoutSummary();
  }

  Widget _buildPrescriptionSection() {
    final attached = _hasPrescription;
    final accent = attached ? const Color(0xFF00A854) : const Color(0xFFFF5E00);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: attached ? const Color(0xFFBFE8CF) : const Color(0xFFEAD8C9),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              attached
                  ? Icons.check_circle_outline_rounded
                  : Icons.description_outlined,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attached ? 'orders_rx_attached'.tr : 'orders_rx_required'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attached
                      ? (_prescriptionId == null
                            ? 'orders_rx_review'.tr
                            : 'orders_rx_number'.trParams({
                                'id': '$_prescriptionId',
                              }))
                      : 'orders_rx_upload_hint'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!attached)
            GestureDetector(
              onTap: _attachPrescription,
              child: Text(
                'orders_upload'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkDelivery() async {
    final vendorId = _vendorId;
    if (!isDelivery ||
        vendorId == null ||
        !Get.isRegistered<OrderRepository>()) {
      return;
    }
    try {
      await Get.find<OrderRepository>().checkDelivery(
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        vendorId: vendorId,
        language: apiLanguageCode(),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  Future<void> _applyCoupon(int orderAmount) async {
    final code = _couponController.text.trim();
    if (code.isEmpty || !Get.isRegistered<OrderRepository>()) return;
    if (_isCatalogCart) {
      // Restaurant carts check the coupon through their own summary; an
      // invalid code comes back as a 422 with the reason.
      final previous = _appliedCoupon;
      setState(() => _appliedCoupon = code);
      await _loadCatalogSummary();
      if (mounted && _appliedCoupon == code && code != previous) {
        showAppToast(
          'coupon_applied'.tr,
          backgroundColor: const Color(0xFFFF5E00),
        );
      }
      return;
    }
    try {
      final message = await Get.find<OrderRepository>().applyCoupon(
        couponCode: code,
        orderAmount: orderAmount,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      _appliedCoupon = code;
      showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      await _loadCheckoutSummary();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  Future<void> _placeOrder(int payable) async {
    if (_placingOrder || !Get.isRegistered<OrderRepository>()) return;
    if (_noPaymentMethod) {
      showAppToast(
        'payment_no_method'.tr,
        backgroundColor: const Color(0xFFEF4444),
      );
      return;
    }
    if (_needsPrescription && !_hasPrescription) {
      showAppToast(
        'orders_rx_before_order'.tr,
        backgroundColor: const Color(0xFFEF4444),
      );
      return;
    }
    _placingOrder = true;
    final unpaid = _unpaidOrder;
    if (unpaid != null) {
      try {
        await _finishPlacedOrder(unpaid, payable);
      } finally {
        _placingOrder = false;
      }
      return;
    }
    final orders = Get.find<OrderRepository>();
    final location = SelectLocationController.selectedSubtitle.trim().isEmpty
        ? SelectLocationController.deliveryLabel.value
        : SelectLocationController.selectedSubtitle;
    final note = _deliveryNoteController.text.trim();
    // Wallet (0) is paid from the wallet when the order is placed; Online (1)
    // opens the payment page; Cash on Delivery (2) is 1; Pay After Delivery
    // (3) is 4, which the server refuses when the customer can't use it.
    // A wallet that can't cover the order splits it: payment_type 2 with
    // use_wallet=1, so the wallet pays what it has and Masrvi the rest.
    final splitWithWallet = selectedPaymentIndex == 0 && _walletShort(payable);
    final paymentType = splitWithWallet
        ? paymentTypeOnline
        : switch (selectedPaymentIndex) {
            0 => paymentTypeWallet,
            1 => paymentTypeOnline,
            3 => paymentTypePayAfterDelivery,
            _ => paymentTypeCash,
          };
    Future<Map<String, dynamic>> place(bool version2) {
      if (_isCatalogCart) {
        return orders.catalogCheckout(
          selfPickup: !isDelivery,
          latitude: SelectLocationController.selectedLatitude,
          longitude: SelectLocationController.selectedLongitude,
          location: location,
          paymentType: paymentType,
          language: apiLanguageCode(),
          note: note,
          useWallet: splitWithWallet,
          scheduledFor: _scheduledFor,
          couponCode: _appliedCoupon,
        );
      }
      return orders.checkout(
        selfPickup: !isDelivery,
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        location: location,
        paymentType: paymentType,
        language: apiLanguageCode(),
        cartId: _cartId,
        couponCode: _appliedCoupon,
        redeemAmount: usePoints && _pointsAmount > 0 ? '$_pointsAmount' : '0',
        note: note,
        version2: version2,
        useWallet: splitWithWallet,
        scheduledFor: _scheduledFor,
      );
    }

    try {
      final placed = await place(true);
      if (!mounted) return;
      await _finishPlacedOrder(placed, payable);
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) {
        try {
          final placed = await place(false);
          if (!mounted) return;
          await _finishPlacedOrder(placed, payable);
          return;
        } on ApiException catch (fallback) {
          if (!mounted) return;
          showAppToast(
            fallback.message,
            backgroundColor: const Color(0xFFEF4444),
          );
          return;
        }
      }
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      // Refused Pay After Delivery: refresh why, which may hide the option.
      if (selectedPaymentIndex == 3) _loadPayAfterDelivery();
      if (error.statusCode == 422) await _recheckCartAfterRefusal(payable);
    } finally {
      _placingOrder = false;
    }
  }

  /// Checkout refused the order (422): the coupon may be used up, or a
  /// product may have been hidden by the store. The server's message is
  /// already shown; drop a coupon that no longer applies and reload the cart
  /// and totals so what's on screen is what can actually be ordered.
  Future<void> _recheckCartAfterRefusal(int payable) async {
    final coupon = _appliedCoupon;
    // Restaurant carts re-check the coupon in their summary on reload.
    if (coupon.isNotEmpty &&
        !_isCatalogCart &&
        Get.isRegistered<OrderRepository>()) {
      try {
        await Get.find<OrderRepository>().applyCoupon(
          couponCode: coupon,
          orderAmount: payable,
          language: apiLanguageCode(),
        );
      } on ApiException catch (error) {
        // 4xx: the coupon itself is refused now. Network errors keep it.
        final status = error.statusCode ?? 0;
        if (mounted && status >= 400 && status < 500) {
          setState(() {
            _appliedCoupon = '';
            _couponController.clear();
          });
          showAppToast(
            'coupon_removed'.trParams({'code': coupon}),
            backgroundColor: const Color(0xFFEF4444),
          );
        }
      }
    }
    if (!mounted) return;
    await _loadCart();
  }

  Future<void> _finishPlacedOrder(
    Map<String, dynamic> placed,
    int payable,
  ) async {
    final checkoutMessage = '${placed['message'] ?? ''}'.trim();
    if (checkoutMessage.isNotEmpty) {
      showAppToast(checkoutMessage, backgroundColor: const Color(0xFFFF5E00));
    }
    var paymentUrl = _paymentPageUrl(placed['payment_url']);
    if (selectedPaymentIndex == 1) {
      final startedUrl = await _startMasrviPayment(placed, payable);
      if (startedUrl != null) paymentUrl = startedUrl;
    }
    if (!mounted) return;
    final orderId = _positiveId(placed['order_id'] ?? placed['id']);
    final needsOnlinePayment =
        selectedPaymentIndex == 1 ||
        placed['payment_required'] == true ||
        placed['payment_required'] == 1 ||
        checkoutMessage.toLowerCase().contains('complete online payment');
    final url =
        paymentUrl ??
        (needsOnlinePayment && orderId != null
            ? _paymentPageUrl(
                '$_apiOrigin/pay/masrvi/payment/session?order_id=$orderId',
              )
            : null);
    if (needsOnlinePayment) {
      _unpaidOrder = placed;
      if (url == null) {
        showAppToast(
          'orders_payment_page_failed_retry'.tr,
          backgroundColor: const Color(0xFFEF4444),
        );
        return;
      }
      Get.closeAllSnackbars();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final paid = await Get.to<bool>(() => PaymentWebViewScreen(url: url));
      if (!mounted) return;
      if (paid != true) {
        showAppToast(
          paid == false
              ? 'orders_payment_failed_retry'.tr
              : 'orders_payment_not_completed_retry'.tr,
          backgroundColor: const Color(0xFFEF4444),
        );
        return;
      }
      _unpaidOrder = null;
    }
    _syncHomeCartBadgeCount(0);
    // Replaces this cart screen, so the placed items don't stay visible behind the success screen.
    final points = int.tryParse('${placed['reward_points_earned'] ?? ''}') ?? 0;
    Get.off(() => OrderSuccessScreen(pointsToEarn: points));
  }

  Future<String?> _startMasrviPayment(
    Map<String, dynamic> placed,
    int payable,
  ) async {
    if (!Get.isRegistered<OrderRepository>()) return null;
    final orders = Get.find<OrderRepository>();
    final language = apiLanguageCode();
    try {
      await orders.masrviSession(language);
    } on ApiException catch (error) {
      if (!mounted) return null;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      return null;
    }
    final orderId = _positiveId(placed['order_id'] ?? placed['id']);
    if (orderId == null) return null;
    final amount = _moneyArgument(
      placed['payable'] ?? placed['to_pay'] ?? payable,
    );
    try {
      final started = await orders.masrviInit(
        orderId: orderId,
        amount: amount,
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
        host: Uri.parse(ApiConstants.baseUrl).host,
        path: uri.path,
        query: uri.hasQuery ? uri.query : null,
      ).toString();
    }
    return uri.toString();
  }

  // Payment pages are served by the same backend as the API.
  String get _apiOrigin => Uri.parse(ApiConstants.baseUrl).origin;

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

  String get storeName {
    if (_cartLoaded) return _apiVendorName;
    if (widget.storeName != null) return widget.storeName!;
    if (Get.isRegistered<HomeController>()) {
      final saved = Get.find<HomeController>().lastCartItem;
      if (saved?['storeName'] != null) return saved!['storeName'].toString();
    }
    return "Pharmacy Nasr";
  }

  String get itemTitle {
    if (_cartLoaded) {
      if (_apiItems.isEmpty) return '';
      return '${_apiItems.first['name'] ?? ''}';
    }
    if (widget.itemName != null) return widget.itemName!;
    if (Get.isRegistered<HomeController>()) {
      final saved = Get.find<HomeController>().lastCartItem;
      if (saved?['itemName'] != null) return saved!['itemName'].toString();
    }
    return "Paracetamol 500 Mg";
  }

  String get itemPortion {
    if (widget.itemPortion != null) return widget.itemPortion!;
    if (Get.isRegistered<HomeController>()) {
      final saved = Get.find<HomeController>().lastCartItem;
      if (saved?['itemPortion'] != null) {
        return saved!['itemPortion'].toString();
      }
    }
    return "10 Tablets";
  }

  int get basePrice {
    if (_cartLoaded) {
      if (_apiItems.isEmpty) return 0;
      final price = _apiItems.first['unitPrice'];
      if (price is num) return price.round();
      return 0;
    }
    if (widget.basePrice != null) return widget.basePrice!;
    if (Get.isRegistered<HomeController>()) {
      final saved = Get.find<HomeController>().lastCartItem;
      final priceVal = saved?['basePrice'];
      if (priceVal is num) return priceVal.toInt();
      if (priceVal is String) {
        return int.tryParse(priceVal.replaceAll(RegExp(r'[^0-9]'), '')) ?? 50;
      }
    }
    return 50;
  }

  String get itemImage {
    String? raw;
    if (widget.itemImage != null) {
      raw = widget.itemImage;
    } else if (Get.isRegistered<HomeController>()) {
      final saved = Get.find<HomeController>().lastCartItem;
      if (saved?['itemImage'] != null) raw = saved!['itemImage'].toString();
    }
    return _resolveBakeryProductImage(itemTitle, raw);
  }

  /// Maps local-store bakery products to their asset images.
  static String _resolveBakeryProductImage(String title, String? image) {
    if (image != null &&
        image.isNotEmpty &&
        (image.startsWith('lib/assets/') || image.startsWith('http'))) {
      return image;
    }
    final t = title.toLowerCase();
    if (t.contains('artisan')) {
      return 'lib/assets/images/artisan_bread.png';
    }
    if (t.contains('pain') || t.contains('chocolat')) {
      return 'lib/assets/images/pain_chocolat.png';
    }
    if (t.contains('citrus') || t.contains('lemon')) {
      return 'lib/assets/images/citrus_lemon.png';
    }
    if (t.contains('croissant')) {
      return 'lib/assets/images/butter_croissant.png';
    }
    return image ?? '';
  }

  final TextEditingController _customQuantityController =
      TextEditingController();
  final Map<int, TextEditingController> _apiQuantityFields = {};
  final Map<int, int> _quantityRequests = {};
  final Map<int, int> _quantityCaps = {};
  Timer? _apiQuantityDebounce;
  bool _syncingQuantityField = false;
  bool _deliveryNoteOpen = false;
  final TextEditingController _deliveryNoteController = TextEditingController();
  final FocusNode _deliveryNoteFocus = FocusNode();

  @override
  void dispose() {
    _cartTabWorker?.dispose();
    _apiQuantityDebounce?.cancel();
    _customQuantityController.dispose();
    _deliveryNoteController.dispose();
    _deliveryNoteFocus.dispose();
    _couponController.dispose();
    for (final controller in _apiQuantityFields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onCustomQuantityChanged(String value) {
    if (_syncingQuantityField) return;

    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final parsed = int.tryParse(trimmed);
    if (parsed != null && parsed >= 0 && parsed != quantity) {
      setState(() => quantity = parsed);
      _syncHomeCartBadgeCount(parsed);
    }
  }

  void _setQuantity(int value) {
    final next = value < 0 ? 0 : value;
    setState(() => quantity = next);
    _syncHomeCartBadgeCount(next);

    _syncingQuantityField = true;
    _customQuantityController.value = TextEditingValue(
      text: next.toString(),
      selection: TextSelection.collapsed(offset: next.toString().length),
    );
    _syncingQuantityField = false;
  }

  TextEditingController _apiQuantityField(int cartItemId) {
    return _apiQuantityFields.putIfAbsent(
      cartItemId,
      TextEditingController.new,
    );
  }

  void _onApiQuantityTyped(int cartItemId, String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return;
    _apiQuantityDebounce?.cancel();
    _apiQuantityDebounce = Timer(const Duration(milliseconds: 450), () {
      _applyApiQuantity(cartItemId, parsed);
    });
  }

  Future<void> _applyApiQuantity(int cartItemId, int next) async {
    if (cartItemId < 1 || !mounted) return;
    final index = _apiItems.indexWhere(
      (item) => item['cartItemId'] == cartItemId,
    );
    if (index < 0) return;
    final current = (_apiItems[index]['quantity'] as int?) ?? 1;
    final maxQuantity = _apiItems[index]['maxQuantity'] is int
        ? _apiItems[index]['maxQuantity'] as int
        : null;
    var quantity = next < 0 ? 0 : next;
    if (maxQuantity != null && quantity > maxQuantity) {
      quantity = maxQuantity;
      final field = _apiQuantityFields[cartItemId];
      if (field != null) {
        final text = '$quantity';
        field.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }
    if (quantity == current) return;

    final updated = Map<String, dynamic>.from(_apiItems[index]);
    final unit = (updated['unitPrice'] as num?) ?? 0;
    updated['quantity'] = quantity;
    updated['lineTotal'] = unit * quantity;
    setState(() {
      final items = [..._apiItems];
      if (quantity == 0) {
        items.removeAt(index);
      } else {
        items[index] = updated;
      }
      _apiItems = items;
    });
    _syncHomeCartBadgeCount(
      _apiItems.fold<int>(
        0,
        (sum, item) => sum + ((item['quantity'] as int?) ?? 0),
      ),
    );

    final request = (_quantityRequests[cartItemId] ?? 0) + 1;
    _quantityRequests[cartItemId] = request;
    try {
      final repository = Get.find<CartRepository>();
      if (quantity == 0) {
        if (_isCatalogCart) {
          await repository.deleteCatalogItem(
            cartItemId: cartItemId,
            language: apiLanguageCode(),
          );
        } else {
          await repository.deleteItem(
            cartItemId: cartItemId,
            language: apiLanguageCode(),
          );
        }
      } else if (_isCatalogCart) {
        await repository.updateCatalogItem(
          cartItemId: cartItemId,
          quantity: quantity,
          language: apiLanguageCode(),
        );
      } else {
        await repository.updateItem(
          cartItemId: cartItemId,
          quantity: quantity,
          language: apiLanguageCode(),
        );
      }
      if (!mounted || _quantityRequests[cartItemId] != request) return;
      await _loadCart();
    } on ApiException catch (error) {
      if (!mounted || _quantityRequests[cartItemId] != request) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      final allowed = _quantityCapFromMessage(error.message);
      if (allowed != null) {
        _quantityCaps[cartItemId] = allowed;
        final target = current > allowed ? allowed : current;
        _setApiLineQuantity(cartItemId, target, allowed);
        if (current > allowed) {
          try {
            final repo = Get.find<CartRepository>();
            if (_isCatalogCart) {
              await repo.updateCatalogItem(
                cartItemId: cartItemId,
                quantity: allowed,
                language: apiLanguageCode(),
              );
            } else {
              await repo.updateItem(
                cartItemId: cartItemId,
                quantity: allowed,
                language: apiLanguageCode(),
              );
            }
          } on ApiException catch (retry) {
            if (!mounted) return;
            showAppToast(
              retry.message,
              backgroundColor: const Color(0xFFEF4444),
            );
          }
        }
      }
      if (!mounted || _quantityRequests[cartItemId] != request) return;
      await _loadCart();
    }
  }

  List<Map<String, dynamic>> _withRememberedCaps(
    List<Map<String, dynamic>> items,
  ) {
    return [
      for (final item in items)
        () {
          final id = item['cartItemId'];
          final cap = id is int ? _quantityCaps[id] : null;
          if (cap == null) return item;
          final copy = Map<String, dynamic>.from(item);
          final existing = copy['maxQuantity'];
          copy['maxQuantity'] =
              existing is int && existing > 0 && existing < cap
              ? existing
              : cap;
          final count = copy['quantity'];
          if (count is int && count > copy['maxQuantity']) {
            final unit = (copy['unitPrice'] as num?) ?? 0;
            copy['quantity'] = copy['maxQuantity'];
            copy['lineTotal'] = unit * copy['maxQuantity'];
          }
          return copy;
        }(),
    ];
  }

  void _setApiLineQuantity(int cartItemId, int quantity, int? cap) {
    final index = _apiItems.indexWhere(
      (item) => item['cartItemId'] == cartItemId,
    );
    if (index < 0) return;
    final updated = Map<String, dynamic>.from(_apiItems[index]);
    final unit = (updated['unitPrice'] as num?) ?? 0;
    updated['quantity'] = quantity;
    updated['lineTotal'] = unit * quantity;
    if (cap != null) updated['maxQuantity'] = cap;
    setState(() {
      final items = [..._apiItems];
      items[index] = updated;
      _apiItems = items;
    });
    _writeQuantityField(cartItemId, quantity);
    _syncHomeCartBadgeCount(
      _apiItems.fold<int>(
        0,
        (sum, item) => sum + ((item['quantity'] as int?) ?? 0),
      ),
    );
  }

  void _writeQuantityField(int cartItemId, int quantity) {
    final field = _apiQuantityFields[cartItemId];
    if (field == null) return;
    final text = '$quantity';
    field.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _syncQuantityFields() {
    for (final item in _apiItems) {
      final id = item['cartItemId'];
      final count = item['quantity'];
      if (id is! int || count is! int) continue;
      final field = _apiQuantityFields[id];
      if (field == null) continue;
      final typed = int.tryParse(field.text.trim());
      if (typed != null && typed != count) {
        _writeQuantityField(id, count);
      }
    }
  }

  int? _quantityCapFromMessage(String message) {
    final lower = message.toLowerCase();
    final aboutQuantity =
        lower.contains('quantit') || message.contains('الكمية');
    if (!aboutQuantity) return null;
    final matches = RegExp(r'(\d+)').allMatches(message);
    if (matches.isEmpty) return null;
    final value = int.tryParse(matches.last.group(1) ?? '');
    if (value == null || value < 1) return null;
    return value;
  }

  Widget _buildApiCartItem(Map<String, dynamic> item) {
    final name = '${item['name'] ?? ''}';
    final portion = '${item['portion'] ?? ''}'.trim();
    final count = item['quantity'] is int ? item['quantity'] as int : 0;
    final total = ((item['lineTotal'] as num?) ?? 0).round();
    final image = '${item['image'] ?? ''}';
    final cartItemId = item['cartItemId'] is int
        ? item['cartItemId'] as int
        : 0;
    final maxQuantity = item['maxQuantity'] is int
        ? item['maxQuantity'] as int
        : null;
    const fallback = ColoredBox(
      color: Color(0xFFF3EFEA),
      child: SizedBox(
        width: 74,
        height: 74,
        child: Icon(Icons.shopping_bag_outlined, color: Color(0xFFA59A94)),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: image.startsWith('http')
                    ? Image.network(
                        image,
                        width: 74,
                        height: 74,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallback,
                      )
                    : fallback,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (portion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        portion,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if ('${item['addOns'] ?? ''}'.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'orders_addons'.trParams({
                          'addons': '${item['addOns']}',
                        }),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'mru'.trParams({'amount': '$total'}),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: cartItemId < 1
                          ? null
                          : () => _applyApiQuantity(cartItemId, count - 1),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Color(0xFFFF5E00),
                          size: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      count.toString(),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap:
                          cartItemId < 1 ||
                              (maxQuantity != null && count >= maxQuantity)
                          ? null
                          : () => _applyApiQuantity(cartItemId, count + 1),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5E00),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: AlignmentDirectional.centerStart,
            child: TextField(
              controller: cartItemId < 1 ? null : _apiQuantityField(cartItemId),
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF2C2520),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'orders_quantity_hint'.tr,
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.done,
              onChanged: cartItemId < 1
                  ? null
                  : (value) => _onApiQuantityTyped(cartItemId, value),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
        ],
      ),
    );
  }

  void _syncHomeCartBadgeCount(int count) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<HomeController>()) {
        final controller = Get.find<HomeController>();
        controller.updateCartItemCount(count);
        if (count == 0) {
          controller.clearCart();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.isRegistered<HomeController>()
          ? Get.find<HomeController>()
          : null;
      final savedCount = controller?.cartItemCount.value ?? 0;
      final savedItem = controller?.lastCartItem;

      final hasDirectParams =
          widget.itemName != null || widget.storeName != null;
      final hasSavedItem =
          savedItem != null &&
          (savedItem['itemName'] != null || savedItem['storeName'] != null);

      if (_cartLoaded) {
        if (_apiItems.isEmpty) quantity = 0;
      } else if (!hasDirectParams &&
          hasSavedItem &&
          savedCount > 0 &&
          quantity != savedCount) {
        quantity = savedCount;
      } else if (!hasDirectParams && savedCount == 0) {
        quantity = 0;
      }

      // Dynamic calculations
      final apiTotal = _apiItems.fold<int>(
        0,
        (sum, item) => sum + (((item['lineTotal'] as num?) ?? 0).round()),
      );
      final itemTotal =
          _summaryItemTotal ?? (_cartLoaded ? apiTotal : basePrice * quantity);
      // Fee, tax and points come from the server summary only; until it
      // loads they count as 0 rather than made-up amounts.
      final pointsOff = usePoints ? _pointsDiscount : 0;
      final currentDeliveryFee = isDelivery ? (_summaryDelivery ?? 0) : 0;
      final currentTax = _summaryTax ?? 0;
      final summaryLoaded = _summaryToPay != null;
      final rawPay = itemTotal - pointsOff + currentDeliveryFee + currentTax;
      final toPay =
          _summaryToPay ?? ((quantity == 0 || rawPay < 0) ? 0 : rawPay);

      final canPop = Navigator.canPop(context);

      return HomeBackgroundBlend(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              color: Colors.transparent,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: (widget.showBottomNav || canPop)
                        ? AppBackButton(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else if (Get.isRegistered<HomeController>()) {
                                Get.find<HomeController>().selectNavigation(0);
                              }
                            },
                          )
                        : const SizedBox(width: 38),
                  ),
                  Text('orders_cart'.tr, style: AppTextStyles.heading()),
                ],
              ),
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_cartLoading) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF5E00),
                            ),
                          ),
                        ),
                      ] else if (_cartLoaded && _apiItems.isNotEmpty) ...[
                        if (storeName.isNotEmpty) ...[
                          Text(
                            'orders_from_vendor'.trParams({'name': storeName}),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        for (final item in _apiItems) _buildApiCartItem(item),
                        if (_needsPrescription || _hasPrescription)
                          _buildPrescriptionSection(),
                      ] else if (quantity > 0) ...[
                        Text(
                          'orders_from_vendor'.trParams({'name': storeName}),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 1. Food Item Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFEAD8C9),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Food Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: itemImage.startsWith('http')
                                        ? Image.network(
                                            itemImage,
                                            width: 74,
                                            height: 74,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  width: 74,
                                                  height: 74,
                                                  color: const Color(
                                                    0xFFF3EFEA,
                                                  ),
                                                  child: const Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          )
                                        : Image.asset(
                                            itemImage,
                                            width: 74,
                                            height: 74,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  width: 74,
                                                  height: 74,
                                                  color: const Color(
                                                    0xFFF3EFEA,
                                                  ),
                                                  child: const Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Text Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemTitle,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          itemPortion,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFA59A94),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'mru'.trParams({
                                            'amount': '${basePrice * quantity}',
                                          }),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFFF5E00),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantity controls
                                  Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0EA),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (quantity > 0) {
                                              _setQuantity(quantity - 1);
                                            }
                                          },
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.remove,
                                              color: Color(0xFFFF5E00),
                                              size: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          quantity.toString(),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              _setQuantity(quantity + 1),
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF5E00),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFEAD8C9),
                                    width: 0.8,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                alignment: AlignmentDirectional.centerStart,
                                child: TextField(
                                  controller: _customQuantityController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF2C2520),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'orders_quantity_hint'.tr,
                                    hintStyle: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onChanged: _onCustomQuantityChanged,
                                  onSubmitted: (_) =>
                                      FocusScope.of(context).unfocus(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFEAD8C9),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                color: Color(0xFFA59A94),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'orders_cart_empty'.tr,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (!_cartLoaded)
                                GestureDetector(
                                  onTap: () => _setQuantity(1),
                                  child: Text(
                                    'orders_add_product'.tr,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFF5E00),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (!_cartLoading && quantity > 0) ...[
                        if (isDelivery) ...[
                          // Add Delivery Note — delivery only
                          if (_deliveryNoteOpen)
                            CustomPaint(
                              painter: _DashedRRectPainter(
                                color: const Color(0xFFCABBAB),
                                radius: 24,
                              ),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 88,
                                ),
                                alignment: AlignmentDirectional.topStart,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F0EC),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: TextField(
                                  controller: _deliveryNoteController,
                                  focusNode: _deliveryNoteFocus,
                                  minLines: 2,
                                  maxLines: 4,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'orders_delivery_note_hint'.tr,
                                    hintStyle: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                setState(() => _deliveryNoteOpen = true);
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    _deliveryNoteFocus.requestFocus();
                                  }
                                });
                              },
                              child: CustomPaint(
                                painter: _DashedRRectPainter(
                                  color: const Color(0xFFCABBAB),
                                  radius: 24,
                                ),
                                child: Container(
                                  height: 48,
                                  alignment: AlignmentDirectional.centerStart,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F0EC),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    'orders_add_delivery_note'.tr,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),
                        ],

                        // 3. Delivery Type
                        Text(
                          'orders_delivery_type'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Delivery Option
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isDelivery = true;
                                    _applyPaymentMethods();
                                  });
                                  _loadCheckoutSummary();
                                  _checkDelivery();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDelivery
                                          ? const Color(0xFFFF5E00)
                                          : const Color(0xFFEAD8C9),
                                      width: isDelivery ? 1.5 : 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDelivery
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFA59A94),
                                            width: 1.5,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(3),
                                        child: isDelivery
                                            ? Container(
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFF5E00),
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'orders_delivery'.tr,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF2C2520),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'orders_delivery_eta'.tr,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFA59A94),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Self Pickup Option
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isDelivery = false;
                                    // Cash and Pay After Delivery are delivery only.
                                    _applyPaymentMethods();
                                  });
                                  _loadCheckoutSummary();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: !isDelivery
                                          ? const Color(0xFFFF5E00)
                                          : const Color(0xFFEAD8C9),
                                      width: !isDelivery ? 1.5 : 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: !isDelivery
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFA59A94),
                                            width: 1.5,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(3),
                                        child: !isDelivery
                                            ? Container(
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFF5E00),
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'orders_self_pickup'.tr,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF2C2520),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'orders_pickup_ready'.tr,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFA59A94),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // 4. Address Details (Shown conditionally based on delivery or pickup selection)
                        if (isDelivery) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFEAD8C9),
                                width: 0.8,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF0EA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.home_outlined,
                                    color: Color(0xFFFF5E00),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // The delivery location the order is
                                      // placed with (was sample text).
                                      Text(
                                        SelectLocationController
                                            .deliveryLabel
                                            .value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        SelectLocationController
                                                .selectedSubtitle
                                                .trim()
                                                .isEmpty
                                            ? SelectLocationController
                                                  .deliveryLabel
                                                  .value
                                            : SelectLocationController
                                                  .selectedSubtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFA59A94),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    'orders_edit'.tr,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFF5E00),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF0EA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFFFF5E00),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'orders_pickup_location'.tr,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'orders_pickup_near'.trParams({
                                          'store': storeName,
                                        }),
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFA59A94),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFFF5E00),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 5. Schedule for Later
                        GestureDetector(
                          onTap: () => _showScheduleBottomSheet(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8EE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFBBEAC5),
                                width: 0.8,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFCEF5DA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Color(0xFF00B25C),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'preorder_title'.tr,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF0E5A2A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _scheduledFor == null
                                            ? 'preorder_pick'.tr
                                            : scheduleText,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF3BA162),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_scheduledFor != null)
                                  // Back to delivering now.
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _scheduledFor = null),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFF00B25C),
                                      size: 20,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF00B25C),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 6. Save More Header & Coupons list
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'orders_save_more'.tr,
                              style: AppTextStyles.title(),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final code = await showCouponsSheet(context);
                                if (code == null || !mounted) return;
                                _couponController.text = code;
                                _applyCoupon(itemTotal);
                              },
                              child: Text(
                                'orders_view_coupons'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Coupon input
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFEAD8C9),
                              width: 0.8,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_offer_outlined,
                                color: Color(0xFFFF5E00),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF2C2520),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'orders_enter_coupon'.tr,
                                    hintStyle: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _applyCoupon(itemTotal),
                                child: Text(
                                  'orders_apply'.tr,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFF5E00),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Store points card: only when the store has
                        // rewards on and the customer has points here.
                        if (_rewardEnabled && _pointsAvailable > 0)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                usePoints = !usePoints;
                              });
                              _loadCheckoutSummary();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: const Color(0xFFEAD8C9),
                                  width: 0.8,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF0EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.monetization_on_outlined,
                                      color: Color(0xFFFF5E00),
                                      size: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'cart_use_points'.trParams({
                                            'points': '$_pointsAvailable',
                                          }),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'cart_points_off'.trParams({
                                            'amount': '$_pointsAmount',
                                          }),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFA59A94),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: usePoints
                                            ? const Color(0xFFFF5E00)
                                            : const Color(0xFFA59A94),
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: usePoints
                                        ? Container(
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF5E00),
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 18),

                        // 7. Payment Header
                        Text(
                          'water_sub_payment'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Payment Cards list
                        // Card 0: Pay After Delivery. Delivery only, never the
                        // default, and selectable only when the server says
                        // can_use; otherwise it says why.
                        if (isDelivery &&
                            _padStatus != null &&
                            PaymentMethods.isOn(
                              paymentTypePayAfterDelivery,
                            )) ...[
                          GestureDetector(
                            onTap: () {
                              if (_padCanUse) {
                                setState(() {
                                  selectedPaymentIndex = 3;
                                  _applyPaymentMethods();
                                });
                              } else if (_padBlockedReason == 'unpaid_order') {
                                Get.to(
                                  () => const PayLaterScreen(),
                                )?.then((_) => _loadPayAfterDelivery());
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: selectedPaymentIndex == 3
                                    ? const Color(0xFFFFF0EA)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: selectedPaymentIndex == 3
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFFEAD8C9),
                                  width: selectedPaymentIndex == 3 ? 1.5 : 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF0EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.verified_user_rounded,
                                        color: Color(0xFFFF5E00),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'pad_option'.tr,
                                          style: GoogleFonts.outfit(
                                            color: _padCanUse
                                                ? const Color(0xFF2C2520)
                                                : const Color(0xFFA59A94),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _padSubtitle,
                                          style: GoogleFonts.outfit(
                                            color: _padCanUse
                                                ? const Color(0xFF8C7D73)
                                                : const Color(0xFFEF4444),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedPaymentIndex == 3
                                            ? const Color(0xFFFF5E00)
                                            : const Color(0xFFA59A94),
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: selectedPaymentIndex == 3
                                        ? Container(
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF5E00),
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Card 1: SAIMPEX Wallet
                        if (PaymentMethods.isOn(paymentTypeWallet))
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPaymentIndex = 0;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: selectedPaymentIndex == 0
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFFEAD8C9),
                                  width: selectedPaymentIndex == 0 ? 1.5 : 0.8,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF0EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: Color(0xFFFF5E00),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'wallet_title'.tr,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _walletSubtitle(toPay),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFA59A94),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedPaymentIndex == 0
                                            ? const Color(0xFFFF5E00)
                                            : const Color(0xFFA59A94),
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: selectedPaymentIndex == 0
                                        ? Container(
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF5E00),
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Card 2: Online Payment
                        if (PaymentMethods.isOn(paymentTypeOnline))
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPaymentIndex = 1;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: selectedPaymentIndex == 1
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFFEAD8C9),
                                  width: selectedPaymentIndex == 1 ? 1.5 : 0.8,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF0EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.credit_card_outlined,
                                      color: Color(0xFFFF5E00),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'water_sub_pay_online'.tr,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'orders_card_mobile_money'.tr,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFA59A94),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedPaymentIndex == 1
                                            ? const Color(0xFFFF5E00)
                                            : const Color(0xFFA59A94),
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: selectedPaymentIndex == 1
                                        ? Container(
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF5E00),
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Card 3: Cash on Delivery (Shown ONLY if Delivery type is Delivery)
                        if (isDelivery && PaymentMethods.isOn(paymentTypeCash))
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPaymentIndex = 2;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: selectedPaymentIndex == 2
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFFEAD8C9),
                                  width: selectedPaymentIndex == 2 ? 1.5 : 0.8,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF0EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.monetization_on_outlined,
                                      color: Color(0xFFFF5E00),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'orders_cash_on_delivery'.tr,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'orders_pay_driver'.tr,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFA59A94),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedPaymentIndex == 2
                                            ? const Color(0xFFFF5E00)
                                            : const Color(0xFFA59A94),
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: selectedPaymentIndex == 2
                                        ? Container(
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF5E00),
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (_noPaymentMethod) const NoPaymentMethodNote(),

                        const SizedBox(height: 14),

                        // 8. Payment Details Box
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2520),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'orders_payment_details'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'orders_item_total'.tr,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'mru'.trParams({'amount': '$itemTotal'}),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (usePoints && pointsOff > 0) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'cart_redeemed_points'.tr,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '-${'mru'.trParams({'amount': '$pointsOff'})}',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFFF5E00),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (isDelivery) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'cart_delivery_fee'.tr,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      // Free delivery (e.g. Gold tier or
                                      // the store's fee rule) is a 0 fee.
                                      !summaryLoaded
                                          ? '…'
                                          : currentDeliveryFee == 0
                                          ? 'cart_free_delivery'.tr
                                          : 'mru'.trParams({
                                              'amount': '$currentDeliveryFee',
                                            }),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'cart_tax'.tr,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    summaryLoaded
                                        ? 'mru'.trParams({
                                            'amount': '$currentTax',
                                          })
                                        : '…',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(
                                color: Color(0xFF423B36),
                                height: 1,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'orders_to_pay'.tr,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'mru'.trParams({'amount': '$toPay'}),
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
                        ),

                        const SizedBox(height: 24),

                        // 9. Gradient Pay Button
                        GestureDetector(
                          onTap: () {
                            if (itemTotal < 500) {
                              _showMinimumOrderReminder(context, itemTotal);
                              return;
                            }
                            _placeOrder(toPay);
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
                              selectedPaymentIndex == 3
                                  ? 'orders_order_now'.tr
                                  : 'orders_pay_amount'.trParams({
                                      'amount': 'mru'.trParams({
                                        'amount': '$toPay',
                                      }),
                                    }),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: widget.showBottomNav
                    ? AppBottomNavBar(
                        selectedIndex: HomeController.navCart,
                        onTap: BottomNavRouter.go,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showMinimumOrderReminder(BuildContext context, int orderValue) {
    const minimum = 500;
    final current = orderValue < 0 ? 0 : orderValue;
    final remaining = minimum - current;
    final progress = (current / minimum).clamp(0.0, 1.0);

    showDialog<void>(
      context: context,
      barrierColor: const Color(0x8A2A241F),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE8DC),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFFF5E00),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFFFF8F2),
                      Color(0xFFFFF4EA),
                      Color(0xFFFFE7C2),
                    ],
                    stops: [0.0, 0.62, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.shopping_cart,
                            color: Color(0xFFFF5E00),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'orders_min_order'.trParams({
                              'amount': 'mru'.trParams({'amount': '500'}),
                            }),
                            maxLines: 1,
                            softWrap: false,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2118),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF3D2C22),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: 'orders_min_add_prefix'.tr),
                          TextSpan(
                            text: 'mru'.trParams({'amount': '$remaining'}),
                            style: const TextStyle(
                              color: Color(0xFFAB2F00),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(text: 'orders_min_add_suffix'.tr),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6E2DE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: progress == 0 ? 0.001 : progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5E00), Color(0xFFFFC14D)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Text(
                          'orders_continue_shopping'.tr,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// When each slot starts: the pre-order is placed for that time.
  static const _slotStartHours = {
    '8-10 AM': 8,
    '10-12 PM': 10,
    '2-4 PM': 14,
    '4-6 PM': 16,
    '6-8 PM': 18,
    'Late night': 22,
  };

  /// Shown text for a slot value (the values stay English: they key the hours).
  static String _slotText(String slot) => switch (slot) {
    '8-10 AM' => 'orders_slot_8_10'.tr,
    '10-12 PM' => 'orders_slot_10_12'.tr,
    '2-4 PM' => 'orders_slot_2_4'.tr,
    '4-6 PM' => 'orders_slot_4_6'.tr,
    '6-8 PM' => 'orders_slot_6_8'.tr,
    'Late night' => 'orders_slot_late'.tr,
    _ => slot,
  };

  Future<void> _showScheduleBottomSheet(BuildContext context) async {
    // Only times inside the server's pre-order window can be picked.
    final ({DateTime earliest, DateTime latest}) window;
    try {
      window = await Get.find<OrderRepository>().preorderWindow(
        apiLanguageCode(),
      );
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      return;
    }
    if (!mounted || !context.mounted) return;
    final firstDay = DateTime(
      window.earliest.year,
      window.earliest.month,
      window.earliest.day,
    );
    final lastDay = DateTime(
      window.latest.year,
      window.latest.month,
      window.latest.day,
    );
    final dates = <DateTime>[
      for (
        var day = firstDay;
        !day.isAfter(lastDay);
        day = DateTime(day.year, day.month, day.day + 1)
      )
        day,
    ];
    DateTime slotStart(DateTime day, String slot) =>
        DateTime(day.year, day.month, day.day, _slotStartHours[slot]!);
    bool slotOpen(DateTime day, String slot) {
      final start = slotStart(day, slot);
      return !start.isBefore(window.earliest) && !start.isAfter(window.latest);
    }

    DateTime selectedDate = dates.first;
    String? selectedTimeSlot;

    // Translation keys, shown with .tr.
    const months = [
      'orders_month_jan',
      'orders_month_feb',
      'orders_month_mar',
      'orders_month_apr',
      'orders_month_may',
      'orders_month_jun',
      'orders_month_jul',
      'orders_month_aug',
      'orders_month_sep',
      'orders_month_oct',
      'orders_month_nov',
      'orders_month_dec',
    ];
    const weekdays = [
      'orders_day_mon',
      'orders_day_tue',
      'orders_day_wed',
      'orders_day_thu',
      'orders_day_fri',
      'orders_day_sat',
      'orders_day_sun',
    ];
    const timeSlots = [
      '8-10 AM',
      '10-12 PM',
      '2-4 PM',
      '4-6 PM',
      '6-8 PM',
      'Late night',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomPad = MediaQuery.paddingOf(context).bottom;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 56),
                  height: MediaQuery.of(context).size.height * 0.72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFF3EC), Colors.white],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF6F1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFD7C2),
                                ),
                              ),
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFFFF5E00),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'preorder_sheet_title'.tr,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2C2520),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'preorder_sheet_subtitle'.tr,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFFEAD8C9), height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'preorder_select_date'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 86,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: dates.length,
                                  separatorBuilder: (_, index) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final date = dates[index];
                                    final isSelected =
                                        selectedDate.year == date.year &&
                                        selectedDate.month == date.month &&
                                        selectedDate.day == date.day;
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedDate = date;
                                          final slot = selectedTimeSlot;
                                          if (slot != null &&
                                              !slotOpen(date, slot)) {
                                            selectedTimeSlot = null;
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 62,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFEAD8C9),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              months[date.month - 1].tr,
                                              style: GoogleFonts.outfit(
                                                color: isSelected
                                                    ? const Color(0xFFFF5E00)
                                                    : const Color(0xFFA59A94),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${date.day}',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFF2C2520),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              weekdays[date.weekday - 1].tr,
                                              style: GoogleFonts.outfit(
                                                color: isSelected
                                                    ? const Color(0xFFFF5E00)
                                                    : const Color(0xFFA59A94),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'preorder_time_slot'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 3.4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 10,
                                children: timeSlots.map((slot) {
                                  final isSelected = selectedTimeSlot == slot;
                                  final open = slotOpen(selectedDate, slot);
                                  return GestureDetector(
                                    onTap: () {
                                      if (!open) return;
                                      setModalState(
                                        () => selectedTimeSlot = slot,
                                      );
                                    },
                                    child: Opacity(
                                      opacity: open ? 1 : 0.35,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFE6E0DB),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.access_time_rounded,
                                              color: Color(0xFFFF5E00),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                _slotText(slot),
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  color: const Color(
                                                    0xFFFF5E00,
                                                  ),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPad),
                        child: GestureDetector(
                          onTap: () {
                            final slot = selectedTimeSlot;
                            if (slot == null || !slotOpen(selectedDate, slot)) {
                              showAppToast(
                                'preorder_choose_slot'.tr,
                                backgroundColor: const Color(0xFFEF4444),
                              );
                              return;
                            }
                            final month = months[selectedDate.month - 1].tr;
                            final weekday =
                                weekdays[selectedDate.weekday - 1].tr;
                            Navigator.pop(context);
                            setState(() {
                              _scheduledFor = slotStart(selectedDate, slot);
                              scheduleText =
                                  '$weekday, $month ${selectedDate.day} • ${_slotText(slot)}';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'preorder_scheduled'.trParams({
                                    'time': scheduleText,
                                  }),
                                  style: GoogleFonts.outfit(),
                                ),
                                backgroundColor: const Color(0xFFFF5E00),
                              ),
                            );
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF5E00,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'orders_continue'.tr,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFF5E00),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final dashed = Path();

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashed.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + dashSpace;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
