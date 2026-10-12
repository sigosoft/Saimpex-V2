import 'package:flutter/material.dart';

/// Top half peach, bottom half the home page white, blended through the middle.
class HomeBackgroundBlend extends StatelessWidget {
  final Widget child;

  const HomeBackgroundBlend({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDDCC9),
            Color(0xFFFAF6F0),
          ],
        ),
      ),
      child: child,
    );
  }
}
