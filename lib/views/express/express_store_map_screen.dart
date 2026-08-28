import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../restaurant_details_screen.dart';

class ExpressStoreMapScreen extends StatefulWidget {
  const ExpressStoreMapScreen({super.key});

  @override
  State<ExpressStoreMapScreen> createState() => _ExpressStoreMapScreenState();
}

class _ExpressStoreMapScreenState extends State<ExpressStoreMapScreen> {
  int selectedIndex = 0;
  late final PageController _pageController;

  final markers = [
    {
      'label': 'Al Fantasia',
      'left': 0.06,
      'top': 0.28,
      'size': 72.0,
      'bg': Colors.white,
      'textColor': Color(0xFF2C2520),
      'fontSize': 9.0,
      'storeIndex': 0,
    },
    {
      'label': 'RUE DU\nBURGER',
      'left': 0.52,
      'top': 0.12,
      'size': 68.0,
      'bg': Color(0xFF5C3D2E),
      'textColor': Colors.white,
      'fontSize': 7.5,
      'storeIndex': 2,
    },
    {
      'label': 'Thieb\nHouse',
      'left': 0.38,
      'top': 0.38,
      'size': 88.0,
      'bg': Color(0xFFFFC400),
      'textColor': Colors.white,
      'fontSize': 10.0,
      'border': Colors.white,
      'storeIndex': 3,
    },
    {
      'label': 'Damas\nRIM',
      'left': 0.08,
      'top': 0.52,
      'size': 68.0,
      'bg': Colors.white,
      'textColor': Color(0xFFE03A3A),
      'fontSize': 8.5,
      'storeIndex': 4,
    },
    {
      'label': 'ARABICA',
      'left': 0.58,
      'top': 0.58,
      'size': 72.0,
      'bg': Colors.white,
      'textColor': Color(0xFF2C2520),
      'fontSize': 8.0,
      'arabic': 'arabica',
      'storeIndex': 5,
    },
    {
      'label': 'BRAHIM\nBASHA',
      'left': 0.62,
      'top': 0.30,
      'size': 68.0,
      'bg': Color(0xFF5C3D2E),
      'textColor': Colors.white,
      'fontSize': 7.5,
      'storeIndex': 6,
    },
  ];

  final stores = [
    {
      'id': 'map1',
      'title': 'Al Fantasia',
      'subtitle': 'Moroccan • Traditional',
      'rating': '4.6',
      'time': '30-35 min',
      'dist': '10 Km',
      'image':
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=350&auto=format&fit=crop',
    },
    {
      'id': 'map2',
      'title': 'Express Hub',
      'subtitle': 'Quick Delivery',
      'rating': '4.5',
      'time': '15-20 min',
      'dist': '8 Km',
      'image':
          'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=350&auto=format&fit=crop',
    },
    {
      'id': 'map3',
      'title': 'Rue du Burger',
      'subtitle': 'Burgers • Fast Food',
      'rating': '4.5',
      'time': '25-30 min',
      'dist': '9 Km',
      'image':
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=350&auto=format&fit=crop',
    },
    {
      'id': 'map4',
      'title': 'Thieb House',
      'subtitle': 'Senegalese • Rice',
      'rating': '4.7',
      'time': '30-35 min',
      'dist': '10 Km',
      'image':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=350&auto=format&fit=crop',
    },
    {
      'id': 'map5',
      'title': 'Damas RIM',
      'subtitle': 'Middle Eastern • Grill',
      'rating': '4.6',
      'time': '30-35 min',
      'dist': '10 Km',
      'image':
          'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=350&auto=format&fit=crop',
    },
    {
      'id': 'map6',
      'title': 'Arabica',
      'subtitle': 'Coffee • Cafe',
      'rating': '4.5',
      'time': '20-25 min',
      'dist': '7 Km',
      'image':
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=350&auto=format&fit=crop',
    },
    {
      'id': 'map7',
      'title': 'Brahim Basha',
      'subtitle': 'Lebanese • Grill',
      'rating': '4.6',
      'time': '30-35 min',
      'dist': '11 Km',
      'image':
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=350&auto=format&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectStore(int index) {
    setState(() => selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECE4),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapRoadPainter(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: markers.map((marker) {
                      final storeIndex = marker['storeIndex'] as int;
                      final isSelected = selectedIndex == storeIndex;
                      return Positioned(
                        left: constraints.maxWidth * (marker['left'] as double),
                        top: constraints.maxHeight * (marker['top'] as double),
                        child: GestureDetector(
                          onTap: () => _selectStore(storeIndex),
                          child: _buildMapMarker(
                            marker,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFFFF5E00),
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(23),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFA59A94),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: GoogleFonts.outfit(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search restaurants, stores...',
                              hintStyle: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 12.5,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
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
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 12,
            child: SizedBox(
              height: 118,
              child: PageView.builder(
                controller: _pageController,
                itemCount: stores.length,
                onPageChanged: (index) => setState(() => selectedIndex = index),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildStoreCard(stores[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapMarker(
    Map<String, dynamic> marker, {
    required bool isSelected,
  }) {
    final size = marker['size'] as double;
    final bg = marker['bg'] as Color;
    final textColor = marker['textColor'] as Color;
    final border = marker['border'] as Color?;
    final label = marker['label'] as String;
    final fontSize = marker['fontSize'] as double;
    final arabic = marker['arabic'] as String?;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: border != null
                ? Border.all(color: border, width: 2)
                : isSelected
                    ? Border.all(color: const Color(0xFFFF5E00), width: 2)
                    : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (arabic != null) ...[
                Text(
                  'arabica',
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: -2,
          bottom: 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE03A3A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return GestureDetector(
      onTap: () => Get.to(() => RestaurantDetailsScreen(restaurant: store)),
      child: Container(
        margin: const EdgeInsets.only(left: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                store['image']!.toString(),
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 88,
                  height: 88,
                  color: const Color(0xFFF3EFEA),
                  child: const Icon(Icons.store, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    store['title']!.toString(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store['subtitle']!.toString(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFFFF5E00),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store['time']!.toString(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4A453F),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFFF5E00),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store['dist']!.toString(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4A453F),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFB8D4E8)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.95, 0)
      ..lineTo(size.width * 0.15, size.height)
      ..lineTo(size.width * 0.02, size.height)
      ..close();

    canvas.drawPath(path, roadPaint);

    final roadPaint2 = Paint()
      ..color = const Color(0xFFC8DFF0)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(size.width * 0.42, 0)
      ..lineTo(size.width * 0.88, 0)
      ..lineTo(size.width * 0.22, size.height)
      ..lineTo(size.width * 0.08, size.height)
      ..close();

    canvas.drawPath(path2, roadPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
