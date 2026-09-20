import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const String _kFoodDescription =
    'Slow-cooked traditional Moroccan tagine with tender chicken, preserved lemons, olives, and aromatic spices. Served with a side of fluffy couscous.';

/// Simple item detail popup (tap on a food card).
Future<void> showFoodItemDetailSheet({
  required BuildContext context,
  required Map<String, dynamic> food,
  required Future<void> Function() onOpenCustomize,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) => _FoodItemDetailSheet(
      food: food,
      onOpenCustomize: onOpenCustomize,
    ),
  );
}

/// Full customize popup (opened from detail via ADD or scroll-up).
Future<void> showFoodItemCustomizeSheet({
  required BuildContext context,
  required Map<String, dynamic> food,
  required Future<void> Function(BuildContext sheetContext) onAddToCart,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) => _FoodItemCustomizeSheet(
      food: food,
      onAddToCart: onAddToCart,
    ),
  );
}

class _FoodItemDetailSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final Future<void> Function() onOpenCustomize;

  const _FoodItemDetailSheet({
    required this.food,
    required this.onOpenCustomize,
  });

  @override
  State<_FoodItemDetailSheet> createState() => _FoodItemDetailSheetState();
}

class _FoodItemDetailSheetState extends State<_FoodItemDetailSheet> {
  bool _openedCustomize = false;
  int _quantity = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_openedCustomize || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Only when user overscrolls past the end
    if (pos.outOfRange && pos.pixels > pos.maxScrollExtent + 48) {
      _openCustomize();
    }
  }

  Future<void> _openCustomize() async {
    if (_openedCustomize || !mounted) return;
    setState(() => _openedCustomize = true);
    // Keep detail underneath — dismissing customize returns here
    await widget.onOpenCustomize();
    if (mounted) {
      setState(() => _openedCustomize = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final screenH = MediaQuery.sizeOf(context).height;
    const closeSize = 44.0;
    const closeGap = 12.0; // space between close button and sheet top
    final sheetHeight = screenH * 0.72;

    return SizedBox(
      height: sheetHeight + closeSize + closeGap,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (_openedCustomize) return false;
          if (notification is OverscrollNotification &&
              notification.overscroll < -20) {
            _openCustomize();
          }
          return false;
        },
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
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Full-bleed top image — no padding, flush to edges
                            SizedBox(
                              width: double.infinity,
                              height: 220,
                              child: Image.network(
                                food['image']?.toString() ?? '',
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFFFE8DC),
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Color(0xFFFF5E00),
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food['title']?.toString() ?? '',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5E00),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      food['tag']?.toString() ?? 'Spicy',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        food['price']?.toString() ?? '',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFFF5E00),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        food['originalPrice']?.toString() ?? '',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFA59A94),
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor:
                                              const Color(0xFFA59A94),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFFFAE00),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${food['rating'] ?? '4.6'} (${food['reviews'] ?? '10k + reviews'})',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF7A6A60),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _kFoodDescription,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF7A6A60),
                                      fontSize: 13,
                                      height: 1.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      'Swipe up to customize',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFA59A94),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
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
                    // Bottom bar: qty stepper + gradient ADD (matches design)
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
                              onTap: _openCustomize,
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
                                      color: const Color(0xFFFF5E00)
                                          .withValues(alpha: 0.32),
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
      ),
    );
  }
}

class _FoodItemCustomizeSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final Future<void> Function(BuildContext sheetContext) onAddToCart;

  const _FoodItemCustomizeSheet({
    required this.food,
    required this.onAddToCart,
  });

  @override
  State<_FoodItemCustomizeSheet> createState() =>
      _FoodItemCustomizeSheetState();
}

class _FoodItemCustomizeSheetState extends State<_FoodItemCustomizeSheet> {
  int _portionIndex = 0;
  int _sideIndex = 0;
  int _quantity = 1;
  final Set<int> _selectedExtras = {};
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _qtyNoteController = TextEditingController();

  static const _sides = [
    {
      'name': 'Moroccan Rice',
      'price': 80,
      'image':
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=300&auto=format&fit=crop',
    },
    {
      'name': 'Brown Rice',
      'price': 80,
      'image':
          'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=300&auto=format&fit=crop',
    },
    {
      'name': 'White Rice',
      'price': 80,
      'image':
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300&auto=format&fit=crop',
    },
    {
      'name': 'Couscous',
      'price': 70,
      'image':
          'https://images.unsplash.com/photo-1604908177636-96162fed2c86?w=300&auto=format&fit=crop',
    },
  ];

  static const _extras = [
    {
      'name': 'Garlic Sauce',
      'price': 20,
      'image':
          'https://images.unsplash.com/photo-1472476443507-c7a5948772fc?w=200&auto=format&fit=crop',
    },
    {
      'name': 'French Fries',
      'price': 50,
      'image':
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=200&auto=format&fit=crop',
    },
    {
      'name': 'Extra Cheese',
      'price': 40,
      'image':
          'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=200&auto=format&fit=crop',
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _qtyNoteController.dispose();
    super.dispose();
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
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFFFE8DC),
                                  ),
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
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
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
                          Text(
                            'Choose Your Portion',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _portionCard(
                                  label: 'Half',
                                  price: '375 MRU',
                                  selected: _portionIndex == 0,
                                  image: image,
                                  onTap: () =>
                                      setState(() => _portionIndex = 0),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _portionCard(
                                  label: 'Full',
                                  price: '750 MRU',
                                  selected: _portionIndex == 1,
                                  image: image,
                                  onTap: () =>
                                      setState(() => _portionIndex = 1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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

                          const SizedBox(height: 22),
                          Text(
                            'Choose Your Side',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 148,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _sides.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final side = _sides[index];
                                final selected = _sideIndex == index;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _sideIndex = index),
                                  child: SizedBox(
                                    width: 110,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.network(
                                                side['image'] as String,
                                                width: 110,
                                                height: 96,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  width: 110,
                                                  height: 96,
                                                  color:
                                                      const Color(0xFFFFE8DC),
                                                ),
                                              ),
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
                                                      color: Colors.black
                                                          .withValues(
                                                        alpha: 0.12,
                                                      ),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                alignment: Alignment.center,
                                                child: _radio(
                                                  selected: selected,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          side['name'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '+ ${side['price']} MRU',
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
                              },
                            ),
                          ),

                          const SizedBox(height: 18),
                          Text(
                            'Add Extras',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_extras.length, (index) {
                            final extra = _extras[index];
                            final selected = _selectedExtras.contains(index);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedExtras.remove(index);
                                  } else {
                                    _selectedExtras.add(index);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        extra['image'] as String,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          width: 48,
                                          height: 48,
                                          color: const Color(0xFFFFE8DC),
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
                                            extra['name'] as String,
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '+${extra['price']} MRU',
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
                          }),

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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
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
                            onTap: () => widget.onAddToCart(context),
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
                                    color: const Color(0xFFFF5E00)
                                        .withValues(alpha: 0.32),
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

  Widget _portionCard({
    required String label,
    required String price,
    required bool selected,
    required String image,
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
            color: selected
                ? const Color(0xFFFF5E00)
                : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                image,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 42,
                  height: 42,
                  color: const Color(0xFFFFE8DC),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
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
}
