import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Light, quick motion for the whole app (client: interactive, never boring;
/// V2_DECISIONS §17). Every effect is off when the phone asks to reduce motion,
/// and none of them delays a tap.
class Motion {
  Motion._();

  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Fades and slides a list item in. Items built in the same frame come in one
/// after another (max 8 steps), so lists animate without passing an index.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.offset = 18});

  final Widget child;

  /// Start distance in logical pixels (downwards).
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  static Duration? _frame;
  static int _inFrame = 0;

  late final AnimationController _controller = AnimationController(vsync: this, duration: Motion.normal);
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Motion.curve);

  @override
  void initState() {
    super.initState();
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    if (_frame != now) {
      _frame = now;
      _inFrame = 0;
    }
    final step = _inFrame.clamp(0, 8);
    _inFrame++;
    Future.delayed(Duration(milliseconds: 45 * step), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _curve.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Gentle press-down feedback for cards and custom buttons.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down && !reduced ? widget.scale : 1,
        duration: Motion.fast,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}
