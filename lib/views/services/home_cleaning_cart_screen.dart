import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/select_location_controller.dart';
import 'home_cleaning_choose_slot_sheet.dart';
import 'home_cleaning_booking_success_screen.dart';
import 'service_booking_submit.dart';
import '../../widgets/app_back_button.dart';
import '../../core/network/api_exception.dart';
import '../../utils/wallet_balance.dart';
import '../../utils/payment_methods.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/no_payment_method_note.dart';

/// Display text for a home-cleaning space, extra or pest label. The labels
/// stay English in the booking data (they are matched against the catalog);
/// only what is shown is translated.
String homeCleaningLabelText(String label) {
  const keys = {
    'Bedrooms': 'svc_hc_bedrooms',
    'Kitchens': 'svc_hc_kitchens',
    'Bathrooms / WC': 'svc_hc_bathrooms',
    'Balconies': 'svc_hc_balconies',
    'Fridge Cleaning': 'svc_hc_fridge',
    'Dish Washing': 'svc_hc_dish',
    'Cockroaches': 'svc_pest_cockroaches',
    'Ants': 'svc_pest_ants',
    'Bed Bugs': 'svc_pest_bed_bugs',
    'Mosquitoes': 'svc_pest_mosquitoes',
    'Rodents': 'svc_pest_rodents',
    'Termites': 'svc_pest_termites',
    'General Disinfection': 'svc_pest_disinfection',
    'Flies': 'svc_pest_flies',
    'Other': 'svc_pest_other',
  };
  final key = keys[label];
  return key == null ? label : key.tr;
}

class HomeCleaningCartScreen extends StatefulWidget {
  final String providerName;
  final String serviceTitle;
  final String serviceImage;
  final String serviceDescription;
  final int bedrooms;
  final int bathrooms;
  final int kitchens;
  final int balconies;
  final List<Map<String, dynamic>> spaces;
  final List<Map<String, dynamic>> extras;
  final List<Map<String, dynamic>> selectedPests;
  final String productsProvider;
  final int productsFee;
  final int basePrice;
  final int baseDurationMin;
  final DateTime slotDate;
  final String slotLabel;
  final Set<String> initialAddonIds;

  /// From the configure screen; sent with the booking.
  final String propertyType;
  final String notes;

  const HomeCleaningCartScreen({
    super.key,
    this.providerName = 'CleanPro Elite',
    this.serviceTitle = 'Regular Cleaning',
    this.serviceImage = 'lib/assets/images/regular_cleaning.jpg',
    this.serviceDescription =
        'Standard cleaning for bedrooms, bathrooms, living...',
    this.bedrooms = 2,
    this.bathrooms = 2,
    this.kitchens = 0,
    this.balconies = 0,
    this.spaces = const [],
    this.extras = const [],
    this.selectedPests = const [],
    this.productsProvider = 'self',
    this.propertyType = '',
    this.notes = '',
    this.productsFee = 120,
    this.basePrice = 750,
    this.baseDurationMin = 90,
    required this.slotDate,
    required this.slotLabel,
    this.initialAddonIds = const {},
  });

  @override
  State<HomeCleaningCartScreen> createState() => _HomeCleaningCartScreenState();
}

class _HomeCleaningCartScreenState extends State<HomeCleaningCartScreen> {
  late DateTime _slotDate;
  late String _slotLabel;
  late String _productsProvider;
  int _paymentIndex = 0; // mandatory — Wallet selected by default
  bool _noPaymentMethod = false;

  static const _roomLabels = {
    'Bedrooms',
    'Kitchens',
    'Bathrooms / WC',
    'Balconies',
  };

  static const _defaultRates = {
    'Bedrooms': 100,
    'Kitchens': 150,
    'Bathrooms / WC': 80,
    'Balconies': 60,
    'Fridge Cleaning': 100,
    'Dish Washing': 150,
  };

  /// Keeps the choice on a method Admin has switched on (wallet or online).
  void _applyPaymentMethods() {
    final type = PaymentMethods.keepOrFirstOn(
      _paymentIndex == 1 ? paymentTypeOnline : paymentTypeWallet,
      const [paymentTypeWallet, paymentTypeOnline],
    );
    _noPaymentMethod = type == null;
    if (type != null) _paymentIndex = type == paymentTypeOnline ? 1 : 0;
  }

  @override
  void initState() {
    super.initState();
    _applyPaymentMethods();
    PaymentMethods.refresh().then((changed) {
      if (changed && mounted) setState(_applyPaymentMethods);
    });
    _slotDate = widget.slotDate;
    _slotLabel = widget.slotLabel;
    _productsProvider = widget.productsProvider;
    _loadQuote();
  }

  String get _paymentType =>
      _paymentIndex == 1 ? paymentTypeOnline : paymentTypeWallet;

  /// `{name, quantity}` rows as customer/service/book takes them.
  List<Map<String, dynamic>> _bookingRows(List<Map<String, dynamic>> rows) => [
    for (final row in rows) {'name': row['label'], 'quantity': row['qty']},
  ];

  String get _productSupply =>
      _productsProvider == 'provider' ? 'vendor' : 'customer';

  /// The server's price for this booking (customer/service/quote):
  /// `subtotal`, `tax`, `total`. Null while loading or when it failed.
  Map<String, dynamic>? _quote;
  String? _quoteError;

  Future<void> _loadQuote() async {
    setState(() {
      _quote = null;
      _quoteError = null;
    });
    try {
      final quote = await quoteServiceBooking(
        slotDate: _slotDate,
        slotLabel: _slotLabel,
        paymentType: _paymentType,
        spaces: _bookingRows(_spaceRows),
        addons: _bookingRows(_extraRows),
        productSupply: _productSupply,
        propertyType: widget.propertyType,
      );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        if (quote == null) _quoteError = 'svc_choose_service_again'.tr;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _quoteError = error.message);
    }
  }

  num? _quoted(String key) => num.tryParse('${_quote?[key] ?? ''}');

  bool _booking = false;

  Future<void> _placeBooking() async {
    if (_noPaymentMethod) {
      showAppToast(
        'payment_no_method'.tr,
        backgroundColor: const Color(0xFFEF4444),
      );
      return;
    }
    if (_booking) return;
    if (_quote == null) {
      if (_quoteError != null) {
        showAppToast(_quoteError!, backgroundColor: const Color(0xFFEF4444));
      }
      return;
    }
    setState(() => _booking = true);
    final booking = await placeServiceBooking(
      shownTotal: _toPay,
      slotDate: _slotDate,
      slotLabel: _slotLabel,
      paymentType: _paymentType,
      spaces: _bookingRows(_spaceRows),
      addons: _bookingRows(_extraRows),
      productSupply: _productSupply,
      propertyType: widget.propertyType,
      notes: widget.notes,
    );
    if (!mounted) return;
    setState(() => _booking = false);
    if (booking == null) return;
    Get.off(() => const HomeCleaningBookingSuccessScreen());
  }

  List<Map<String, dynamic>> get _allSourceRows {
    if (widget.spaces.isNotEmpty || widget.extras.isNotEmpty) {
      return [...widget.spaces, ...widget.extras];
    }
    final rows = <Map<String, dynamic>>[];
    if (widget.bedrooms > 0) {
      rows.add({'label': 'Bedrooms', 'rate': 100, 'qty': widget.bedrooms});
    }
    if (widget.kitchens > 0) {
      rows.add({'label': 'Kitchens', 'rate': 150, 'qty': widget.kitchens});
    }
    if (widget.bathrooms > 0) {
      rows.add({
        'label': 'Bathrooms / WC',
        'rate': 80,
        'qty': widget.bathrooms,
      });
    }
    if (widget.balconies > 0) {
      rows.add({'label': 'Balconies', 'rate': 60, 'qty': widget.balconies});
    }
    return rows;
  }

  List<Map<String, dynamic>> get _spaceRows => _allSourceRows.where((s) {
    final label = s['label'] as String? ?? '';
    final qty = (s['qty'] as int?) ?? 0;
    return qty > 0 && _roomLabels.contains(label);
  }).toList();

  List<Map<String, dynamic>> get _extraRows {
    if (widget.extras.isNotEmpty) {
      return widget.extras.where((s) => ((s['qty'] as int?) ?? 0) > 0).toList();
    }
    return _allSourceRows.where((s) {
      final label = s['label'] as String? ?? '';
      final qty = (s['qty'] as int?) ?? 0;
      return qty > 0 &&
          !_roomLabels.contains(label) &&
          label != 'Cleaning Products';
    }).toList();
  }

  int _rowTotal(Map<String, dynamic> s) {
    final label = s['label'] as String? ?? '';
    final rate = (s['rate'] as int?) ?? (_defaultRates[label] ?? 0);
    final qty = (s['qty'] as int?) ?? 0;
    return rate * qty;
  }

  int get _spacesTotal =>
      _spaceRows.fold<int>(0, (sum, s) => sum + _rowTotal(s));

  int get _extrasTotal =>
      _extraRows.fold<int>(0, (sum, s) => sum + _rowTotal(s));

  int get _productsTotal =>
      _productsProvider == 'provider' ? widget.productsFee : 0;

  /// The provider's price before tax; the cart's own estimate until the
  /// server answers.
  int get _subtotal =>
      (_quoted('subtotal') ?? _spacesTotal + _extrasTotal + _productsTotal)
          .round();
  int? get _tax => _quoted('tax')?.round();
  int get _toPay => (_quoted('total') ?? _subtotal).round();

  // Translation keys.
  static const _months = [
    'svc_month_1',
    'svc_month_2',
    'svc_month_3',
    'svc_month_4',
    'svc_month_5',
    'svc_month_6',
    'svc_month_7',
    'svc_month_8',
    'svc_month_9',
    'svc_month_10',
    'svc_month_11',
    'svc_month_12',
  ];

  String get _slotDisplay {
    final d = _slotDate;
    return '${d.day} ${_months[d.month - 1].tr} ${d.year}, $_slotLabel';
  }

  String _slotRangeFromLabel(String label) {
    final match = RegExp(
      r'(\d+)\s*-\s*(\d+)\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(label);
    if (match == null) return label;
    final start = match.group(1)!;
    final end = match.group(2)!;
    final period = match.group(3)!.toUpperCase();
    return '$start:00 $period - $end:00 $period';
  }

  Future<void> _changeSlot() async {
    final result = await HomeCleaningChooseSlotSheet.show(context);
    if (result == null) return;
    setState(() {
      _slotDate = result['date'] as DateTime;
      _slotLabel = _slotRangeFromLabel(result['slot'] as String);
    });
    _loadQuote();
  }

  bool get _isPestControl =>
      widget.serviceTitle.toLowerCase().contains('pest') ||
      widget.serviceTitle.toLowerCase().contains('disinfection');

  void _clearAll() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 20 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFromClearRow(),
                      const SizedBox(height: 12),
                      _buildMainServiceCard(),
                      const SizedBox(height: 22),
                      if (_spaceRows.isNotEmpty) ...[
                        _sectionTitle(
                          _isPestControl
                              ? 'svc_areas_to_treat'.tr
                              : 'svc_spaces'.tr,
                        ),
                        const SizedBox(height: 12),
                        _buildLineItemsCard(_spaceRows),
                        const SizedBox(height: 22),
                      ],
                      if (_isPestControl &&
                          widget.selectedPests.isNotEmpty) ...[
                        _sectionTitle('svc_what_facing'.tr),
                        const SizedBox(height: 12),
                        _buildSelectedPestsRow(),
                        const SizedBox(height: 22),
                      ],
                      if (!_isPestControl && _extraRows.isNotEmpty) ...[
                        _sectionTitle('svc_extra_clean'.tr),
                        const SizedBox(height: 12),
                        _buildLineItemsCard(_extraRows),
                        const SizedBox(height: 22),
                      ],
                      if (!_isPestControl) ...[
                        _buildCleaningProductsSection(),
                        const SizedBox(height: 22),
                      ],
                      _sectionTitle('svc_cleaning_details'.tr),
                      const SizedBox(height: 12),
                      _buildAddressCard(),
                      const SizedBox(height: 10),
                      _buildSlotCard(),
                      const SizedBox(height: 22),
                      _sectionTitle('svc_payment'.tr),
                      const SizedBox(height: 12),
                      if (PaymentMethods.isOn(paymentTypeWallet)) ...[
                        _buildPaymentOption(
                          index: 0,
                          imageAsset: 'lib/assets/images/wallet.png',
                          title: 'wallet_title'.tr,
                          subtitle: walletBalanceSubtitle(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (PaymentMethods.isOn(paymentTypeOnline))
                        _buildPaymentOption(
                          index: 1,
                          imageAsset: 'lib/assets/images/currency.png',
                          title: 'svc_online_payment'.tr,
                          subtitle: 'svc_card_mobile_money'.tr,
                        ),
                      if (_noPaymentMethod) const NoPaymentMethodNote(),
                      const SizedBox(height: 22),
                      _buildPaymentDetailsCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(bottomInset),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppBackButton(onTap: () => Get.back()),
          ),
          Text(
            'svc_cart'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFromClearRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'svc_from_provider'.trParams({'provider': widget.providerName}),
            style: GoogleFonts.outfit(
              color: const Color(0xFF9A8E86),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        GestureDetector(
          onTap: _clearAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF5E00),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                'svc_clear_all'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF1A1A1A),
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildMainServiceCard() {
    final image = widget.serviceImage;
    final isNetwork = image.startsWith('http');

    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetwork
                ? Image.network(
                    image,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imageFallback(72),
                  )
                : Image.asset(
                    image,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imageFallback(72),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.serviceTitle,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'svc_edit'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.serviceDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsCard(List<Map<String, dynamic>> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _spaceRow(rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedPestsRow() {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.selectedPests.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final pest = widget.selectedPests[index];
          final label = pest['label'] as String? ?? '';
          final image = pest['image'] as String?;
          return Container(
            width: 100,
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFC9A8)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: image != null
                      ? Image.asset(
                          image,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.bug_report_outlined,
                            color: Color(0xFF2B5A9E),
                            size: 22,
                          ),
                        )
                      : Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1B2B4A),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.north_east_rounded,
                            color: Color(0xFF1B2B4A),
                            size: 14,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  homeCleaningLabelText(label),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCleaningProductsSection() {
    final providerSelected = _productsProvider == 'provider';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('svc_cleaning_products'.tr)),
            Text(
              providerSelected
                  ? 'svc_plus_mru'.trParams({'amount': '${widget.productsFee}'})
                  : 'mru'.trParams({'amount': '0'}),
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EB),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFD8C2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF5E00),
                        width: 1.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5E00),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerSelected
                              ? 'svc_provider_provides_products'.tr
                              : 'svc_self_provides_products'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          providerSelected
                              ? 'svc_provider_products_hint'.tr
                              : 'svc_self_products_hint'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF8A7E76),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _productsProvider = providerSelected ? 'self' : 'provider';
                  });
                  _loadQuote();
                },
                child: Text(
                  providerSelected
                      ? 'svc_switch_to_self'.tr
                      : 'svc_switch_to_provider'.trParams({
                          'amount': '${widget.productsFee}',
                        }),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _spaceRow(Map<String, dynamic> space) {
    final label = space['label'] as String? ?? '';
    final rate = (space['rate'] as int?) ?? (_defaultRates[label] ?? 0);
    final qty = (space['qty'] as int?) ?? 0;
    final total = rate * qty;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homeCleaningLabelText(label),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'svc_rate_times_qty'.trParams({
                    'rate': '$rate',
                    'qty': '$qty',
                  }),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'mru'.trParams({'amount': '$total'}),
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Color(0xFFFF5E00),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SelectLocationController.selectedTitle.isNotEmpty
                      ? SelectLocationController.selectedTitle
                      : 'Sahara View Home',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SelectLocationController.selectedSubtitle.isNotEmpty
                      ? SelectLocationController.selectedSubtitle
                      : 'Near Marhaba Supermarket, Nouakchott',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'svc_edit'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard() {
    return GestureDetector(
      onTap: _changeSlot,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFF5E00), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5E00),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'svc_your_slot'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _slotDisplay,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6B6B6B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFFF5E00)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required String imageAsset,
    required String title,
    required String subtitle,
  }) {
    final selected = _paymentIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        // Payment type is mandatory — switch between options, never clear.
        _paymentIndex = index;
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                imageAsset,
                width: 20,
                height: 20,
                color: const Color(0xFFFF5E00),
                errorBuilder: (_, _, _) => Icon(
                  index == 0
                      ? Icons.account_balance_wallet_outlined
                      : Icons.credit_card_rounded,
                  color: const Color(0xFFFF5E00),
                  size: 20,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFC4B8AF),
                  width: 1.8,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
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
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'svc_payment_details'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('svc_total'.tr, 'mru'.trParams({'amount': '$_subtotal'})),
          const SizedBox(height: 10),
          // "…" until the server has priced the booking.
          _detailRow(
            'svc_tax'.tr,
            _tax == null ? '…' : 'mru'.trParams({'amount': '$_tax'}),
          ),
          if (_quoteError != null) ...[
            const SizedBox(height: 10),
            Text(
              _quoteError!,
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF8A80),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF4A4A4A), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'svc_to_pay'.tr,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'mru'.trParams({'amount': '$_toPay'}),
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

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 14 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'svc_total_upper'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF8A7E76),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'mru'.trParams({'amount': '$_toPay'}),
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _placeBooking,
            child: Container(
              width: double.infinity,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _booking
                    ? 'svc_booking_in_progress'.tr
                    : 'svc_pay_amount'.trParams({'amount': '$_toPay'}),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFFFF3EB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.cleaning_services_rounded,
        color: Color(0xFFFF5E00),
      ),
    );
  }
}
