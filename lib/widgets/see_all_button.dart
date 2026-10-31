import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SeeAllButton extends StatelessWidget {
  const SeeAllButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'core_see_all'.tr,
          style: GoogleFonts.outfit(
            color: const Color.fromARGB(255, 255, 112, 30),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFFF5E00),
          size: 20,
        ),
      ],
    );

    if (onTap == null) return button;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: button,
    );
  }
}
