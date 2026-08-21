import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'prescription_success_screen.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  final String? initialPharmacy;

  const UploadPrescriptionScreen({super.key, this.initialPharmacy});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  bool callBeforeAlternative = true;
  bool isPickingFile = false;
  String? selectedPharmacy;
  String? uploadedLabel;
  String? uploadedPath;
  bool uploadedIsImage = false;
  final TextEditingController contactController = TextEditingController();
  final FocusNode contactFocus = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  final List<Map<String, String>> pharmacies = const [
    {
      'title': 'Pharmacie Nasr',
      'rating': '4.6',
      'time': '30-35 min',
      'dist': '10 Km',
      'image':
          'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400&auto=format&fit=crop',
      'status': 'OPEN',
    },
    {
      'title': 'Pharmacy Mauritanie',
      'rating': '4.5',
      'time': '30-35 min',
      'dist': '10 Km',
      'image':
          'https://images.unsplash.com/photo-1586015555751-63bb77f4322a?w=400&auto=format&fit=crop',
      'status': 'OPEN',
    },
    {
      'title': 'Pharmacy El Amal',
      'rating': '4.7',
      'time': '25-30 min',
      'dist': '8 Km',
      'image':
          'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=400&auto=format&fit=crop',
      'status': 'OPEN',
    },
    {
      'title': 'Pharmacie Ibn Sina',
      'rating': '4.7',
      'time': '30-35 min',
      'dist': '10 Km',
      'image':
          'https://images.unsplash.com/photo-1628771065518-0d82f1938462?w=400&auto=format&fit=crop',
      'status': 'OPEN',
    },
    {
      'title': 'Pharmacy Safa',
      'rating': '4.3',
      'time': '30-35 min',
      'dist': '10 Km',
      'image':
          'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=400&auto=format&fit=crop',
      'status': 'OPEN',
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedPharmacy = widget.initialPharmacy;
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
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
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFF5E00).withValues(
                              alpha: 0.4,
                            ),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFFFF5E00),
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Upload Prescription',
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
                    'A licensed pharmacist will review your prescription and send you a priced quotation',
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
                    'Choose a Pharmacy',
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
                    'Enter Contact Number',
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
                    onTap: isPickingFile ? null : _submitQuotation,
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
                            color: const Color(0xFFFF5E00).withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        'Submit for Quotation',
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
            Positioned(
              right: 22,
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
      alignment: Alignment.centerLeft,
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
                  'Add your prescription',
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
              'Selected: $uploadedLabel',
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
                  const TextSpan(
                    text:
                        'Take a clear photo or upload a file. We accept ',
                  ),
                  TextSpan(
                    text: 'JPG, PNG',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(text: ' and '),
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
                  label: 'Take Photo',
                  icon: Icons.photo_camera_outlined,
                  filled: true,
                  onTap: isPickingFile ? null : _takePhoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUploadAction(
                  label: 'Upload File',
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
              'Call me before suggesting an alternative medicine',
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
      onTap: _showPharmacyPicker,
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
                selectedPharmacy ?? 'Choose a Pharmacy',
                style: GoogleFonts.outfit(
                  color: selectedPharmacy == null
                      ? const Color(0xFFA59A94)
                      : const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              '+222',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
    setState(() => isPickingFile = true);
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (photo == null) return;

      setState(() {
        uploadedPath = photo.path;
        uploadedLabel = photo.name;
        uploadedIsImage = true;
      });
      _showToast('Prescription photo captured');
    } catch (_) {
      _showToast(
        'Unable to open camera. Please allow camera permission and fully restart the app.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isPickingFile = false);
    }
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
        final tempFile = File(
          '${tempDir.path}${Platform.pathSeparator}$name',
        );
        await tempFile.writeAsBytes(file.bytes!, flush: true);
        path = tempFile.path;
      }

      if (path == null || path.isEmpty) {
        _showToast('Could not read selected file', isError: true);
        return;
      }

      setState(() {
        uploadedPath = path;
        uploadedLabel = name;
        uploadedIsImage = false;
      });
      _showToast('Prescription PDF uploaded');
    } catch (_) {
      _showToast(
        'Unable to open file picker. Please fully restart the app and try again.',
        isError: true,
      );
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
              return pharmacy['title']!
                  .toLowerCase()
                  .contains(query.toLowerCase());
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
                            'Choose a Pharmacy',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
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
                                        hintText: 'Search near Nouakchott...',
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
                                      'No pharmacies found',
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
                                          setState(
                                            () => selectedPharmacy =
                                                pharmacy['title'],
                                          );
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
                          child: Image.network(
                            pharmacy['image']!,
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
                          ),
                        ),
                      ),
                      Positioned(
                        top: -2,
                        left: -4,
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
                              pharmacy['status']!,
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

  void _submitQuotation() {
    if (uploadedPath == null) {
      _showToast('Please add your prescription first', isError: true);
      return;
    }
    if (selectedPharmacy == null) {
      _showToast('Please choose a pharmacy', isError: true);
      return;
    }
    if (contactController.text.trim().isEmpty) {
      _showToast('Please enter your contact number', isError: true);
      return;
    }

    Get.to(
      () => PrescriptionSuccessScreen(
        fileName: uploadedLabel ?? 'Prescription.pdf',
        filePath: uploadedPath,
        isImage: uploadedIsImage,
      ),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF00B25C),
      ),
    );
  }
}
