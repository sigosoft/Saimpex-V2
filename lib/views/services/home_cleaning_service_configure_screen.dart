import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'home_cleaning_cart_screen.dart';
import 'home_cleaning_choose_slot_sheet.dart';
import '../../widgets/app_back_button.dart';

import '../../controllers/service_booking_draft.dart';
import '../../utils/api_language.dart';
import '../../utils/app_fonts.dart';

class HomeCleaningServiceConfigureScreen extends StatefulWidget {
  final Map<String, String> service;
  final String providerName;

  const HomeCleaningServiceConfigureScreen({
    super.key,
    required this.service,
    this.providerName = '',
  });

  @override
  State<HomeCleaningServiceConfigureScreen> createState() =>
      _HomeCleaningServiceConfigureScreenState();
}

class _HomeCleaningServiceConfigureScreenState
    extends State<HomeCleaningServiceConfigureScreen> {
  // Everything below comes from the picked service's catalog in
  // customer/serviceProvider (ServiceBookingDraft.item): spaces, addons,
  // property_types, issues, supply_fee. It used to be a fixed list (Bedrooms
  // 100, Kitchens 150, Bathrooms 80, Balconies 60, Fridge 100, Dish 150,
  // products +120, 4 bedrooms preselected), so a provider whose rooms are
  // named or priced differently got wrong prices and a refused booking.
  late final List<Map<String, Object>> _roomRates = _catalogRows('spaces');
  late final List<Map<String, Object>> _extraClean = _catalogRows('addons');
  late final List<Map<String, Object>> _pestIssues = _issueRows();
  late final List<String> _propertyTypes = _textList('property_types');

  late String _propertyType = _propertyTypes.isEmpty
      ? ''
      : _propertyTypes.first;
  final Map<String, int> _spaceQty = {};
  final Map<String, int> _addonQty = {};

  /// `self` = customer provides, `provider` = the provider brings them
  /// (+ the service's `supply_fee`).
  String _productsProvider = 'self';
  final _notesController = TextEditingController();
  final Set<String> _selectedPests = {};

  static Map<String, dynamic> get _item => ServiceBookingDraft.item;

  static List<Map<String, Object>> _catalogRows(String key) {
    final raw = _item[key];
    if (raw is! List) return const [];
    final language = apiLanguageCode();
    final rows = <Map<String, Object>>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final name = '${entry['name'] ?? ''}'.trim();
      if (name.isEmpty) continue;
      final local = '${entry['name_$language'] ?? ''}'.trim();
      final unit = '${entry['unit'] ?? ''}'.trim().toLowerCase();
      rows.add({
        'key': '${entry['id'] ?? rows.length}',
        'label': name,
        'display': local.isNotEmpty ? local : homeCleaningLabelText(name),
        'unitLabel': unit.contains('room')
            ? 'svc_rate_per_room'
            : 'svc_rate_per_unit',
        'rate': num.tryParse('${entry['price'] ?? ''}')?.round() ?? 0,
      });
    }
    return rows;
  }

  static List<String> _textList(String key) {
    final raw = _item[key];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if ('$entry'.trim().isNotEmpty) '$entry'.trim(),
    ];
  }

  /// The provider's pest issues, with the bundled picture for known ones.
  static List<Map<String, Object>> _issueRows() {
    const pictures = {
      'cockroach': 'lib/assets/images/Cockroach.png',
      'ant': 'lib/assets/images/Ant.png',
      'bed bug': 'lib/assets/images/BedBug.png',
      'mosquito': 'lib/assets/images/Mosquito.png',
      'rodent': 'lib/assets/images/Rodent.png',
      'termite': 'lib/assets/images/Termite.png',
      'disinfection': 'lib/assets/images/BlueShield.png',
      'fl': 'lib/assets/images/Fly.png',
    };
    return [
      for (final name in _textList('issues'))
        {
          'id': name,
          'label': name,
          'display': homeCleaningLabelText(name),
          for (final entry in pictures.entries)
            if (name.toLowerCase().startsWith(entry.key)) 'image': entry.value,
        },
    ];
  }

  static int get _supplyFee =>
      num.tryParse('${_item['supply_fee'] ?? ''}')?.round() ?? 0;

  /// The provider can bring the products: a fee or a product list is set.
  static bool get _offersProducts =>
      _supplyFee > 0 || _textList('product_supply').isNotEmpty;

  String get _title => widget.service['title'] ?? '';

  bool get _isPestControl =>
      _title.toLowerCase().contains('pest') ||
      _title.toLowerCase().contains('disinfection') ||
      _pestIssues.isNotEmpty;

  int get _basePrice {
    final raw = widget.service['price'] ?? '';
    return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  int get _baseDurationMin =>
      _parseDurationMinutes(widget.service['duration'] ?? '');

  int _sum(List<Map<String, Object>> rows, Map<String, int> qty) =>
      rows.fold<int>(
        0,
        (sum, row) => sum + (row['rate'] as int) * (qty[row['key']] ?? 0),
      );

  int get _roomsPrice => _sum(_roomRates, _spaceQty);

  int get _productsPrice => _productsProvider == 'provider' ? _supplyFee : 0;

  int get _extrasPrice => _isPestControl ? 0 : _sum(_extraClean, _addonQty);

  /// The app's estimate; the cart shows the server's quote.
  int get _totalPrice {
    final selected =
        _roomsPrice + (_isPestControl ? 0 : _productsPrice) + _extrasPrice;
    return selected > 0 ? selected : _basePrice;
  }

  int get _totalDurationMin => _baseDurationMin;

  /// Rows the cart sends to service/quote and service/book.
  List<Map<String, dynamic>> _selectedRows(
    List<Map<String, Object>> rows,
    Map<String, int> qty,
  ) => [
    for (final row in rows)
      if ((qty[row['key']] ?? 0) > 0)
        {
          'label': row['label'],
          'display': row['display'],
          'rate': row['rate'],
          'qty': qty[row['key']],
        },
  ];

  String get _heroImage {
    final image = widget.service['image'];
    if (image != null && image.isNotEmpty) return image;
    return 'lib/assets/images/cleanproelitee.jpg';
  }

  bool get _heroIsNetwork => _heroImage.startsWith('http');

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  static int _parseDurationMinutes(String raw) {
    var hours = 0;
    var mins = 0;
    final hourMatch = RegExp(r'(\d+)\s*hr').firstMatch(raw);
    final minMatch = RegExp(r'(\d+)\s*min').firstMatch(raw);
    if (hourMatch != null) hours = int.parse(hourMatch.group(1)!);
    if (minMatch != null) mins = int.parse(minMatch.group(1)!);
    if (hours == 0 && mins == 0) return 0;
    return hours * 60 + mins;
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

  Future<void> _openSlotAndGoToCart() async {
    final result = await HomeCleaningChooseSlotSheet.show(context);
    if (result == null || !mounted) return;

    final date = result['date'] as DateTime;
    final slot = _slotRangeFromLabel(result['slot'] as String);

    Get.to(
      () => HomeCleaningCartScreen(
        providerName: widget.providerName,
        serviceTitle: _title,
        serviceImage: _heroImage,
        serviceDescription: _isPestControl
            ? 'svc_pest_service_desc'.tr
            : 'svc_regular_service_desc'.tr,
        spaces: _selectedRows(_roomRates, _spaceQty),
        extras: _isPestControl
            ? const []
            : _selectedRows(_extraClean, _addonQty),
        productsProvider: _isPestControl ? 'self' : _productsProvider,
        propertyType: _propertyType,
        notes: _notesController.text,
        productsFee: _supplyFee,
        selectedPests: _isPestControl
            ? _pestIssues
                  .where((p) => _selectedPests.contains(p['id']))
                  .map(
                    (p) => {
                      'id': p['id'],
                      'label': p['label'],
                      if (p['image'] != null) 'image': p['image'],
                    },
                  )
                  .toList()
            : const [],
        basePrice: _totalPrice,
        baseDurationMin: _totalDurationMin,
        slotDate: date,
        slotLabel: slot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFEDE5),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFEDE5), Color(0xFFFAF6F0), Color(0xFFFAF6F0)],
            stops: [0.0, 0.22, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      12 + bottomInset + 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(),
                        const SizedBox(height: 12),
                        // Each section shows only what this service lists.
                        if (_basePrice > 0) ...[
                          _buildInfoChips(),
                          const SizedBox(height: 22),
                        ],
                        if (_propertyTypes.isNotEmpty) ...[
                          _buildPropertyType(),
                          const SizedBox(height: 22),
                        ],
                        if (_isPestControl) ...[
                          if (_pestIssues.isNotEmpty) ...[
                            _buildPestFacing(),
                            const SizedBox(height: 22),
                          ],
                          if (_roomRates.isNotEmpty) ...[
                            _buildAreasToTreat(),
                            const SizedBox(height: 22),
                          ],
                          _buildSpecialNotes(),
                        ] else ...[
                          if (_roomRates.isNotEmpty) ...[
                            _buildHomeDetails(),
                            const SizedBox(height: 22),
                          ],
                          if (_offersProducts) ...[
                            _buildCleaningProducts(),
                            const SizedBox(height: 22),
                          ],
                          if (_extraClean.isNotEmpty) ...[
                            _buildAddons(),
                            const SizedBox(height: 22),
                          ],
                          _buildSpecialNotes(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(bottomInset),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
            _title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: _isPestControl ? 15.5 : 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _heroIsNetwork
            ? Image.network(
                _heroImage,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  'lib/assets/images/cleanproelitee.jpg',
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                _heroImage,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  'lib/assets/images/cleanproelitee.jpg',
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoChips() {
    return Row(
      children: [
        _infoChip(
          imageAsset: 'lib/assets/images/currency.png',
          label: 'svc_from_price'.trParams({'amount': '$_basePrice'}),
        ),
      ],
    );
  }

  Widget _infoChip({
    IconData? icon,
    String? imageAsset,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageAsset != null)
            Image.asset(
              imageAsset,
              width: 15,
              height: 15,
              color: const Color(0xFFFF5216),
              errorBuilder: (_, _, _) => const Icon(
                Icons.account_balance_wallet_outlined,
                size: 15,
                color: Color(0xFFFF5216),
              ),
            )
          else
            Icon(icon, size: 15, color: const Color(0xFFFF5216)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.outfit(
              color: const Color(0xFF2B5A9E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppFonts.outfit(
        color: const Color(0xFF1B2B4A),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _sectionTitleWithOptional(String title) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: title,
            style: AppFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' (${'svc_optional'.tr})',
            style: AppFonts.outfit(
              color: const Color(0xFF6B6B6B),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitleWithOptional('svc_property_type'.tr),
        const SizedBox(height: 12),
        // The provider's own property types, two per row.
        for (var i = 0; i < _propertyTypes.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _propertyCard(
                  type: _propertyTypes[i],
                  icon: _propertyIcon(_propertyTypes[i]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < _propertyTypes.length
                    ? _propertyCard(
                        type: _propertyTypes[i + 1],
                        icon: _propertyIcon(_propertyTypes[i + 1]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static IconData _propertyIcon(String type) {
    final value = type.toLowerCase();
    if (value.contains('villa') || value.contains('house')) {
      return Icons.home_rounded;
    }
    if (value.contains('office')) return Icons.business_rounded;
    return Icons.apartment_rounded;
  }

  /// Known types in the app language; any other name as the provider wrote it.
  static String _propertyText(String type) => switch (type.toLowerCase()) {
    'villa' => 'svc_villa'.tr,
    'apartment' => 'svc_apartment'.tr,
    'office' => 'svc_office'.tr,
    _ => type,
  };

  Widget _propertyCard({required String type, required IconData icon}) {
    final selected = _propertyType == type;
    return GestureDetector(
      onTap: () => setState(() {
        // Property type is mandatory — switch between options, never clear.
        _propertyType = type;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3EB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFFF5216) : const Color(0xFFE8DFD6),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? const Color(0xFFFF5216)
                  : const Color(0xFFB0A59C),
              size: 20,
            ),
            const SizedBox(width: 10),
            Icon(
              icon,
              color: selected
                  ? const Color(0xFFFF5216)
                  : const Color(0xFF8A7E76),
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _propertyText(type),
                style: AppFonts.outfit(
                  color: selected
                      ? const Color(0xFFFF5216)
                      : const Color(0xFF1B2B4A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('svc_tell_us_home'.tr),
        const SizedBox(height: 12),
        _buildRoomRatesCard(),
      ],
    );
  }

  Widget _buildAreasToTreat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('svc_select_areas_to_treat'.tr),
        const SizedBox(height: 12),
        for (var i = 0; i < _roomRates.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _areaTreatCard(_roomRates[i]),
        ],
      ],
    );
  }

  Widget _buildRoomRatesCard() {
    return Container(
      width: double.infinity,
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
          for (var i = 0; i < _roomRates.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF0E8DF),
                indent: 16,
                endIndent: 16,
              ),
            _roomRateRow(_roomRates[i]),
          ],
        ],
      ),
    );
  }

  Widget _areaTreatCard(Map<String, Object> room) {
    final key = room['key'] as String;
    final rate = room['rate'] as int;
    final count = _roomCountFor(key);
    final lineTotal = count * rate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  room['display'] as String,
                  style: AppFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (room['unitLabel'] as String).trParams({'rate': '$rate'}),
                  style: AppFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _areaStepper(
            value: count,
            onMinus: () => _setRoomCount(key, count - 1),
            onPlus: () => _setRoomCount(key, count + 1),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              'mru'.trParams({'amount': '$lineTotal'}),
              textAlign: TextAlign.end,
              style: AppFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pest mock: minus/plus without beige pill wrapper
  Widget _areaStepper({
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperButton(
          icon: Icons.remove_rounded,
          filled: false,
          onTap: onMinus,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _stepperButton(icon: Icons.add_rounded, filled: true, onTap: onPlus),
      ],
    );
  }

  Widget _buildPestFacing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('svc_what_facing'.tr),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pestIssues.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final item = _pestIssues[index];
            final id = item['id'] as String;
            final selected = _selectedPests.contains(id);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedPests.remove(id);
                } else {
                  _selectedPests.add(id);
                }
              }),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFFF5216)
                        : const Color(0xFFEDE4DA),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFF0E6)
                            : const Color(0xFFE8F2FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: item['image'] != null
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                item['image'] as String,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.bug_report_outlined,
                                  size: 22,
                                  color: selected
                                      ? const Color(0xFFFF5216)
                                      : const Color(0xFF2B5A9E),
                                ),
                              ),
                            )
                          : Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFF5216)
                                      : const Color(0xFF1B2B4A),
                                  width: 1.6,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.north_east_rounded,
                                size: 14,
                                color: selected
                                    ? const Color(0xFFFF5216)
                                    : const Color(0xFF1B2B4A),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['display'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.outfit(
                        color: const Color(0xFF1B2B4A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  int _roomCountFor(String key) => _spaceQty[key] ?? 0;

  void _setRoomCount(String key, int value) {
    setState(() => _spaceQty[key] = value < 0 ? 0 : value);
  }

  Widget _roomRateRow(Map<String, Object> room) {
    final key = room['key'] as String;
    final rate = room['rate'] as int;
    final count = _roomCountFor(key);
    final lineTotal = count * rate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room['display'] as String,
                  style: AppFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (room['unitLabel'] as String).trParams({'rate': '$rate'}),
                  style: AppFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _pillStepper(
            value: count,
            onMinus: () => _setRoomCount(key, count - 1),
            onPlus: () => _setRoomCount(key, count + 1),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              'mru'.trParams({'amount': '$lineTotal'}),
              textAlign: TextAlign.end,
              style: AppFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillStepper({
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0E8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(
            icon: Icons.remove_rounded,
            filled: false,
            onTap: onMinus,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _stepperButton(icon: Icons.add_rounded, filled: true, onTap: onPlus),
        ],
      ),
    );
  }

  Widget _buildCleaningProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('svc_who_provides_products'.tr),
        const SizedBox(height: 12),
        _productOptionCard(
          id: 'self',
          title: 'svc_self_provides_products'.tr,
          description: 'svc_self_products_hint'.tr,
          priceLabel: 'mru'.trParams({'amount': '0'}),
          priceOrange: false,
        ),
        const SizedBox(height: 12),
        _productOptionCard(
          id: 'provider',
          title: 'svc_provider_provides_products'.tr,
          description: 'svc_provider_products_hint'.tr,
          priceLabel: 'svc_plus_mru'.trParams({'amount': '$_supplyFee'}),
          priceOrange: true,
        ),
      ],
    );
  }

  Widget _productOptionCard({
    required String id,
    required String title,
    required String description,
    required String priceLabel,
    required bool priceOrange,
  }) {
    final selected = _productsProvider == id;
    return GestureDetector(
      onTap: () => setState(() => _productsProvider = id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? const Color(0xFFFF5216) : const Color(0xFFEDE4DA),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF5216)
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
                        color: Color(0xFFFF5216),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.outfit(
                      color: const Color(0xFF1B2B4A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              priceLabel,
              style: AppFonts.outfit(
                color: priceOrange
                    ? const Color(0xFFFF5216)
                    : const Color(0xFF1B2B4A),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF5216) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: filled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? Colors.white : const Color(0xFFFF5216),
        ),
      ),
    );
  }

  Widget _buildSpecialNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('svc_special_notes'.tr),
        const SizedBox(height: 12),
        Container(
          height: 120,
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
          child: Stack(
            children: [
              TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AppFonts.outfit(
                  color: const Color(0xFF1B2B4A),
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  hintText: 'svc_notes_example_kitchen'.tr,
                  hintStyle: AppFonts.outfit(
                    color: const Color(0xFFB0A59C),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    16,
                    14,
                    52,
                    14,
                  ),
                ),
              ),
              PositionedDirectional(
                top: 10,
                end: 10,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0E6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'lib/assets/images/Voice.png',
                    width: 15,
                    height: 15,
                    color: const Color(0xFFFF5216),
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.settings_voice_rounded,
                      color: Color(0xFFFF5216),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitleWithOptional('svc_extra_clean'.tr),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
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
              for (var i = 0; i < _extraClean.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _extraCleanRow(_extraClean[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  int _extraCountFor(String key) => _addonQty[key] ?? 0;

  void _setExtraCount(String key, int value) {
    setState(() => _addonQty[key] = value < 0 ? 0 : value);
  }

  Widget _extraCleanRow(Map<String, Object> item) {
    final key = item['key'] as String;
    final rate = item['rate'] as int;
    final count = _extraCountFor(key);
    final lineTotal = count * rate;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
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
                  item['display'] as String,
                  style: AppFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (item['unitLabel'] as String).trParams({'rate': '$rate'}),
                  style: AppFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _pillStepper(
            value: count,
            onMinus: () => _setExtraCount(key, count - 1),
            onPlus: () => _setExtraCount(key, count + 1),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              'mru'.trParams({'amount': '$lineTotal'}),
              textAlign: TextAlign.end,
              style: AppFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'svc_total_upper'.tr,
                      style: AppFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'mru'.trParams({'amount': '$_totalPrice'}),
                      style: AppFonts.outfit(
                        color: const Color(0xFFFF5216),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openSlotAndGoToCart,
            child: Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5216), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5216).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'svc_choose_your_slot'.tr,
                style: AppFonts.outfit(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
