import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography scale:
/// Heading (screen app-bar) → Title (section / card name) → Subtitle (supporting).
class AppTextStyles {
  AppTextStyles._();

  /// Screen headings — e.g. My Orders, Services, Cart.
  static TextStyle heading({Color color = const Color(0xFF2C2520)}) {
    return GoogleFonts.outfit(
      color: color,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    );
  }

  /// Titles — a step down from heading (section / card primary).
  static TextStyle title({Color color = const Color(0xFF2C2520)}) {
    return GoogleFonts.outfit(
      color: color,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
  }

  /// Subtitles — a step down from title (supporting / secondary).
  static TextStyle subtitle({Color color = const Color(0xFF7A6A60)}) {
    return GoogleFonts.outfit(
      color: color,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
  }
}
