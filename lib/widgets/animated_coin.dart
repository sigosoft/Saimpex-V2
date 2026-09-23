import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Continuously animates [Coin.png] with a gentle flip + bounce.
class AnimatedCoin extends StatefulWidget {
  final double size;
  final String asset;

  const AnimatedCoin({
    super.key,
    this.size = 17,
    this.asset = 'lib/assets/images/Coin.png',
  });

  @override
  State<AnimatedCoin> createState() => _AnimatedCoinState();
}

class _AnimatedCoinState extends State<AnimatedCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flip;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _flip = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: math.pi * 2)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(math.pi * 2),
        weight: 45,
      ),
    ]).animate(_controller);

    _bounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _flip.value;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle),
          child: Transform.scale(
            scale: _bounce.value,
            child: child,
          ),
        );
      },
      child: Image.asset(
        widget.asset,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}
