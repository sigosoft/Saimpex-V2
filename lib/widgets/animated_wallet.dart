import 'package:flutter/material.dart';

/// Wallet icon with a float + soft pulse (not a coin flip).
class AnimatedWallet extends StatefulWidget {
  final double size;
  final String asset;

  const AnimatedWallet({
    super.key,
    this.size = 28,
    this.asset = 'lib/assets/images/wallet.png',
  });

  @override
  State<AnimatedWallet> createState() => _AnimatedWalletState();
}

class _AnimatedWalletState extends State<AnimatedWallet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;
  late final Animation<double> _pulse;
  late final Animation<double> _tilt;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _float = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _tilt = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: Transform.rotate(
            angle: _tilt.value,
            child: Transform.scale(
              scale: _pulse.value,
              child: child,
            ),
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
