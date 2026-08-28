import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import 'home_cleaning_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const _tallCards = [
    _PopularCardData(
      title: 'Home\nCleaning',
      image: 'lib/assets/images/Home_cleaning.png',
      imageWidth: 104,
      imageHeight: 104,
      imageRight: 2,
      imageBottom: -6,
      ghostSize: 92,
      ghostTop: 34,
      ghostRight: 10,
    ),
    _PopularCardData(
      title: 'Car\nWash',
      image: 'lib/assets/images/car_wash.png',
      imageWidth: 118,
      imageHeight: 92,
      imageRight: 6,
      imageBottom: 8,
      imageAlignment: Alignment(0.1, 1.0),
      clipBottomFraction: 0.22,
      ghostSize: 88,
      ghostTop: 40,
      ghostRight: 6,
      ghostClipBottomFraction: 0.22,
    ),
  ];

  static const _compactCards = [
    _PopularCardData(
      title: 'Plumbing',
      image: 'lib/assets/images/plumbing.png',
      imageWidth: 56,
      imageHeight: 56,
      imageRight: 10,
      imageBottom: 8,
      imageAlignment: Alignment.bottomRight,
      imageScale: 1.18,
      showGhost: false,
    ),
    _PopularCardData(
      title: 'Laundry',
      image: 'lib/assets/images/laundry.png',
      imageWidth: 60,
      imageHeight: 60,
      imageRight: 6,
      imageBottom: -2,
      ghostSize: 50,
      ghostTop: 8,
      ghostRight: 10,
      showGhost: false,
    ),
    _PopularCardData(
      title: 'Carpentry',
      image: 'lib/assets/images/carpentry.png',
      imageWidth: 62,
      imageHeight: 62,
      imageRight: 4,
      imageBottom: -3,
      ghostSize: 52,
      ghostTop: 10,
      ghostRight: 8,
      showGhost: false,
    ),
    _PopularCardData(
      title: 'Electrical',
      image: 'lib/assets/images/electrical.png',
      imageWidth: 60,
      imageHeight: 60,
      imageRight: 6,
      imageBottom: -2,
      ghostSize: 50,
      ghostTop: 8,
      ghostRight: 10,
      showGhost: false,
    ),
  ];

  static const _categories = [
    _CategoryData(
      'Home\nMaintenance',
      'lib/assets/images/home_maintainance.png',
    ),
    _CategoryData(
      'Cleaning\nServices',
      'lib/assets/images/cleaning_services.png',
    ),
    _CategoryData(
      'Vehicle\nServices',
      'lib/assets/images/vehicle_services.png',
    ),
    _CategoryData(
      'Pet\nServices',
      'lib/assets/images/pet_services.png',
    ),
    _CategoryData(
      'CCTV\nInstallation',
      'lib/assets/images/cctv.png',
      imageSize: 42,
    ),
    _CategoryData(
      'Computer\nRepair',
      'lib/assets/images/computer.png',
    ),
    _CategoryData(
      'Car\nWash',
      'lib/assets/images/car_wash (2).png',
    ),
    _CategoryData(
      'Plumbing',
      'lib/assets/images/plumbng.png',
      imageSize: 42,
    ),
  ];

  static const _emergencyServices = [
    _EmergencyData(
      title: 'Plumbing\nEmergency',
      image: 'lib/assets/images/plumbing.png',
      imageSize: 56,
    ),
    _EmergencyData(
      title: 'Electrical\nEmergency',
      image: 'lib/assets/images/electrical.png',
      imageSize: 54,
      clipBottomFraction: 0.12,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFE6DC),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFE6DC),
              Color(0xFFFFF4EE),
              Color(0xFFFAF6F0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 120 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _buildSearchBar(),
                        const SizedBox(height: 22),
                        _sectionTitle('Popular Services'),
                        const SizedBox(height: 12),
                        _buildPopularGrid(),
                        const SizedBox(height: 16),
                        _sectionTitle('All Service Categories'),
                        const SizedBox(height: 14),
                        _buildCategoryGrid(context),
                        const SizedBox(height: 24),
                        _buildEmergencyHeader(),
                        const SizedBox(height: 12),
                        _buildEmergencyRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                final controller = Get.find<HomeController>();
                controller.selectNavigation(HomeController.navHome);
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF2D4C4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
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
          ),
          Text(
            'Services',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search for services...',
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF0E6),
              border: Border.all(color: const Color(0xFFFF5E00), width: 1.4),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'lib/assets/images/Voice.png',
              width: 15,
              height: 15,
              color: const Color(0xFFFF5E00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF2C2520),
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildPopularGrid() {
    const tallHeight = 168.0;
    const compactHeight = 79.0;
    const rowGap = 10.0;

    return Column(
      children: [
        for (var i = 0; i < _tallCards.length; i++) ...[
          if (i > 0) const SizedBox(height: rowGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PopularServiceCard(
                  data: _tallCards[i],
                  height: tallHeight,
                  borderRadius: 32,
                  titleFontSize: 16,
                  onTap: _tallCards[i].title.contains('Home')
                      ? () => Get.to(() => const HomeCleaningScreen())
                      : null,
                ),
              ),
              const SizedBox(width: rowGap),
              Expanded(
                child: Column(
                  children: [
                    _PopularServiceCard(
                      data: _compactCards[i * 2],
                      height: compactHeight,
                      borderRadius: 26,
                      titleFontSize: 14,
                    ),
                    const SizedBox(height: rowGap),
                    _PopularServiceCard(
                      data: _compactCards[i * 2 + 1],
                      height: compactHeight,
                      borderRadius: 26,
                      titleFontSize: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final itemWidth = (MediaQuery.sizeOf(context).width - 32 - 30) / 4;

    return Wrap(
      spacing: 10,
      runSpacing: 16,
      children: _categories.map((item) {
        final isCleaning = item.label.contains('Cleaning');
        return SizedBox(
          width: itemWidth,
          child: GestureDetector(
            onTap: isCleaning
                ? () => Get.to(() => const HomeCleaningScreen())
                : null,
            behavior: HitTestBehavior.opaque,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFFFF3EB),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _CategoryImage(
                  asset: item.image,
                  size: item.imageSize,
                  clipBottomFraction: item.clipBottomFraction,
                  alignment: item.imageAlignment,
                  scale: item.imageScale,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmergencyHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Emergency Services',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFDDCF)),
          ),
          child: Text(
            '24/7 AVAILABLE',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyRow() {
    return Row(
      children: [
        for (var i = 0; i < _emergencyServices.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _buildEmergencyCard(_emergencyServices[i])),
        ],
      ],
    );
  }

  Widget _buildEmergencyCard(_EmergencyData data) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD4C4),
                Color(0xFFFFEDE6),
                Color(0xFFFFFFFF),
              ],
              stops: [0.0, 0.38, 0.72],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 64, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFFFF5E00),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '15 min',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: Color(0xFFFF5E00),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 6,
                top: 0,
                bottom: 0,
                width: 58,
                child: Center(
                  child: _ServiceImage(
                    asset: data.image,
                    width: data.imageSize,
                    height: data.imageSize,
                    alignment: Alignment.center,
                    clipBottomFraction: data.clipBottomFraction,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularServiceCard extends StatelessWidget {
  final _PopularCardData data;
  final double height;
  final double borderRadius;
  final double titleFontSize;
  final VoidCallback? onTap;

  const _PopularServiceCard({
    required this.data,
    required this.height,
    required this.borderRadius,
    required this.titleFontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    if (data.showGhost)
                      Positioned(
                        top: data.ghostTop,
                        right: data.ghostRight,
                        child: Opacity(
                          opacity: 0.09,
                          child: _ServiceImage(
                            asset: data.image,
                            width: data.ghostSize,
                            height: data.ghostSize,
                            fit: data.imageFit,
                            alignment: data.imageAlignment,
                            clipBottomFraction: data.ghostClipBottomFraction,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 56,
                      child: Text(
                        data.title,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Positioned(
                      right: data.imageRight,
                      bottom: data.imageBottom,
                      child: _ServiceImage(
                        asset: data.image,
                        width: data.imageWidth,
                        height: data.imageHeight,
                        fit: data.imageFit,
                        alignment: data.imageAlignment,
                        clipBottomFraction: data.clipBottomFraction,
                        scale: data.imageScale,
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
}

class _ServiceImage extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final BoxFit fit;
  final Alignment alignment;
  final double clipBottomFraction;
  final double scale;

  const _ServiceImage({
    required this.asset,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.clipBottomFraction = 0,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
    );

    if (clipBottomFraction > 0) {
      image = ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1 - clipBottomFraction,
          child: image,
        ),
      );
    }

    if (scale != 1) {
      image = Transform.scale(
        scale: scale,
        alignment: alignment,
        child: image,
      );
    }

    return SizedBox(
      width: width,
      height: height * (clipBottomFraction > 0 ? 1 - clipBottomFraction : 1),
      child: clipBottomFraction > 0
          ? Align(
              alignment: Alignment.bottomCenter,
              child: image,
            )
          : image,
    );
  }
}

class _PopularCardData {
  final String title;
  final String image;
  final double imageWidth;
  final double imageHeight;
  final double imageRight;
  final double imageBottom;
  final BoxFit imageFit;
  final Alignment imageAlignment;
  final double clipBottomFraction;
  final double ghostSize;
  final double ghostTop;
  final double ghostRight;
  final double ghostClipBottomFraction;
  final bool showGhost;
  final double imageScale;

  const _PopularCardData({
    required this.title,
    required this.image,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageRight,
    required this.imageBottom,
    this.imageFit = BoxFit.contain,
    this.imageAlignment = Alignment.center,
    this.clipBottomFraction = 0,
    this.ghostSize = 0,
    this.ghostTop = 0,
    this.ghostRight = 0,
    this.ghostClipBottomFraction = 0,
    this.showGhost = true,
    this.imageScale = 1,
  });
}

class _CategoryData {
  final String label;
  final String image;
  final double imageSize;
  final double clipBottomFraction;
  final Alignment imageAlignment;
  final double imageScale;

  const _CategoryData(
    this.label,
    this.image, {
    this.imageSize = 44,
    this.clipBottomFraction = 0,
    this.imageAlignment = Alignment.center,
    this.imageScale = 1,
  });
}

class _CategoryImage extends StatelessWidget {
  final String asset;
  final double size;
  final double clipBottomFraction;
  final Alignment alignment;
  final double scale;

  const _CategoryImage({
    required this.asset,
    required this.size,
    this.clipBottomFraction = 0,
    this.alignment = Alignment.center,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      alignment: alignment,
      filterQuality: FilterQuality.high,
    );

    if (scale != 1) {
      image = Transform.scale(
        scale: scale,
        alignment: alignment,
        child: image,
      );
    }

    if (clipBottomFraction > 0) {
      image = ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1 - clipBottomFraction,
          child: image,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size * (clipBottomFraction > 0 ? 1 - clipBottomFraction : 1),
      child: clipBottomFraction > 0
          ? Align(alignment: Alignment.bottomCenter, child: image)
          : image,
    );
  }
}

class _EmergencyData {
  final String title;
  final String image;
  final double imageSize;
  final double clipBottomFraction;

  const _EmergencyData({
    required this.title,
    required this.image,
    this.imageSize = 58,
    this.clipBottomFraction = 0,
  });
}
