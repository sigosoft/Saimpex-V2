import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/toast_helper.dart';

class HomeScannerScreen extends StatefulWidget {
  const HomeScannerScreen({super.key});

  @override
  State<HomeScannerScreen> createState() => _HomeScannerScreenState();
}

class _HomeScannerScreenState extends State<HomeScannerScreen> {
  CameraController? _controller;
  final ImagePicker _picker = ImagePicker();
  bool _disposed = false;
  bool _taking = false;
  String? _lastPath;

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || _disposed) return;
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (_disposed) {
        await controller.dispose();
        return;
      }
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) {
        showAppToast('core_scanner_allow_camera'.tr);
      }
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_taking || controller == null || !controller.value.isInitialized) {
      showAppToast('core_scanner_allow_camera'.tr);
      return;
    }
    setState(() => _taking = true);
    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      setState(() => _lastPath = photo.path);
      Get.back(result: photo.path);
    } catch (_) {
      if (mounted) showAppToast('core_scanner_capture_failed'.tr);
    } finally {
      if (mounted) setState(() => _taking = false);
    }
  }

  Future<void> _uploadGallery() async {
    if (_taking) return;
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;
    setState(() => _lastPath = photo.path);
    Get.back(result: photo.path);
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF252525),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF2A2A2A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (ready) _CameraFill(controller: controller),
            const _EdgeFade(),
            const _ScanFrame(),
            Positioned(
              left: 24,
              right: 24,
              bottom: 18 + bottomPad,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _uploadGallery,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.4,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'core_scanner_upload_gallery'.tr,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              height: 1.15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Transform.translate(
                        offset: const Offset(0, -12),
                        child: GestureDetector(
                          onTap: _taking ? null : _capture,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            padding: const EdgeInsets.all(5),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _thumbnail(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final path = _lastPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: path == null
            ? const ColoredBox(color: Color(0xFF3A3A3A))
            : Image.file(File(path), fit: BoxFit.cover),
      ),
    );
  }
}

class _CameraFill extends StatelessWidget {
  const _CameraFill({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    if (size == null) return const SizedBox.expand();
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xE6343434),
                    Color(0x99545454),
                    Color(0x00747474),
                  ],
                ),
              ),
            ),
          ),
          Spacer(),
          SizedBox(
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x006B6B6B),
                    Color(0xC45A5A5A),
                    Color(0xF23F3F3F),
                    Color(0xFF252525),
                  ],
                  stops: [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 36;
    final height = width * 0.72;
    return Align(
      alignment: const Alignment(0, -0.18),
      child: SizedBox(
        width: width,
        height: height,
        child: const CustomPaint(
          painter: _ScanFramePainter(),
          child: Center(child: _GridMark()),
        ),
      ),
    );
  }
}

class _GridMark extends StatelessWidget {
  const _GridMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: 2),
                Container(
                  width: 2.5,
                  height: 2.5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = 0.8;
    final thirdW = size.width / 3;
    final thirdH = size.height / 3;
    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), grid);
    canvas.drawLine(
      Offset(thirdW * 2, 0),
      Offset(thirdW * 2, size.height),
      grid,
    );
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), grid);
    canvas.drawLine(
      Offset(0, thirdH * 2),
      Offset(size.width, thirdH * 2),
      grid,
    );

    final corner = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const arm = 26.0;
    final path = Path()
      ..moveTo(0, arm)
      ..lineTo(0, 0)
      ..lineTo(arm, 0)
      ..moveTo(size.width - arm, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, arm)
      ..moveTo(0, size.height - arm)
      ..lineTo(0, size.height)
      ..lineTo(arm, size.height)
      ..moveTo(size.width - arm, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height - arm);
    canvas.drawPath(path, corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
