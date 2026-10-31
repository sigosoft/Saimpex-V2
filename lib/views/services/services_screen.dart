import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import '../../constants/text_styles.dart';
import 'car_wash_screen.dart';
import 'home_cleaning_screen.dart';
import 'laundry_services_screen.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/home_background_blend.dart';

class ServicesScreen extends StatelessWidget {
  final bool showBottomNav;

  const ServicesScreen({super.key, this.showBottomNav = true});

  /// Display keys for the card titles. The titles themselves stay English
  /// because `_verticalOf` matches on them.
  static const _titleKeys = {
    'Home\nCleaning': 'svc_cat_home_cleaning',
    'Car\nWash': 'svc_cat_car_wash',
    'Plumbing': 'svc_cat_plumbing',
    'Laundry': 'svc_cat_laundry',
    'Carpentry': 'svc_cat_carpentry',
    'Electrical': 'svc_cat_electrical',
    'Home\nMaintenance': 'svc_cat_home_maintenance',
    'Cleaning\nServices': 'svc_cat_cleaning_services',
    'Vehicle\nServices': 'svc_cat_vehicle_services',
    'Pet\nServices': 'svc_cat_pet_services',
    'CCTV\nInstallation': 'svc_cat_cctv',
    'Computer\nRepair': 'svc_cat_computer_repair',
    'Plumbing\nEmergency': 'svc_cat_plumbing_emergency',
    'Electrical\nEmergency': 'svc_cat_electrical_emergency',
  };

  static String _label(String title) => (_titleKeys[title] ?? title).tr;

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
    _CategoryData('Pet\nServices', 'lib/assets/images/pet_services.png'),
    _CategoryData(
      'CCTV\nInstallation',
      'lib/assets/images/cctv.png',
      imageSize: 42,
    ),
    _CategoryData('Computer\nRepair', 'lib/assets/images/computer.png'),
    _CategoryData('Car\nWash', 'lib/assets/images/car_wash (2).png'),
    _CategoryData('Plumbing', 'lib/assets/images/plumbng.png', imageSize: 42),
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
        statusBarColor: Color(0xFFFDDCC9),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: HomeBackgroundBlend(
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
                        _sectionTitle('svc_popular_services'.tr),
                        const SizedBox(height: 12),
                        _buildPopularGrid(),
                        const SizedBox(height: 16),
                        _sectionTitle('svc_all_categories'.tr),
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
            alignment: AlignmentDirectional.centerStart,
            child: showBottomNav
                ? AppBackButton(
                    onTap: () {
                      final controller = Get.find<HomeController>();
                      controller.selectNavigation(HomeController.navHome);
                    },
                  )
                : const SizedBox(width: 38),
          ),
          Text('svc_services_title'.tr, style: AppTextStyles.heading()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF7A6A60), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'svc_search_services_hint'.tr,
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFF8A8078),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEBE2),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'lib/assets/images/Voice.png',
              width: 16,
              height: 16,
              color: const Color(0xFFFF5E00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppTextStyles.title());
  }

  /// The vertical behind a card (home_cleaning, car_wash, laundry), or null
  /// for tiles that aren't a service vertical yet.
  static String? _verticalOf(String title) {
    final key = title.replaceAll('\n', ' ').toLowerCase();
    if (key.contains('cleaning')) return 'home_cleaning';
    if (key.contains('car wash')) return 'car_wash';
    if (key.contains('laundry')) return 'laundry';
    return null;
  }

  /// False for a service the admin switched off (is_enabled false).
  static bool _shown(String title) {
    final slug = _verticalOf(title);
    if (slug == null || !Get.isRegistered<HomeController>()) return true;
    return Get.find<HomeController>().isVerticalEnabled(slug);
  }

  static VoidCallback? _open(String title) => switch (_verticalOf(title)) {
    'home_cleaning' => () => Get.to(() => const HomeCleaningScreen()),
    'car_wash' => () => Get.to(() => const CarWashScreen()),
    'laundry' => () => Get.to(() => const LaundryServicesScreen()),
    _ => null,
  };

  Widget _buildPopularGrid() {
    const tallHeight = 168.0;
    const compactHeight = 79.0;
    const rowGap = 10.0;
    // Switched-off services are left out and the grid closes up.
    final tall = _tallCards.where((card) => _shown(card.title)).toList();
    final compact = _compactCards.where((card) => _shown(card.title)).toList();
    final rowCount = tall.length > (compact.length + 1) ~/ 2
        ? tall.length
        : (compact.length + 1) ~/ 2;

    Widget compactCard(_PopularCardData data) => _PopularServiceCard(
      data: data,
      height: compactHeight,
      borderRadius: 26,
      titleFontSize: 14,
      onTap: _open(data.title),
    );

    return Column(
      children: [
        for (var i = 0; i < rowCount; i++) ...[
          if (i > 0) const SizedBox(height: rowGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (i < tall.length) ...[
                Expanded(
                  child: _PopularServiceCard(
                    data: tall[i],
                    height: tallHeight,
                    borderRadius: 32,
                    titleFontSize: 16,
                    onTap: _open(tall[i].title),
                  ),
                ),
                const SizedBox(width: rowGap),
                Expanded(
                  child: Column(
                    children: [
                      if (i * 2 < compact.length) compactCard(compact[i * 2]),
                      if (i * 2 + 1 < compact.length) ...[
                        const SizedBox(height: rowGap),
                        compactCard(compact[i * 2 + 1]),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // No tall card left for this row: the small cards share it.
                if (i * 2 < compact.length)
                  Expanded(child: compactCard(compact[i * 2])),
                const SizedBox(width: rowGap),
                if (i * 2 + 1 < compact.length)
                  Expanded(child: compactCard(compact[i * 2 + 1]))
                else
                  const Spacer(),
              ],
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
      children: _categories.where((item) => _shown(item.label)).map((item) {
        return SizedBox(
          width: itemWidth,
          child: GestureDetector(
            onTap: _open(item.label),
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
                      colors: [Color(0xFFFFFFFF), Color(0xFFFFF3EB)],
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
                  _label(item.label),
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
            'svc_emergency_services'.tr,
            style: AppTextStyles.title(),
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
            'svc_available_24_7'.tr,
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
              colors: [Color(0xFFFFD4C4), Color(0xFFFFEDE6), Color(0xFFFFFFFF)],
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
                padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 64, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ServicesScreen._label(data.title),
                      style: AppTextStyles.title().copyWith(
                        fontSize: 13,
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
                          'svc_minutes'.trParams({'count': '15'}),
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
              PositionedDirectional(
                end: 6,
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
                    PositionedDirectional(
                      top: 16,
                      start: 16,
                      end: 56,
                      child: Text(
                        ServicesScreen._label(data.title),
                        style: AppTextStyles.title().copyWith(
                          fontSize: titleFontSize,
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
      image = Transform.scale(scale: scale, alignment: alignment, child: image);
    }

    return SizedBox(
      width: width,
      height: height * (clipBottomFraction > 0 ? 1 - clipBottomFraction : 1),
      child: clipBottomFraction > 0
          ? Align(alignment: Alignment.bottomCenter, child: image)
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
    this.imageAlignment = Alignment.center,
    this.clipBottomFraction = 0,
    this.ghostSize = 0,
    this.ghostTop = 0,
    this.ghostRight = 0,
    this.ghostClipBottomFraction = 0,
    this.showGhost = true,
    this.imageScale = 1,
  }) : imageFit = BoxFit.contain;
}

class _CategoryData {
  final String label;
  final String image;
  final double imageSize;
  final double clipBottomFraction;
  final Alignment imageAlignment;
  final double imageScale;

  const _CategoryData(this.label, this.image, {this.imageSize = 44})
    : imageScale = 1,
      imageAlignment = Alignment.center,
      clipBottomFraction = 0;
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
      image = Transform.scale(scale: scale, alignment: alignment, child: image);
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
