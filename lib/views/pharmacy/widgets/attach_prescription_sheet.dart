import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../models/cart_repository.dart';
import '../../../utils/api_language.dart';
import '../../../utils/toast_helper.dart';
import '../../home_scanner_screen.dart';

/// Shown after adding a pharmacy item that needs a prescription.
/// Uploads the prescription to the cart via `cart/pharmacy/attachPrescription`.
class AttachPrescriptionSheet extends StatefulWidget {
  final int pharmacyId;

  const AttachPrescriptionSheet({super.key, required this.pharmacyId});

  @override
  State<AttachPrescriptionSheet> createState() =>
      _AttachPrescriptionSheetState();
}

class _AttachPrescriptionSheetState extends State<AttachPrescriptionSheet> {
  final TextEditingController _noteController = TextEditingController();
  String? _filePath;
  String? _fileLabel;
  bool _picking = false;
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
      );
      final file = result?.files.firstOrNull;
      if (file?.path == null) return;
      _setFile(file!.path!, file.name);
    } catch (_) {
      showAppToast(
        'Unable to open file picker. Please try again.',
        backgroundColor: const Color(0xFFEF4444),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _takePhoto() async {
    final path = await Get.to<String>(() => const HomeScannerScreen());
    if (path == null || !mounted) return;
    _setFile(path, path.split(Platform.pathSeparator).last);
  }

  void _setFile(String path, String label) {
    setState(() {
      _filePath = path;
      _fileLabel = label;
    });
  }

  Future<void> _submit() async {
    final path = _filePath;
    if (_submitting || path == null) return;
    setState(() => _submitting = true);
    try {
      final message = await Get.find<CartRepository>().attachPrescription(
        pharmacyId: widget.pharmacyId,
        filePath: path,
        note: _noteController.text,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Prescription Required',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Attach a prescription for this item. A pharmacist will review it before checkout.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: _picking ? 'Opening...' : 'Upload PDF',
                  onTap: _picking ? null : _pickPdf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take Photo',
                  onTap: _takePhoto,
                ),
              ),
            ],
          ),
          if (_fileLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.attach_file_rounded,
                  size: 16,
                  color: Color(0xFF00A854),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _fileLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            maxLines: 2,
            maxLength: 2000,
            style: GoogleFonts.outfit(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Note for the pharmacist (optional)',
              hintStyle: GoogleFonts.outfit(
                color: const Color(0xFFB0A59C),
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5D9CE)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _filePath == null || _submitting ? null : _submit,
            child: Opacity(
              opacity: _filePath == null ? 0.5 : 1,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Attach Prescription',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5D9CE)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF5E00), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
