import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacyProductCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final bool isNotAccepting;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const PharmacyProductCard({
    super.key,
    required this.food,
    required this.isNotAccepting,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      food['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF3EFEA),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E00),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        food['discount']!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food['title']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      food['tag']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFAE00),
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${food['rating']!} (${food['reviews']})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food['originalPrice']!,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFA59A94),
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: const Color(0xFFA59A94),
                                ),
                              ),
                              Text(
                                food['price']!,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: isNotAccepting
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Pharmacy is currently closed or temporarily not accepting orders.',
                                        style: GoogleFonts.outfit(),
                                      ),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              : onAdd,
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isNotAccepting
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF5E00,
                                        ).withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isNotAccepting ? 'CLOSED' : 'ADD',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
