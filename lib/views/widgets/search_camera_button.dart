import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../../utils/toast_helper.dart';
import '../home_scanner_screen.dart';

/// Opens the home scanner and returns a title-cased label for [path].
Future<String?> labelScannedImage(String path) async {
  final labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.4),
  );
  try {
    final labels = await labeler.processImage(InputImage.fromFilePath(path));
    if (labels.isEmpty) {
      showAppToast('Could not identify that image.');
      return null;
    }
    labels.sort((a, b) => b.confidence.compareTo(a.confidence));
    return titleCaseScanLabel(labels.first.label);
  } catch (_) {
    showAppToast('Could not scan that image.');
    return null;
  } finally {
    await labeler.close();
  }
}

String titleCaseScanLabel(String value) {
  return value
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

/// Holds a search controller for screens that are not stateful.
class ScanSearchHost extends StatefulWidget {
  const ScanSearchHost({super.key, required this.builder});

  final Widget Function(TextEditingController controller) builder;

  @override
  State<ScanSearchHost> createState() => _ScanSearchHostState();
}

class _ScanSearchHostState extends State<ScanSearchHost> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(controller);
}

class SearchCameraButton extends StatefulWidget {
  const SearchCameraButton({
    super.key,
    required this.controller,
    required this.child,
    this.onFilled,
  });

  final TextEditingController controller;
  final Widget child;
  final ValueChanged<String>? onFilled;

  @override
  State<SearchCameraButton> createState() => _SearchCameraButtonState();
}

class _SearchCameraButtonState extends State<SearchCameraButton> {
  bool _busy = false;

  Future<void> _scan() async {
    if (_busy) return;
    final path = await Get.to<String>(() => const HomeScannerScreen());
    if (path == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final text = await labelScannedImage(path);
      if (!mounted || text == null) return;
      widget.controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      widget.onFilled?.call(text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy ? null : _scan,
      behavior: HitTestBehavior.opaque,
      child: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF5E00),
              ),
            )
          : ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
              child: widget.child,
            ),
    );
  }
}
