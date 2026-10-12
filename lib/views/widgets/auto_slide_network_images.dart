import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

List<String> foodGalleryImages(Map<String, dynamic> food) {
  final raw = food['images'];
  if (raw is List) {
    final urls = raw
        .map((image) => image.toString())
        .where((image) => image.isNotEmpty)
        .toList();
    if (urls.isNotEmpty) return urls;
  }
  final single = food['image']?.toString() ?? '';
  return single.isEmpty ? const [] : [single];
}

class AutoSlideNetworkImages extends StatefulWidget {
  final List<String> images;
  final bool showDots;
  final Duration interval;
  final BoxFit fit;
  final Alignment alignment;
  final double blurSigma;

  const AutoSlideNetworkImages({
    super.key,
    required this.images,
    this.showDots = true,
    this.interval = const Duration(seconds: 3),
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.blurSigma = 0,
  });

  @override
  State<AutoSlideNetworkImages> createState() => _AutoSlideNetworkImagesState();
}

class _ForwardOnlyScrollPhysics extends ScrollPhysics {
  const _ForwardOnlyScrollPhysics({super.parent});

  @override
  _ForwardOnlyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ForwardOnlyScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels) return value - position.pixels;
    return super.applyBoundaryConditions(position, value);
  }
}

class _AutoSlideNetworkImagesState extends State<AutoSlideNetworkImages> {
  static const int _loopBase = 1000;

  late final PageController _controller;
  Timer? _timer;
  late int _page;

  @override
  void initState() {
    super.initState();
    final count = widget.images.length;
    _page = count > 1 ? _loopBase * count : 0;
    _controller = PageController(initialPage: _page);
    if (count > 1) {
      _timer = Timer.periodic(widget.interval, (_) => _advance());
    }
  }

  void _advance() {
    if (!mounted || !_controller.hasClients || widget.images.length < 2) {
      return;
    }
    _page += 1;
    _controller.animateToPage(
      _page,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  int get _dotIndex {
    final count = widget.images.length;
    if (count == 0) return 0;
    return _page % count;
  }

  Widget _galleryImage(String path) {
    const fallback = ColoredBox(
      color: Color(0xFFFFE8DC),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: Color(0xFFFF5E00)),
      ),
    );
    final image = path.startsWith('http')
        ? Image.network(
            path,
            fit: widget.fit,
            alignment: widget.alignment,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => fallback,
          )
        : Image.asset(
            path,
            fit: widget.fit,
            alignment: widget.alignment,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => fallback,
          );
    if (widget.blurSigma <= 0) return image;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: widget.blurSigma,
        sigmaY: widget.blurSigma,
        tileMode: TileMode.clamp,
      ),
      child: image,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFFFE8DC),
        child: Center(
          child: Icon(Icons.restaurant, color: Color(0xFFFF5E00)),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          physics: widget.images.length > 1
              ? const _ForwardOnlyScrollPhysics(
                  parent: PageScrollPhysics(),
                )
              : const NeverScrollableScrollPhysics(),
          itemCount: widget.images.length > 1 ? null : widget.images.length,
          onPageChanged: (index) => setState(() => _page = index),
          itemBuilder: (context, index) {
            final image = widget.images[index % widget.images.length];
            return _galleryImage(image);
          },
        ),
        if (widget.showDots && widget.images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (index) {
                final active = index == _dotIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  width: active ? 10 : 4,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFFF5E00)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
