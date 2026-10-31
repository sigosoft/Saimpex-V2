import 'dart:io';
import '../../widgets/app_back_button.dart';
import '../widgets/country_code_picker.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/pharmacy_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../home_scanner_screen.dart';
import 'widgets/pharmacy_background.dart';
import 'prescription_success_screen.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  final String? initialPharmacy;
  final int? initialPharmacyId;

  const UploadPrescriptionScreen({
    super.key,
    this.initialPharmacy,
    this.initialPharmacyId,
  });

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  bool callBeforeAlternative = true;
  bool isPickingFile = false;
  bool isLoadingPharmacies = false;
  bool isSubmitting = false;
  String? selectedPharmacy;
  int? selectedPharmacyId;
  String? uploadedLabel;
  String? uploadedPath;
  bool uploadedIsImage = false;
  final TextEditingController contactController = TextEditingController();
  final FocusNode contactFocus = FocusNode();
  String countryCode = '+222';
  String countryFlag = '🇲🇷';
  List<Map<String, String>> pharmacies = [];

  @override
  void initState() {
    super.initState();
    selectedPharmacy = widget.initialPharmacy;
    selectedPharmacyId = widget.initialPharmacyId;
    _loadPharmacies();
  }

  @override
  void dispose() {
    contactController.dispose();
    contactFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return PharmacyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            SizedBox(height: topInset + 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppBackButton(onTap: () => Navigator.pop(context)),
                    ),
                    Text(
                      'pw_upload_prescription'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'pw_upload_prescription_intro'.tr,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPrescriptionIllustration(),
                    const SizedBox(height: 20),
                    _buildAddPrescriptionCard(),
                    const SizedBox(height: 14),
                    _buildCallToggle(),
                    const SizedBox(height: 18),
                    Text(
                      'pw_choose_pharmacy'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPharmacyDropdown(),
                    const SizedBox(height: 16),
                    Text(
                      'pw_enter_contact_number'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildContactField(),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: isPickingFile || isSubmitting
                          ? null
                          : _submitQuotation,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF5E00,
                              ).withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'pw_submit_for_quotation'.tr,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionIllustration() {
    return Center(
      child: SizedBox(
        width: 160,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD7E8DC).withValues(alpha: 0.9),
                    const Color(0xFFFAF6F0).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            if (uploadedIsImage && uploadedPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(uploadedPath!),
                  width: 110,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 92,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
                child: Column(
                  children: [
                    _docLine(widthFactor: 1),
                    const SizedBox(height: 12),
                    _docLine(widthFactor: 0.85),
                    const SizedBox(height: 12),
                    _docLine(widthFactor: 0.7),
                  ],
                ),
              ),
            PositionedDirectional(
              end: 22,
              bottom: 10,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E00),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  uploadedPath == null
                      ? Icons.note_add_rounded
                      : Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docLine({required double widthFactor}) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFB7C9D4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPrescriptionCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'pw_add_your_prescription'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5E00),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'i',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (uploadedLabel != null)
            Text(
              'pw_selected_file'.trParams({'name': uploadedLabel!}),
              style: GoogleFonts.outfit(
                color: const Color(0xFF00B25C),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text.rich(
              TextSpan(
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(text: 'pw_accept_files_prefix'.tr),
                  TextSpan(
                    text: 'JPG, PNG',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: 'pw_accept_files_and'.tr),
                  TextSpan(
                    text: 'PDF',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildUploadAction(
                  label: 'pw_take_photo'.tr,
                  icon: Icons.photo_camera_outlined,
                  filled: true,
                  onTap: isPickingFile ? null : _takePhoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUploadAction(
                  label: 'pw_upload_file'.tr,
                  icon: Icons.file_upload_outlined,
                  filled: false,
                  onTap: isPickingFile ? null : _uploadFile,
                ),
              ),
            ],
          ),
          if (isPickingFile) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFFFF5E00),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadAction({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: filled ? const Color(0xFFFFF0EA) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled ? const Color(0xFFFFD8C4) : const Color(0xFFE5D9CE),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: filled
                    ? const Color(0xFFFF5E00)
                    : const Color(0xFF7A6A60),
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: filled
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFF2C2520),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallToggle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFEA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'pw_call_before_alternative'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          Switch.adaptive(
            value: callBeforeAlternative,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFFF5E00),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD9CFC6),
            onChanged: (value) {
              setState(() => callBeforeAlternative = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyDropdown() {
    return GestureDetector(
      onTap: isLoadingPharmacies ? null : _showPharmacyPicker,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5D9CE), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedPharmacy ?? 'pw_choose_pharmacy'.tr,
                style: GoogleFonts.outfit(
                  color: selectedPharmacy == null
                      ? const Color(0xFFA59A94)
                      : const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isLoadingPharmacies)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF5E00),
                ),
              )
            else
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFA59A94),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactField() {
    return GestureDetector(
      onTap: () => contactFocus.requestFocus(),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5D9CE), width: 1),
        ),
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => showCountryCodePicker(
                onSelected: (code, flag) => setState(() {
                  countryCode = code;
                  countryFlag = flag;
                }),
              ),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(countryFlag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    countryCode,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF7A6A60),
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: contactController,
                focusNode: contactFocus,
                keyboardType: TextInputType.phone,
                cursorColor: const Color(0xFF2C2520),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final path = await Get.to<String>(() => const HomeScannerScreen());
    if (path == null || !mounted) return;

    setState(() {
      uploadedPath = path;
      uploadedLabel = path.split(Platform.pathSeparator).last;
      uploadedIsImage = true;
    });
    _showToast('pw_photo_captured'.tr);
  }

  Future<void> _uploadFile() async {
    if (isPickingFile) return;
    setState(() => isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final name = file.name;

      String? path = file.path;
      if ((path == null || path.isEmpty) && file.bytes != null) {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}${Platform.pathSeparator}$name');
        await tempFile.writeAsBytes(file.bytes!, flush: true);
        path = tempFile.path;
      }

      if (path == null || path.isEmpty) {
        _showToast('pw_could_not_read_file'.tr, isError: true);
        return;
      }

      setState(() {
        uploadedPath = path;
        uploadedLabel = name;
        uploadedIsImage = false;
      });
      _showToast('pw_pdf_uploaded'.tr);
    } catch (_) {
      _showToast('pw_file_picker_restart'.tr, isError: true);
    } finally {
      if (mounted) setState(() => isPickingFile = false);
    }
  }

  void _showPharmacyPicker() {
    final searchController = TextEditingController();
    var query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        final sheetHeight = MediaQuery.sizeOf(context).height * 0.72;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = pharmacies.where((pharmacy) {
              if (query.isEmpty) return true;
              return pharmacy['title']!.toLowerCase().contains(
                query.toLowerCase(),
              );
            }).toList();

            return SizedBox(
              height: sheetHeight + 56,
              child: Stack(
                children: [
                  Positioned(
                    top: 56,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: const Color(0xFFFAF6F0),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          const SizedBox(height: 22),
                          Text(
                            'pw_choose_pharmacy'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFE8DFD6),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFFB0A59C),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      onChanged: (value) {
                                        setModalState(
                                          () => query = value.trim(),
                                        );
                                      },
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF2C2520),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      cursorColor: const Color(0xFFFF5E00),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        hintText:
                                            'pw_search_near_nouakchott'.tr,
                                        hintStyle: GoogleFonts.outfit(
                                          color: const Color(0xFFB0A59C),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      'pw_no_pharmacies_found'.tr,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFA59A94),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      bottomInset + 20,
                                    ),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final pharmacy = filtered[index];
                                      return _buildPharmacyPickerCard(
                                        pharmacy: pharmacy,
                                        onTap: () {
                                          setState(() {
                                            selectedPharmacy =
                                                pharmacy['title'];
                                            selectedPharmacyId = int.tryParse(
                                              pharmacy['id'] ?? '',
                                            );
                                          });
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Keep close inside hit-test bounds (above the sheet)
                  Positioned(
                    top: 7,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(context),
                          child: Ink(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFFFF5E00),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(searchController.dispose);
  }

  Widget _buildPharmacyPickerCard({
    required Map<String, String> pharmacy,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ClipOval(
                          child: _pharmacyImage(pharmacy['image'] ?? ''),
                        ),
                      ),
                      PositionedDirectional(
                        top: -2,
                        start: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFAE00),
                                size: 11,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                pharmacy['rating']!,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              pharmacy['title']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD8F5E5),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              pharmacy['status'] == 'CLOSED'
                                  ? 'pw_closed_caps'.tr
                                  : 'pw_open_caps'.tr,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF00A854),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFFFF5E00),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pharmacy['time']!,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFFF5E00),
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            pharmacy['dist']!,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9A8F86),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pharmacyImage(String image) {
    if (!image.startsWith('http')) {
      return Container(
        color: const Color(0xFFF3EFEA),
        alignment: Alignment.center,
        child: const Icon(
          Icons.local_pharmacy_outlined,
          color: Color(0xFFA59A94),
          size: 24,
        ),
      );
    }
    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF3EFEA),
        alignment: Alignment.center,
        child: const Icon(
          Icons.local_pharmacy_outlined,
          color: Color(0xFFA59A94),
          size: 24,
        ),
      ),
    );
  }

  Future<void> _loadPharmacies() async {
    setState(() => isLoadingPharmacies = true);
    try {
      final cards = await Get.find<PharmacyRepository>()
          .fetchPrescriptionPharmacies(
            latitude: SelectLocationController.selectedLatitude,
            longitude: SelectLocationController.selectedLongitude,
            language: apiLanguageCode(),
          );
      if (!mounted) return;
      final loaded = cards.map(_pickerPharmacy).toList();
      final initialId = widget.initialPharmacyId;
      if (initialId != null &&
          loaded.every((pharmacy) => pharmacy['id'] != '$initialId')) {
        loaded.insert(0, {
          'id': '$initialId',
          'title': widget.initialPharmacy ?? 'pw_pharmacy'.tr,
          'rating': '',
          'time': '',
          'dist': '',
          'image': '',
          'status': 'OPEN',
        });
      }
      String? matchedTitle;
      if (initialId != null) {
        for (final pharmacy in loaded) {
          if (pharmacy['id'] == '$initialId') {
            matchedTitle = pharmacy['title'];
            break;
          }
        }
      }
      setState(() {
        pharmacies = loaded;
        if (matchedTitle != null) {
          selectedPharmacyId = initialId;
          selectedPharmacy = matchedTitle;
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => isLoadingPharmacies = false);
    }
  }

  Map<String, String> _pickerPharmacy(Map<String, dynamic> card) {
    return {
      'id': '${card['id'] ?? ''}',
      'title': '${card['title'] ?? 'pw_pharmacy'.tr}',
      'rating': '${card['rating'] ?? ''}',
      'time': '${card['time'] ?? ''}',
      'dist': '${card['dist'] ?? ''}',
      'image': '${card['image'] ?? ''}',
      'status': card['isClosed'] == true ? 'CLOSED' : 'OPEN',
    };
  }

  Future<void> _submitQuotation() async {
    if (isSubmitting) return;
    if (uploadedPath == null) {
      _showToast('pw_add_prescription_first'.tr, isError: true);
      return;
    }
    if (selectedPharmacyId == null) {
      _showToast('pw_please_choose_pharmacy'.tr, isError: true);
      return;
    }
    final contactNumber = contactController.text.trim();
    if (contactNumber.isEmpty) {
      _showToast('pw_please_enter_contact'.tr, isError: true);
      return;
    }
    if (!File(uploadedPath!).existsSync()) {
      _showToast('pw_could_not_read_file'.tr, isError: true);
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final message = await Get.find<PharmacyRepository>().uploadPrescription(
        pharmacyId: selectedPharmacyId!,
        contactNumber: '$countryCode $contactNumber',
        callBeforeAlternative: callBeforeAlternative,
        filePath: uploadedPath!,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      Get.to(
        () => PrescriptionSuccessScreen(
          fileName: uploadedLabel ?? 'Prescription.pdf',
          filePath: uploadedPath,
          isImage: uploadedIsImage,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF00B25C),
      ),
    );
  }
}
