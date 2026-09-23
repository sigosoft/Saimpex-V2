import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centered title block matching the Home Cleaning reference design.
class HomeCleaningHeader extends StatelessWidget {
  const HomeCleaningHeader({super.key});

  static const _bg = Color(0xFFFAF6F0);
  static const _titleColor = Color(0xFF1A2B48);
  static const _accent = Color(0xFFFF8A65);
  static const _subtitleColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = (width * 0.05).clamp(18.0, 22.0);
    final subtitleSize = (width * 0.034).clamp(12.5, 14.0);
    final starSize = (titleSize * 0.55).clamp(10.0, 13.0);
    final lineInset = (width * 0.01).clamp(0.0, 4.0);

    return ColoredBox(
      color: _bg,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title + small orange "*" as superscript beside "Cleaning"
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home Cleaning',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: _titleColor,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(1, titleSize * -0.12),
                    child: Text(
                      '*',
                      style: GoogleFonts.outfit(
                        color: _accent,
                        fontSize: starSize,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Thin orange line — nearly full content width
              Padding(
                padding: EdgeInsets.symmetric(horizontal: lineInset),
                child: const SizedBox(
                  width: double.infinity,
                  height: 1,
                  child: ColoredBox(color: _accent),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Professional cleaning services at your doorstep',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: _subtitleColor,
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
