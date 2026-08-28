import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef ExpressProductAddedCallback = void Function(
  Map<String, dynamic> product,
  String portion,
  String price,
);

void showExpressProductDetailSheet(
  BuildContext context, {
  required Map<String, dynamic> product,
  required ExpressProductAddedCallback onAdded,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      var isLiked = false;

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 56),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFDF9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: Image.network(
                        product['image'].toString(),
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 240,
                          color: const Color(0xFFF3EFEA),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['title'].toString(),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 18,
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
                              (product['tag'] ?? 'Fresh').toString(),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                product['price'].toString(),
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (product['originalPrice'] ?? '100 MRU')
                                    .toString(),
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFA59A94),
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: const Color(0xFFA59A94),
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
                                '${product['rating']} (${product['reviews']})',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFA59A94),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            (product['description'] ??
                                    'Premium quality fresh product sourced directly from local producers, ensuring high nutritional value and clean packaging.')
                                .toString(),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF7A6A60),
                              fontSize: 12,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    showExpressProductCustomizeSheet(
                                      context,
                                      product: product,
                                      onAdded: onAdded,
                                    );
                                  },
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF5E00),
                                          Color(0xFFFFAE00),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(23),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.shopping_cart_outlined,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ADD',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() => isLiked = !isLiked);
                                },
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFEAD8C9),
                                      width: 0.8,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isLiked
                                        ? const Color(0xFFE03A3A)
                                        : const Color(0xFF2C2520),
                                    size: 20,
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
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(sheetContext),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
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

void showExpressProductCustomizeSheet(
  BuildContext context, {
  required Map<String, dynamic> product,
  required ExpressProductAddedCallback onAdded,
}) {
  var selectedQuantityIndex = 0;
  var quantity = 1;
  final notesController = TextEditingController();

  final title = product['title'].toString();
  final displayTitle = title.replaceAll(RegExp(r'\s*\d+\s*[kKgGlL]+'), '').trim();

  var qtyText1 = '1 Kg';
  var qtyPrice1 = product['price']?.toString() ?? '50 MRU';
  var qtyText2 = '5 Kg';
  var qtyPrice2 = '550 MRU';

  if (title.contains('Milk')) {
    qtyText1 = '1 L';
    qtyPrice1 = '50 MRU';
    qtyText2 = '5 L';
    qtyPrice2 = '220 MRU';
  } else if (title.contains('Banana')) {
    qtyText2 = '3 Kg';
    qtyPrice2 = '140 MRU';
  }

  final noteHint = displayTitle.toLowerCase();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 56),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFDF9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      displayTitle.isEmpty ? title : displayTitle,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFEAD8C9), height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _quantityOption(
                                    qtyText1,
                                    qtyPrice1,
                                    selectedQuantityIndex == 0,
                                    () => setModalState(
                                      () => selectedQuantityIndex = 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _quantityOption(
                                    qtyText2,
                                    qtyPrice2,
                                    selectedQuantityIndex == 1,
                                    () => setModalState(
                                      () => selectedQuantityIndex = 1,
                                    ),
                                    dimPrice: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.centerLeft,
                              child: TextField(
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF2C2520),
                                ),
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
                            const SizedBox(height: 24),
                            Text(
                              'Add Order Notes',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEAD8C9),
                                  width: 0.8,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: notesController,
                                      maxLines: 1,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: const Color(0xFF2C2520),
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Add notes (e.g. fresh $noteHint only...)',
                                        hintStyle: GoogleFonts.outfit(
                                          color: const Color(0xFFA59A94),
                                          fontSize: 12,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF0EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mic_none_rounded,
                                      color: Color(0xFFFF5E00),
                                      size: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFEAD8C9), width: 0.8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0EA),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (quantity > 1) {
                                      setModalState(() => quantity--);
                                    }
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
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
                                const SizedBox(width: 12),
                                Text(
                                  quantity.toString(),
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() => quantity++);
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final portion = selectedQuantityIndex == 0
                                    ? qtyText1
                                    : qtyText2;
                                final price = selectedQuantityIndex == 0
                                    ? qtyPrice1
                                    : qtyPrice2;
                                Navigator.pop(sheetContext);
                                onAdded(
                                  Map<String, dynamic>.from(product),
                                  portion,
                                  price,
                                );
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5E00),
                                      Color(0xFFFFAE00),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
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
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ADD',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 13,
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
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(sheetContext),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
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

Widget _quantityOption(
  String label,
  String price,
  bool isSelected,
  VoidCallback onTap, {
  bool dimPrice = false,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF0EA) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFF5E00)
              : const Color(0xFFEAD8C9),
          width: isSelected ? 1.5 : 0.8,
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
                color: isSelected
                    ? const Color(0xFFFF5E00)
                    : const Color(0xFFA59A94),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: isSelected
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: GoogleFonts.outfit(
                  color: dimPrice && !isSelected
                      ? const Color(0xFFA59A94)
                      : const Color(0xFFFF5E00),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
