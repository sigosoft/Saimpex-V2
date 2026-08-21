import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showPharmacyProductDetailsSheet(
  BuildContext context, {
  required Map<String, dynamic> food,
  required bool isNotAccepting,
  required VoidCallback onAdd,
}) {
  bool isLiked = false;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final description =
        (food['description'] as String?) ??
        'Premium quality medical grade products sourced directly from licensed distributors, ensuring safety, effectiveness, and clean packaging.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomSafe),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8F3),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 10,
                                    child: Image.network(
                                      food['image']!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: const Color(0xFFF3EFEA),
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.grey,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    16,
                                    20,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food['title']!,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        food['tag']!,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFA59A94),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            food['price']!,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFFF5E00),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            food['originalPrice']!,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFA59A94),
                                              fontSize: 13,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor: const Color(
                                                0xFFA59A94,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFFFAE00),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${food['rating']!} (${food['reviews']!})',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF2C2520),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        description,
                                        textAlign: TextAlign.justify,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF7A6A60),
                                          fontSize: 12,
                                          height: 1.55,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: isNotAccepting
                                      ? () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Pharmacy is currently closed or temporarily not accepting orders.',
                                                style: GoogleFonts.outfit(),
                                              ),
                                              backgroundColor: const Color(
                                                0xFFEF4444,
                                              ),
                                            ),
                                          );
                                        }
                                      : () {
                                          Navigator.pop(context);
                                          onAdd();
                                        },
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: isNotAccepting
                                          ? null
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFFFF5E00),
                                                Color(0xFFFFAE00),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                      color: isNotAccepting
                                          ? const Color(0xFFA59A94)
                                          : null,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: isNotAccepting
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFFF5E00,
                                                ).withOpacity(0.28),
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
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isNotAccepting ? 'CLOSED' : 'ADD',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    isLiked = !isLiked;
                                  });
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFEAD8C9),
                                      width: 0.8,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
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
                                        ? const Color(0xFFFF5E00)
                                        : const Color(0xFFA59A94),
                                    size: 20,
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
                    top: -52,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 10,
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
              ),
            );
          },
        );
      },
    );

}
