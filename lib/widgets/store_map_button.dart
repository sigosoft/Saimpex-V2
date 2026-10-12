import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoreMapButton extends StatelessWidget {
  const StoreMapButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: 33,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Store Map',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5216),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          const SizedBox(width: 6),
          Image.asset(
            'lib/assets/images/storemap.png',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );

    if (onTap == null) return button;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: button,
    );
  }
}
