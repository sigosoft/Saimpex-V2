import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centered dialog shown when adding an item from a different restaurant
/// than the one already in the cart.
class ReplaceCartItemDialog extends StatelessWidget {
  final String currentCartRestaurant;
  final String newRestaurant;

  const ReplaceCartItemDialog({
    super.key,
    required this.currentCartRestaurant,
    required this.newRestaurant,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String currentCartRestaurant,
    required String newRestaurant,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => ReplaceCartItemDialog(
        currentCartRestaurant: currentCartRestaurant,
        newRestaurant: newRestaurant,
      ),
    );
  }

  String _displayName(String name) {
    final trimmed = name.trim();
    if (trimmed.toLowerCase().endsWith('restaurant')) return trimmed;
    return '$trimmed Restaurant';
  }

  @override
  Widget build(BuildContext context) {
    final fromName = _displayName(currentCartRestaurant);
    final toName = _displayName(newRestaurant);

    // Close button sits centered on the top border (half above / half below).
    const closeSize = 44.0;
    const closeOverlap = closeSize / 2;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // White modal — top edge aligns with center of close button
          Padding(
            padding: const EdgeInsets.only(top: closeOverlap),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 34, 22, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Replace cart item?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your cart has dishes from $fromName. '
                    'Do you want to replace them with dishes from $toName?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EDE6),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'No',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(true),
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
                                  color: const Color(0xFFFF5E00)
                                      .withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Yes',
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
                ],
              ),
            ),
          ),

          // Close button — horizontally centered, overlapping top edge
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Container(
                  width: closeSize,
                  height: closeSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5EC),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withValues(alpha: 0.18),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFFFF5E00),
                    size: 20,
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
