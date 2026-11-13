import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../utils/app_fonts.dart';

/// Figma Store Map pins: the store's photo in a round white frame (yellow
/// when selected) with the store name underneath, instead of Google's red
/// drop pins. Drawn once per store and state, then cached.
class StoreMapPins {
  final Map<String, BitmapDescriptor> _cache = {};
  final Map<String, ui.Image?> _images = {};

  static const double _canvasWidth = 220;
  static const double _circle = 112;
  static const double _labelTop = _circle + 8;
  static const double _canvasHeight = _labelTop + 44;

  /// Where the pin sits on the store's point: the circle's centre.
  static const Offset anchor = Offset(0.5, (_circle / 2) / _canvasHeight);

  BitmapDescriptor? cached(String key, bool selected) =>
      _cache['$key|$selected'];

  /// Builds (or returns) the pin for one store.
  Future<BitmapDescriptor> pin({
    required String key,
    required String imageUrl,
    required String title,
    required bool selected,
  }) async {
    final cacheKey = '$key|$selected';
    final hit = _cache[cacheKey];
    if (hit != null) return hit;
    final image = _images.containsKey(imageUrl)
        ? _images[imageUrl]
        : _images[imageUrl] = await _loadImage(imageUrl);
    final descriptor = await _draw(image, title, selected);
    return _cache[cacheKey] = descriptor;
  }

  static Future<ui.Image?> _loadImage(String url) {
    if (!url.startsWith('http')) return Future.value(null);
    final completer = Completer<ui.Image?>();
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (_, _) {
        if (!completer.isCompleted) completer.complete(null);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  }

  static Future<BitmapDescriptor> _draw(
    ui.Image? image,
    String title,
    bool selected,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(_canvasWidth / 2, _circle / 2);
    const outer = _circle / 2 - 6;

    canvas.drawCircle(
      center.translate(0, 3),
      outer,
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      center,
      outer,
      Paint()..color = selected ? const Color(0xFFFFC23A) : Colors.white,
    );
    final inner = outer - (selected ? 10 : 7);
    final photo = Rect.fromCircle(center: center, radius: inner);
    if (image != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(photo));
      paintImage(canvas: canvas, rect: photo, image: image, fit: BoxFit.cover);
      canvas.restore();
    } else {
      canvas.drawCircle(
        center,
        inner,
        Paint()..color = const Color(0xFFFFEDE4),
      );
      final initial = TextPainter(
        text: TextSpan(
          text: title.isEmpty ? '?' : title.characters.first.toUpperCase(),
          style: AppFonts.outfit(
            color: Color(0xFFFF5216),
            fontSize: 44,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      initial.paint(
        canvas,
        center - Offset(initial.width / 2, initial.height / 2),
      );
    }

    // Name under the pin, dark text in a white pill, as in Figma.
    if (title.isNotEmpty) {
      final label = TextPainter(
        text: TextSpan(
          text: title,
          style: AppFonts.outfit(
            color: Color(0xFF2C2520),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: _canvasWidth - 28);
      final pill = Rect.fromCenter(
        center: Offset(_canvasWidth / 2, _labelTop + 18),
        width: label.width + 24,
        height: 36,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pill, const Radius.circular(18)),
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
      label.paint(
        canvas,
        Offset(
          pill.center.dx - label.width / 2,
          pill.center.dy - label.height / 2,
        ),
      );
    }

    final picture = recorder.endRecording();
    final bitmap = await picture.toImage(
      _canvasWidth.toInt(),
      _canvasHeight.toInt(),
    );
    final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      // ~46 dp circle on screen.
      width: _canvasWidth * 0.42,
    );
  }
}
