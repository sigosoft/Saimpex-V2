import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

void showPharmacyCustomizeSheet(
  BuildContext context, {
  required Map<String, dynamic> food,
  required bool fromBottomSheet,
  required Future<bool> Function(
    Map<String, dynamic> item,
    String portion,
    int quantity,
  )
  onAdded,
}) {
  int selectedQuantityIndex = 0; // Default to option 1
  int quantity = 1;
  var adding = false;
  final quantityController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  int? readLimit(dynamic value) {
    final number = value is int ? value : int.tryParse('$value');
    if (number == null || number < 1) return null;
    return number;
  }

  final maxQuantity =
      readLimit(food['quantityAllowed']) ?? readLimit(food['stock']);

  final title = food['title'] as String;

  // The item API has one price per product, so only that pack is offered.
  // Extra pack sizes need pack-size data from the backend first.
  final portion = '${food['portion'] ?? ''}'.trim();
  final String qtyText1 = portion.isEmpty ? '1 Pack' : portion;
  final String qtyPrice1 = '${food['price'] ?? '0 MRU'}';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
                      title,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                            // Quantity Section
                            Text(
                              'pw_quantity'.tr,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                // Option 1
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        selectedQuantityIndex = 0;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selectedQuantityIndex == 0
                                            ? const Color(0xFFFFF0EA)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: selectedQuantityIndex == 0
                                              ? const Color(0xFFFF5E00)
                                              : const Color(0xFFEAD8C9),
                                          width: selectedQuantityIndex == 0
                                              ? 1.5
                                              : 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Radio dot
                                          Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    selectedQuantityIndex == 0
                                                    ? const Color(0xFFFF5E00)
                                                    : const Color(0xFFA59A94),
                                                width: 1.5,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(3),
                                            child: selectedQuantityIndex == 0
                                                ? Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFFFF5E00,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
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
                                                portion.isEmpty
                                                    ? 'pw_one_pack'.tr
                                                    : portion,
                                                style: GoogleFonts.outfit(
                                                  color: const Color(
                                                    0xFF2C2520,
                                                  ),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                qtyPrice1,
                                                style: GoogleFonts.outfit(
                                                  color: const Color(
                                                    0xFFFF5E00,
                                                  ),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
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
                            const SizedBox(height: 16),

                            // Customize quantity field
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              alignment: AlignmentDirectional.centerStart,
                              child: TextField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF2C2520),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'pw_customize_quantity'.tr,
                                  hintStyle: GoogleFonts.outfit(
                                    color: const Color(0xFFA59A94),
                                    fontSize: 12,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  final parsed = int.tryParse(value.trim());
                                  if (parsed == null || parsed < 1) return;
                                  final next =
                                      maxQuantity != null &&
                                          parsed > maxQuantity
                                      ? maxQuantity
                                      : parsed;
                                  setModalState(() => quantity = next);
                                  if (next == parsed) return;
                                  quantityController.value = TextEditingValue(
                                    text: '$next',
                                    selection: TextSelection.collapsed(
                                      offset: '$next'.length,
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Add Order Notes Section
                            Text(
                              'pw_add_order_notes'.tr,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                        hintText: 'pw_add_notes_hint'.trParams({
                                          'item': title.toLowerCase(),
                                        }),
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

                    // Bottom actions bar
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        24 + bottomPadding,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFEAD8C9), width: 0.8),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Quantity Counter
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
                                      setModalState(() {
                                        quantity--;
                                      });
                                      quantityController.text = '$quantity';
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    if (maxQuantity != null &&
                                        quantity >= maxQuantity) {
                                      return;
                                    }
                                    setModalState(() {
                                      quantity++;
                                    });
                                    quantityController.text = '$quantity';
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Color(0xFFFF5E00),
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
                              onTap: () async {
                                if (adding) return;
                                adding = true;
                                var added = false;
                                try {
                                  added = await onAdded(
                                    Map<String, dynamic>.from(food)
                                      ..['price'] = qtyPrice1,
                                    qtyText1,
                                    quantity,
                                  );
                                } finally {
                                  adding = false;
                                }
                                if (!context.mounted || !added) return;
                                Navigator.pop(context);
                                if (fromBottomSheet && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5E00),
                                      Color(0xFFFFAE00),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF5E00,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
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
                                      'pw_add_caps'.tr,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
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
                top: -56,
                left: 0,
                right: 0,
                child: Center(
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
              ),
            ],
          );
        },
      );
    },
  );
}
