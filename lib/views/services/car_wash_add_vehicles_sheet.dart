import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CarWashAddedVehicle {
  final String label;
  final String image;
  final int price;
  final String plateNumber;

  const CarWashAddedVehicle({
    required this.label,
    required this.image,
    required this.price,
    required this.plateNumber,
  });
}

Future<CarWashAddedVehicle?> showCarWashAddVehiclesSheet(
  BuildContext context,
) {
  return showModalBottomSheet<CarWashAddedVehicle>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => const _AddVehiclesSheet(),
  );
}

class _AddVehiclesSheet extends StatefulWidget {
  const _AddVehiclesSheet();

  @override
  State<_AddVehiclesSheet> createState() => _AddVehiclesSheetState();
}

class _AddVehiclesSheetState extends State<_AddVehiclesSheet> {
  int _selectedType = 0;
  final _plateController = TextEditingController();
  bool _showPlateError = false;

  static const _closeSize = 44.0;
  static const _closeGap = 12.0;

  static const _types = [
    {
      'label': 'Sedan',
      'price': 350,
      'image': 'lib/assets/images/Sedan.png',
    },
    {
      'label': 'SUV/4x4',
      'price': 500,
      'image': 'lib/assets/images/SUV.png',
    },
    {
      'label': 'Pickup',
      'price': 550,
      'image': 'lib/assets/images/Pickup.png',
    },
    {
      'label': 'Mini bus',
      'price': 750,
      'image': 'lib/assets/images/MiniBus.png',
    },
  ];

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  /// Formats as `1234 AB 01` (4 digits + space + 2 letters + space + 2 digits).
  String _formatPlateNumber(String raw) {
    final cleaned = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final d1 = StringBuffer();
    final letters = StringBuffer();
    final d2 = StringBuffer();

    for (final ch in cleaned.split('')) {
      if (d1.length < 4) {
        if (RegExp(r'[0-9]').hasMatch(ch)) d1.write(ch);
      } else if (letters.length < 2) {
        if (RegExp(r'[A-Z]').hasMatch(ch)) letters.write(ch);
      } else if (d2.length < 2) {
        if (RegExp(r'[0-9]').hasMatch(ch)) d2.write(ch);
      }
    }

    final result = StringBuffer(d1.toString());
    if (letters.isNotEmpty || d2.isNotEmpty) {
      result.write(' ');
      result.write(letters.toString());
    }
    if (d2.isNotEmpty) {
      result.write(' ');
      result.write(d2.toString());
    }
    return result.toString();
  }

  void _onPlateChanged(String value) {
    final formatted = _formatPlateNumber(value);
    if (formatted != value) {
      _plateController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (_showPlateError) {
      setState(() => _showPlateError = false);
    }
  }

  void _onAdd() {
    final plate = _formatPlateNumber(_plateController.text).trim();
    if (plate.isEmpty) {
      setState(() => _showPlateError = true);
      Get.snackbar(
        '',
        'Please enter vehicle number',
        titleText: const SizedBox.shrink(),
        messageText: Text(
          'Please enter vehicle number',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF2C2520),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    setState(() => _showPlateError = false);
    final type = _types[_selectedType];
    Navigator.pop(
      context,
      CarWashAddedVehicle(
        label: type['label'] as String,
        image: type['image'] as String,
        price: type['price'] as int,
        plateNumber: plate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight =
        MediaQuery.sizeOf(context).height - keyboard - _closeSize - _closeGap;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: _closeSize + _closeGap),
            constraints: BoxConstraints(
              maxHeight: maxSheetHeight.clamp(280, double.infinity),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFDF8F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                  child: Text(
                    'Add Vehicles',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEDE4DA),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        'Vehicle Type',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _types.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final type = _types[index];
                            final selected = _selectedType == index;
                            const cardRadius = 28.0;

                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedType = index),
                              child: Container(
                                width: 132,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(cardRadius),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFFF5E00)
                                        : const Color(0xFFD8DEE8),
                                    width: selected ? 1.8 : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9AABB8)
                                          .withValues(alpha: 0.18),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    cardRadius - (selected ? 1.8 : 1.2),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 7,
                                        child: ColoredBox(
                                          color: const Color(0xFFE8E8E8),
                                          child: Image.asset(
                                            type['image'] as String,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (_, __, ___) =>
                                                const Center(
                                              child: Icon(
                                                Icons.directions_car_rounded,
                                                color: Color(0xFFFF5E00),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: ColoredBox(
                                          color: Colors.white,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                16,
                                                0,
                                                12,
                                                4,
                                              ),
                                              child: Text(
                                                type['label'] as String,
                                                style: GoogleFonts.outfit(
                                                  color:
                                                      const Color(0xFF0F1E31),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Enter vehicle number',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _showPlateError
                                ? const Color(0xFFE53935)
                                : const Color(0xFFE8DFD6),
                            width: _showPlateError ? 1.5 : 1,
                          ),
                        ),
                        child: TextField(
                          controller: _plateController,
                          textCapitalization: TextCapitalization.characters,
                          keyboardType: TextInputType.text,
                          onChanged: _onPlateChanged,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 1234 AB 01',
                            hintStyle: GoogleFonts.outfit(
                              color: const Color(0xFFB0A59C),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.6,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      if (_showPlateError) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Please enter vehicle number',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFE53935),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: Color(0xFF9A8E86),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'This helps the wash center identify your vehicle easily',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF9A8E86),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2ECE1),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF1A1A1A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _onAdd,
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5E00),
                                      Color(0xFFFFAE00),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5E00)
                                          .withValues(alpha: 0.28),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Add',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: _closeSize,
                height: _closeSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
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
        ],
      ),
    );
  }
}
