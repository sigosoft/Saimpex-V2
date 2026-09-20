import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared pill-style filter chip used across grocery, food, express, etc.
class AppFilterChip extends StatelessWidget {
  final String label;
  final Widget? leading;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const AppFilterChip({
    super.key,
    required this.label,
    this.leading,
    this.onTap,
    this.margin = const EdgeInsets.only(right: 10),
  });

  /// Orange $ badge for “Under … MRU” filters.
  static Widget mruLeading() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFFF5E00),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        '\$',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  /// Green veg square for veg filters.
  static Widget vegLeading() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  static Widget iconLeading(IconData icon, {Color? color}) {
    return Icon(icon, color: color ?? const Color(0xFF2C2520), size: 15);
  }

  static Widget assetLeading(String path, {double size = 15}) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(path),
    );
  }

  static Widget widgetLeading(Widget child, {double size = 15}) {
    return SizedBox(width: size, height: size, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

/// Horizontal scrolling row of [AppFilterChip]s.
class AppFilterChipsRow extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double height;

  const AppFilterChipsRow({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        children: children,
      ),
    );
  }
}
