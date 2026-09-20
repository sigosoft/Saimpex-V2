import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef RestaurantAddToCartCallback = Future<void> Function(
  BuildContext context,
  Map<String, dynamic> food, {
  bool fromBottomSheet,
});

void showRestaurantFoodCustomizeSheet(
  BuildContext context, {
  required Map<String, dynamic> food,
  required bool fromBottomSheet,
  required RestaurantAddToCartCallback onAddToCart,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _RestaurantFoodCustomizeSheet(
        food: food,
        fromBottomSheet: fromBottomSheet,
        onAddToCart: onAddToCart,
      );
    },
  );
}

class _RestaurantFoodCustomizeSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final bool fromBottomSheet;
  final RestaurantAddToCartCallback onAddToCart;

  const _RestaurantFoodCustomizeSheet({
    required this.food,
    required this.fromBottomSheet,
    required this.onAddToCart,
  });

  @override
  State<_RestaurantFoodCustomizeSheet> createState() =>
      _RestaurantFoodCustomizeSheetState();
}

class _RestaurantFoodCustomizeSheetState
    extends State<_RestaurantFoodCustomizeSheet> {
  static const _closeSize = 44.0;
  static const _closeOverlap = _closeSize / 2;

  int _selectedPortion = 1;
  int? _selectedSide;
  final Set<int> _selectedExtras = {};
  int _quantity = 1;
  final TextEditingController _customQtyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _customQtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _sides => [
        {
          'name': 'Moroccan Rice',
          'price': 80,
          'image': widget.food['image'],
        },
        {
          'name': 'Brown Rice',
          'price': 80,
          'image': widget.food['image'],
        },
        {
          'name': 'Couscous',
          'price': 90,
          'image': widget.food['image'],
        },
      ];

  List<Map<String, dynamic>> get _extras => [
        {'name': 'Garlic Sauce', 'price': 20, 'image': widget.food['image']},
        {'name': 'French Fries', 'price': 50, 'image': widget.food['image']},
        {'name': 'Soft Drink', 'price': 50, 'image': widget.food['image']},
        {
          'name': 'Side of Olives',
          'price': 30,
          'image': widget.food['image'],
        },
      ];

  Widget _radio(bool selected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFFFF5E00) : const Color(0xFFC8C2BC),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(4),
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

  Widget _foodThumb(String url, {double size = 44}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: const Color(0xFFFFE8DC),
          child: const Icon(Icons.restaurant, color: Color(0xFFFF5E00)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final imageUrl = food['image']!.toString();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _closeOverlap),
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.92,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFDF9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          child: Image.network(
                            imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          food['title']!.toString(),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFFFAE00),
                                            size: 16,
                                          ),
                                          Text(
                                            '${food['rating']} (${food['reviews']})',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF7A6A60),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Slow-cooked traditional Moroccan tagine with tender chicken, preserved lemons, olives, and aromatic spices. Served with a side of fluffy couscous.',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF7A6A60),
                                      fontSize: 12,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Choose Your Portion'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _portionCard(
                                      imageUrl: imageUrl,
                                      label: 'Half',
                                      price: '375 MRU',
                                      selected: _selectedPortion == 0,
                                      onTap: () =>
                                          setState(() => _selectedPortion = 0),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _portionCard(
                                      imageUrl: imageUrl,
                                      label: 'Full',
                                      price: '750 MRU',
                                      selected: _selectedPortion == 1,
                                      onTap: () =>
                                          setState(() => _selectedPortion = 1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 46,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(23),
                                  border: Border.all(
                                    color: const Color(0xFFEAD8C9),
                                    width: 0.8,
                                  ),
                                ),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: _customQtyController,
                                  style: GoogleFonts.outfit(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Customize your quantity here',
                                    hintStyle: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _sectionTitle('Choose Your Side'),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 130,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _sides.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final side = _sides[index];
                                    final selected = _selectedSide == index;
                                    return GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedSide = index,
                                      ),
                                      child: SizedBox(
                                        width: 100,
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                _foodThumb(
                                                  side['image'].toString(),
                                                  size: 88,
                                                ),
                                                Positioned(
                                                  top: 6,
                                                  right: 6,
                                                  child: _radio(selected),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              side['name'].toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF2C2520),
                                              ),
                                            ),
                                            Text(
                                              '+ ${side['price']} MRU',
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFFF5E00),
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
                              _sectionTitle('Add Extras'),
                              const SizedBox(height: 10),
                              ...List.generate(_extras.length, (index) {
                                final extra = _extras[index];
                                final selected =
                                    _selectedExtras.contains(index);
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFEAD8C9),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _foodThumb(
                                          extra['image'].toString(),
                                          size: 40,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                extra['name'].toString(),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      const Color(0xFF2C2520),
                                                ),
                                              ),
                                              Text(
                                                '+${extra['price']} MRU',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      const Color(0xFFFF5E00),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _radio(selected),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                              _sectionTitle('Add Order Notes'),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFEAD8C9),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _notesController,
                                        maxLines: 3,
                                        style: GoogleFonts.outfit(fontSize: 12),
                                        decoration: InputDecoration(
                                          hintText:
                                              'Add notes (e.g., no onions, extra spicy...)',
                                          hintStyle: GoogleFonts.outfit(
                                            color: const Color(0xFFA59A94),
                                            fontSize: 12,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFF0E0),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.mic_none_rounded,
                                        color: Color(0xFFFF5E00),
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EA),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            _qtyCircle(
                              icon: Icons.remove,
                              filled: false,
                              onTap: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                '$_quantity',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2C2520),
                                ),
                              ),
                            ),
                            _qtyCircle(
                              icon: Icons.add,
                              filled: true,
                              onTap: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onAddToCart(
                            context,
                            food,
                            fromBottomSheet: widget.fromBottomSheet,
                          ),
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
                                      .withValues(alpha: 0.3),
                                  blurRadius: 10,
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
                                    fontSize: 14,
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
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: _closeSize,
              height: _closeSize,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5EC),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFFFF5E00),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: const Color(0xFF2C2520),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _portionCard({
    required String imageUrl,
    required String label,
    required String price,
    required bool selected,
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
                : const Color(0xFFEAD8C9),
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            _foodThumb(imageUrl, size: 40),
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
                      color: const Color(0xFF2C2520),
                    ),
                  ),
                  Text(
                    price,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF5E00),
                    ),
                  ),
                ],
              ),
            ),
            _radio(selected),
          ],
        ),
      ),
    );
  }

  Widget _qtyCircle({
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF5E00) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : const Color(0xFFFF5E00),
        ),
      ),
    );
  }
}
