import 'package:flutter/material.dart';

class PharmacyBackground extends StatelessWidget {
  const PharmacyBackground({super.key, required this.child});

  final Widget child;

  static const Color top = Color(0xFFF4F7EF);
  static const Color bottom = Color(0xFFFDF9F0);

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF4F7EF),
      Color(0xFFF6F5EB),
      Color(0xFFFDE3D4),
      Color(0xFFFDF1E7),
      Color(0xFFFDF9F0),
    ],
    stops: [0.0, 0.16, 0.32, 0.5, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}
