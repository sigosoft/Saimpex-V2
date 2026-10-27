import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_constants.dart';
import '../../models/food_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';

/// Group id for the item's extras; the API gives extras no option_group_id.
const int _extrasGroupId = -1;

const String _kFoodDescription =
    'Slow-cooked traditional Moroccan tagine with tender chicken, preserved lemons, olives, and aromatic spices. Served with a side of fluffy couscous.';

/// Full customize popup (opened from a card's ADD or the detail sheet).
/// Portions come from the item's `items` and option groups from `option_groups`.
Future<void> showFoodItemCustomizeSheet({
  required BuildContext context,
  required Map<String, dynamic> food,
  required Future<void> Function(
    BuildContext sheetContext, {
    required int variantId,
    required List<int> optionIds,
    required List<int> extraIds,
    required String portion,
    required int price,
    required int quantity,
  })
  onAddToCart,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) =>
        _FoodItemCustomizeSheet(food: food, onAddToCart: onAddToCart),
  );
}

List<Map<String, dynamic>> _mapsOf(dynamic raw) => raw is List
    ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];

int _intOf(dynamic value) => int.tryParse('${value ?? ''}') ?? 0;

/// Leading number of a price such as 100, "100.00" or "100.00 MRU".
int _priceOf(dynamic value) {
  final match = RegExp(r'\d+(\.\d+)?').firstMatch('${value ?? ''}');
  return match == null ? 0 : double.parse(match.group(0)!).round();
}

String _localizedText(Map<String, dynamic> map, String key) {
  for (final code in [apiLanguageCode(), 'en', 'fr', 'ar']) {
    final value = map['${key}_$code']?.toString().trim() ?? '';
    if (value.isNotEmpty && value != 'null') return value;
  }
  return '';
}

int _variantPrice(Map<String, dynamic> variant) {
  final discount = _priceOf(variant['discount_price']);
  return discount > 0 ? discount : _priceOf(variant['price']);
}

String _variantLabel(Map<String, dynamic>? variant) {
  if (variant == null) return 'Regular';
  final name = _localizedText(variant, 'variant_name');
  if (name.isNotEmpty) return name;
  final attribute = variant['attribute_value']?.toString().trim() ?? '';
  return attribute.isNotEmpty && attribute != 'null' ? attribute : 'Regular';
}

Widget _radio({required bool selected}) {
  return Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? const Color(0xFFFF5E00) : const Color(0xFFC8C2BC),
        width: 1.6,
      ),
    ),
    padding: const EdgeInsets.all(3.5),
    child: selected
        ? Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFF5E00),
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}

Widget _networkImage(
  String? url, {
  required double width,
  required double height,
  required BorderRadius radius,
}) {
  final fallback = Container(
    width: width,
    height: height,
    color: const Color(0xFFFFE8DC),
  );
  if (url == null || url.isEmpty) return fallback;
  return ClipRRect(
    borderRadius: radius,
    child: Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    ),
  );
}

/// Section title with a badge and a status pill on the right.
Widget _sectionHeader({
  required String title,
  required String badge,
  required String trailing,
  required bool trailingHighlight,
  bool badgeHighlight = true,
}) {
  final titleText = Text(
    title,
    maxLines: 1,
    softWrap: false,
    style: GoogleFonts.outfit(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF1A1A1A),
    ),
  );
  return LayoutBuilder(
    builder: (context, constraints) {
      // Pill = text + 10px padding on each side
      final pillsWidth =
          _textWidth(badge, 11, FontWeight.w600) +
          _textWidth(trailing, 11, FontWeight.w600) +
          40;
      final fitsOneRow =
          _textWidth(title, 15, FontWeight.w800) + 10 + pillsWidth <=
          constraints.maxWidth;
      if (fitsOneRow) {
        return Row(
          children: [
            titleText,
            const SizedBox(width: 10),
            _sectionPill(badge, highlight: badgeHighlight),
            const Spacer(),
            _sectionPill(trailing, highlight: trailingHighlight),
          ],
        );
      }
      // Too long for one row: scroll sideways so the whole title stays visible
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            titleText,
            const SizedBox(width: 10),
            _sectionPill(badge, highlight: badgeHighlight),
            const SizedBox(width: 10),
            _sectionPill(trailing, highlight: trailingHighlight),
          ],
        ),
      );
    },
  );
}

Widget _sectionPill(String text, {required bool highlight}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: highlight ? const Color(0xFFFFE8EC) : const Color(0xFFE6E6E6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: GoogleFonts.outfit(
        color: highlight ? const Color(0xFFE5484D) : const Color(0xFF1A1A1A),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget _portionCard({
  required String label,
  required String price,
  required bool selected,
  required String? image,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFFFF5E00) : Colors.transparent,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _networkImage(
            image,
            width: 42,
            height: 42,
            radius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  price,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _radio(selected: selected),
        ],
      ),
    ),
  );
}

class _FoodItemCustomizeSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final Future<void> Function(
    BuildContext sheetContext, {
    required int variantId,
    required List<int> optionIds,
    required List<int> extraIds,
    required String portion,
    required int price,
    required int quantity,
  })
  onAddToCart;

  const _FoodItemCustomizeSheet({
    required this.food,
    required this.onAddToCart,
  });

  @override
  State<_FoodItemCustomizeSheet> createState() =>
      _FoodItemCustomizeSheetState();
}

class _FoodItemCustomizeSheetState extends State<_FoodItemCustomizeSheet> {
  int _variantIndex = 0;
  int _quantity = 1;
  // Chosen option ids, keyed by option group id
  final Map<int, Set<int>> _selectedOptions = {};
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _qtyNoteController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _qtyNoteController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _raw {
    final raw = widget.food['raw'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  List<Map<String, dynamic>> get _variants => _mapsOf(_raw['items']);

  /// Option groups from the API, then the item's extras as one more group.
  List<Map<String, dynamic>> get _optionGroups => [
    for (final group in _mapsOf(_raw['option_groups'])) _withIds(group),
    ?_extrasGroup,
  ];

  /// Option groups and options come as `id` in the list response, but the
  /// selection code reads `option_group_id` / `option_id`. Without these keys
  /// every option reads as id 0, so picking one looks like picking them all.
  Map<String, dynamic> _withIds(Map<String, dynamic> group) => {
    ...group,
    'option_group_id': group['option_group_id'] ?? group['id'],
    'options': [
      for (final option in _mapsOf(group['options']))
        {...option, 'option_id': option['option_id'] ?? option['id']},
    ],
  };

  /// The API `extras` block shaped like an option group, so it reuses the
  /// same selection, pricing and rendering as the other groups.
  Map<String, dynamic>? get _extrasGroup {
    final extras = _raw['extras'];
    if (extras is! Map) return null;
    final items = _mapsOf(extras['items']);
    if (items.isEmpty) return null;
    return {
      'option_group_id': _extrasGroupId,
      'name': 'Add Extras',
      'selection_requirement': 'optional',
      'min_selections': 0,
      'max_selections': extras['max_selections'] ?? 0,
      'options': [
        for (final item in items)
          {
            'option_id': item['id'],
            'name': item['name'],
            'additional_price': item['additional_price'],
            'image': item['image'],
          },
      ],
    };
  }

  Map<String, dynamic>? get _selectedVariant {
    final variants = _variants;
    if (variants.isEmpty) return null;
    return variants[_variantIndex.clamp(0, variants.length - 1)];
  }

  Set<int> _chosen(Map<String, dynamic> group) =>
      _selectedOptions[_intOf(group['option_group_id'])] ?? <int>{};

  int get _unitPrice {
    final variant = _selectedVariant;
    var total = variant == null
        ? _priceOf(widget.food['price'])
        : _variantPrice(variant);
    for (final group in _optionGroups) {
      final chosen = _chosen(group);
      for (final option in _mapsOf(group['options'])) {
        if (chosen.contains(_intOf(option['option_id']))) {
          total += _priceOf(option['additional_price']);
        }
      }
    }
    return total;
  }

  Map<String, dynamic>? _missingRequiredGroup() {
    for (final group in _optionGroups) {
      final min = _intOf(group['min_selections']);
      if (min > 0 && _chosen(group).length < min) return group;
    }
    return null;
  }

  void _toggleOption(Map<String, dynamic> group, int optionId) {
    final groupId = _intOf(group['option_group_id']);
    final max = _intOf(group['max_selections']);
    final chosen = {..._chosen(group)};
    setState(() {
      if (max == 1) {
        _selectedOptions[groupId] = {optionId};
      } else if (chosen.remove(optionId)) {
        _selectedOptions[groupId] = chosen;
      } else if (max <= 0 || chosen.length < max) {
        chosen.add(optionId);
        _selectedOptions[groupId] = chosen;
      }
    });
  }

  /// Portions follow the item's own stock (has_stock, then stock).
  bool _variantInStock(Map<String, dynamic> variant) =>
      FoodRepository.itemInStock(_raw);

  String _variantPriceLabel(Map<String, dynamic> variant) =>
      _variantInStock(variant)
      ? '${_variantPrice(variant)} MRU'
      : 'Out of stock';

  void _selectVariant(int index) {
    if (!_variantInStock(_variants[index])) {
      showAppToast('This portion is out of stock');
      return;
    }
    setState(() => _variantIndex = index);
  }

  @override
  void initState() {
    super.initState();
    // Start on the first portion that can be ordered
    final index = _variants.indexWhere(_variantInStock);
    if (index > 0) _variantIndex = index;
  }

  void _addToCart() {
    final selected = _selectedVariant;
    if (selected != null && !_variantInStock(selected)) {
      showAppToast('This portion is out of stock');
      return;
    }
    final missing = _missingRequiredGroup();
    if (missing != null) {
      showAppToast('Please choose ${missing['name'] ?? 'an option'}');
      return;
    }
    // Option groups and extras are sent under different keys (option_ids / extra_ids)
    final optionIds = [
      for (final group in _optionGroups)
        if (_intOf(group['option_group_id']) != _extrasGroupId)
          ..._chosen(group),
    ];
    final extraIds = [
      for (final group in _optionGroups)
        if (_intOf(group['option_group_id']) == _extrasGroupId)
          ..._chosen(group),
    ];
    widget.onAddToCart(
      context,
      variantId: _intOf(_selectedVariant?['item_id']),
      optionIds: optionIds,
      extraIds: extraIds,
      portion: _variantLabel(_selectedVariant),
      price: _unitPrice,
      quantity: _quantity,
    );
  }

  Widget _portionSection(String? image) {
    final variants = _variants;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Choose Your Portion',
          badge: 'Mandatory',
          trailing: 'Select 1',
          trailingHighlight: false,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Room for the full name: image, text, radio and padding
            final needed = [
              for (final variant in variants)
                _textWidth(_variantLabel(variant), 13, FontWeight.w700) + 120,
            ];
            final half = (constraints.maxWidth - 10) / 2;
            final sideBySide =
                variants.length <= 2 && needed.every((width) => width <= half);
            if (sideBySide) {
              return Row(
                children: [
                  for (var i = 0; i < variants.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _portionCard(
                        label: _variantLabel(variants[i]),
                        price: _variantPriceLabel(variants[i]),
                        selected: _variantIndex == i,
                        image: image,
                        onTap: () => _selectVariant(i),
                      ),
                    ),
                  ],
                ],
              );
            }
            return SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: variants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => SizedBox(
                  width: needed[i] > 180 ? needed[i] : 180,
                  child: _portionCard(
                    label: _variantLabel(variants[i]),
                    price: _variantPriceLabel(variants[i]),
                    selected: _variantIndex == i,
                    image: image,
                    onTap: () => _selectVariant(i),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _optionGroupSection(Map<String, dynamic> group) {
    final options = _mapsOf(group['options']);
    final min = _intOf(group['min_selections']);
    final max = _intOf(group['max_selections']);
    final required = min > 0 || group['selection_requirement'] == 'required';
    // Extras always list as rows (as in the design); other single-choice groups are cards
    final isExtras = _intOf(group['option_group_id']) == _extrasGroupId;
    final single = max == 1 && !isExtras;
    final trailing = required
        ? 'Min ${min > 0 ? min : 1} required'
        : single
        ? 'Select 1'
        : 'Max ${max > 0 ? max : options.length} items';
    final chosen = _chosen(group);

    Widget optionCard(Map<String, dynamic> option) {
      final id = _intOf(option['option_id']);
      final price = _priceOf(option['additional_price']);
      final name = option['name']?.toString() ?? '';
      final image = ApiConstants.mediaUrl(option['image']?.toString());
      return single
          ? _sideCardFor(name, price, image, chosen.contains(id), () {
              _toggleOption(group, id);
            })
          : Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _extraRowFor(name, price, image, chosen.contains(id), () {
                _toggleOption(group, id);
              }),
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: group['name']?.toString() ?? '',
          badge: required ? 'Mandatory' : 'Optional',
          badgeHighlight: required,
          trailing: trailing,
          trailingHighlight: required,
        ),
        const SizedBox(height: 12),
        if (single)
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => optionCard(options[index]),
            ),
          )
        else
          for (final option in options) optionCard(option),
      ],
    );
  }

  Widget _sideCardFor(
    String name,
    int price,
    String? image,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _sideCardWidth(name),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _networkImage(
                  image,
                  width: 110,
                  height: 96,
                  radius: BorderRadius.circular(16),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _radio(selected: selected),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              price > 0 ? '+ $price MRU' : 'Included',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _extraRowFor(
    String name,
    int price,
    String? image,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _networkImage(
              image,
              width: 48,
              height: 48,
              radius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price > 0 ? '+$price MRU' : 'Included',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _radio(selected: selected),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final image = food['image']?.toString() ?? '';
    const closeSize = 44.0;
    const closeGap = 12.0; // space between close button and sheet top
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.90;

    return SizedBox(
      height: sheetHeight + closeSize + closeGap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Sheet sits fully below the close button (gap above container)
          Positioned(
            top: closeSize + closeGap,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Color(0xFFFDF8F1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full-bleed hero — flush to top/left/right, no padding
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 210,
                                child: Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: const Color(0xFFFFE8DC)),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: -42,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              food['title']?.toString() ?? '',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFF1A1A1A),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFFFAE00),
                                            size: 15,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            food['rating']?.toString() ?? '4.6',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            ' (${food['reviews'] ?? '10k + reviews'})',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF7A6A60),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _kFoodDescription,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF7A6A60),
                                          fontSize: 11.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 58),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_variants.isNotEmpty) ...[
                                  _portionSection(image),
                                  const SizedBox(height: 12),
                                ],
                                Container(
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(23),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: TextField(
                                    controller: _qtyNoteController,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Customize your quantity here',
                                      hintStyle: GoogleFonts.outfit(
                                        color: const Color(0xFFA59A94),
                                        fontSize: 13,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                for (final group in _optionGroups) ...[
                                  const SizedBox(height: 22),
                                  _optionGroupSection(group),
                                ],
                                const SizedBox(height: 10),
                                Text(
                                  'Add Order Notes',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        12,
                                        48,
                                        12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: TextField(
                                        controller: _notesController,
                                        maxLines: 3,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              'Add notes (e.g., no onions, extra spicy...)',
                                          hintStyle: GoogleFonts.outfit(
                                            color: const Color(0xFFA59A94),
                                            fontSize: 13,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      bottom: 10,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF5E00),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.mic_none_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sticky footer — qty + gradient ADD
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 14 + bottomPad),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9F1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.remove,
                                    color: Color(0xFFFF5E00),
                                    size: 16,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Text(
                                  '$_quantity',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _quantity++),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF5E00),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _addToCart,
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
                                    ).withValues(alpha: 0.32),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ADD',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
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
                ],
              ),
            ),
          ),
          // Close button — centered above the sheet with clear gap
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: closeSize,
                  height: closeSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFFFF5E00),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Side cards are 110 wide, widened when the option name needs more room.
double _sideCardWidth(String name) {
  final textWidth = _textWidth(name, 12, FontWeight.w600) + 2;
  return textWidth > 110 ? textWidth : 110;
}

/// Width of one line of text in the app's font, so rows can fit it.
double _textWidth(String text, double fontSize, FontWeight weight) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: GoogleFonts.outfit(fontSize: fontSize, fontWeight: weight),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width;
}
