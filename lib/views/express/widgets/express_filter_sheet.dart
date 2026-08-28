import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showExpressFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ExpressFilterSheet(),
  );
}

class ExpressFilterSheet extends StatefulWidget {
  const ExpressFilterSheet({super.key});

  @override
  State<ExpressFilterSheet> createState() => _ExpressFilterSheetState();
}

class _ExpressFilterSheetState extends State<ExpressFilterSheet> {
  final List<String> selectedTags = [];
  RangeValues priceRange = const RangeValues(65, 1500);
  String selectedSortBy = 'Relevance';

  final List<String> preferenceTags = [
    'Spicy',
    'Non Spicy',
    'Sugar Free',
    'Mild Sugar',
  ];

  final List<String> filterTags = [
    'Offers',
    'Ratings 4.5+',
    'Ratings 4.0+',
    'Ratings 3.5+',
  ];

  final List<String> sortOptions = [
    'Relevance',
    'Delivery Time',
    'Cost: Low to High',
    'Cost: High to Low',
  ];

  void _clearAll() {
    setState(() {
      selectedTags.clear();
      priceRange = const RangeValues(65, 1500);
      selectedSortBy = 'Relevance';
    });
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF6F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFEAD8C9),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected
                ? const Color(0xFFFF5E00)
                : const Color(0xFF2C2520),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChipRow(List<String> tags) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tags.map((tag) {
          final isSelected = selectedTags.contains(tag);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildChip(tag, isSelected, () {
              setState(() {
                if (selectedTags.contains(tag)) {
                  selectedTags.remove(tag);
                } else {
                  selectedTags.add(tag);
                }
              });
            }),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 56),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    Text(
                      'Filters',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearAll,
                      child: Text(
                        'Clear all',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildChipRow(preferenceTags),
              const SizedBox(height: 10),
              _buildChipRow(filterTags),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price Range',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${priceRange.start.round()} MRU - ${priceRange.end.round()} MRU',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFFF5E00),
                    inactiveTrackColor: const Color(0xFFF3EFEA),
                    overlayColor: const Color(0xFFFF5E00).withValues(alpha: 0.12),
                    rangeThumbShape: const _ExpressRangeThumbShape(
                      enabledThumbRadius: 10,
                    ),
                  ),
                  child: RangeSlider(
                    values: priceRange,
                    min: 0,
                    max: 3000,
                    divisions: 60,
                    onChanged: (values) {
                      setState(() => priceRange = values);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0 MRU',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '3000 MRU',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Text(
                  'Sort by',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: sortOptions.map((option) {
                    final isSelected = selectedSortBy == option;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildChip(option, isSelected, () {
                        setState(() => selectedSortBy = option);
                      }),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 12 + bottomPad),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _clearAll,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EA),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5E00)
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Apply',
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
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
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
    );
  }
}

class _ExpressRangeThumbShape extends RangeSliderThumbShape {
  final double enabledThumbRadius;

  const _ExpressRangeThumbShape({this.enabledThumbRadius = 10.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isPressed) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop = false,
    bool isPressed = false,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb thumb = Thumb.start,
  }) {
    final canvas = context.canvas;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, enabledThumbRadius, shadowPaint);

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius, fillPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFF5E00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, enabledThumbRadius - 1.25, borderPaint);
  }
}
