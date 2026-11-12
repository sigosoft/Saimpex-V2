import 'package:flutter/material.dart';

/// The small open/closed dot Figma puts before a provider's status
/// ("Open", "Closed") on service cards: green when open, red otherwise.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.open, this.size = 7});

  final bool open;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: open ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
      ),
    );
  }
}
