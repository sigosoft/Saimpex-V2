import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../controllers/home_controller.dart';
import 'my_favourites_screen.dart';
import 'rewards_referral_screen.dart';
import 'saved_addresses_screen.dart';
import 'my_subscriptions_screen.dart';
import 'my_schedules_screen.dart';
import 'app_preferences_screen.dart';
import 'help_support_screen.dart';
import 'terms_conditions_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../navigation/bottom_nav_router.dart';

class AccountScreen extends StatefulWidget {
  final bool showBottomNav;

  const AccountScreen({super.key, this.showBottomNav = true});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _showDeleteMenu = false;

  void _openDeleteConfirmSheet() {
    setState(() => _showDeleteMenu = false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _DeleteAccountSheet(),
    );
  }

  void _openLogoutConfirmSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _LogoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFF5E00),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      Text(
                        'Settings',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsCard(context),
                      const SizedBox(height: 28),
                      _buildSocialRow(),
                      const SizedBox(height: 16),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'V2.8.2',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Check for update',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.showBottomNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNavBar(
                selectedIndex: HomeController.navProfile,
                onTap: BottomNavRouter.go,
              ),
            ),
          if (_showDeleteMenu) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showDeleteMenu = false),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 52,
              right: 16,
              child: _buildDeleteMenuPopup(),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildDeleteMenuPopup() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _openDeleteConfirmSheet,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF5E00),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Delete Account',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFFF5E00),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 22,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        gradient: LinearGradient(
          colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
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
              Expanded(
                child: Text(
                  'Account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showDeleteMenu = !_showDeleteMenu),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahmed Ould Salem',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+222 45 12 34 56',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E00),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  iconAsset: 'lib/assets/images/wallet.png',
                  label: 'WALLET',
                  value: '2,450',
                  unit: 'MRU',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  iconAsset: 'lib/assets/images/Coin.png',
                  label: 'REWARD POINTS',
                  value: '1,820',
                  onTap: () => Get.to(() => const RewardsReferralScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String iconAsset,
    required String label,
    required String value,
    String? unit,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      height: 124,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -26,
            child: Opacity(
              opacity: 0.50,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFFFF9A5A),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'lib/assets/images/Ellipse.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    iconAsset,
                    width: 17,
                    height: 17,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          unit,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Orders',
        'icon': Icons.assignment_outlined,
        'bg': const Color(0xFFF1E9FF),
        'fg': const Color(0xFF8B5CF6),
      },
      {
        'label': 'My Favourite',
        'icon': Icons.favorite_border_rounded,
        'bg': const Color(0xFFFFE8EC),
        'fg': const Color(0xFFEF4444),
      },
      {
        'label': 'My Schedules',
        'icon': Icons.calendar_today_outlined,
        'bg': const Color(0xFFE8F1FF),
        'fg': const Color(0xFF3B82F6),
      },
      {
        'label': 'Reward & Referral',
        'asset': 'lib/assets/images/reward.png',
        'bg': const Color(0xFFFFF0E6),
      },
      {
        'label': 'Saved Addresses',
        'icon': Icons.location_on_outlined,
        'bg': const Color(0xFFFFF6E0),
        'fg': const Color(0xFFF59E0B),
      },
      {
        'label': 'My Subscriptions',
        'asset': 'lib/assets/images/subscriptions.png',
        'bg': const Color(0xFFFFE8F3),
      },
    ];

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.35,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        final asset = action['asset'] as String?;
        return GestureDetector(
          onTap: () {
            if (action['label'] == 'Orders') {
              BottomNavRouter.go(HomeController.navOrders);
            } else if (action['label'] == 'My Favourite') {
              Get.to(() => const MyFavouritesScreen());
            } else if (action['label'] == 'Reward & Referral') {
              Get.to(() => const RewardsReferralScreen());
            } else if (action['label'] == 'Saved Addresses') {
              Get.to(() => const SavedAddressesScreen());
            } else if (action['label'] == 'My Subscriptions') {
              Get.to(() => const MySubscriptionsScreen());
            } else if (action['label'] == 'My Schedules') {
              Get.to(() => const MySchedulesScreen());
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: action['bg'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: asset != null
                      ? Image.asset(
                          asset,
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          action['icon'] as IconData,
                          color: action['fg'] as Color,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: action['label'] == 'My Favourite'
                      ? Obx(() {
                          final homeController =
                              Get.isRegistered<HomeController>()
                                  ? Get.find<HomeController>()
                                  : Get.put(HomeController());
                          final count = homeController.favouritesCount;
                          return Text(
                            count > 0
                                ? 'My Favourite ($count)'
                                : 'My Favourite',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          );
                        })
                      : Text(
                          action['label'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    final items = [
      {
        'label': 'Language',
        'icon': Icons.language_rounded,
        'trailing': 'English',
        'isLogout': false,
      },
      {
        'label': 'App Preferences',
        'icon': Icons.settings_outlined,
        'isLogout': false,
      },
      {
        'label': 'Help & Support',
        'icon': Icons.help_outline_rounded,
        'isLogout': false,
      },
      {
        'label': 'Terms & Conditions',
        'icon': Icons.description_outlined,
        'isLogout': false,
      },
      {
        'label': 'Privacy & Security',
        'asset': 'lib/assets/images/sheild_icon.png',
        'isLogout': false,
      },
      {
        'label': 'About Us',
        'icon': Icons.info_outline_rounded,
        'isLogout': false,
      },
      {
        'label': 'Logout',
        'icon': Icons.logout_rounded,
        'isLogout': true,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAD8C9)),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLogout = item['isLogout'] == true;
          final isLast = index == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () {
                  if (isLogout) {
                    _openLogoutConfirmSheet();
                  } else if (item['label'] == 'App Preferences') {
                    Get.to(() => const AppPreferencesScreen());
                  } else if (item['label'] == 'Help & Support') {
                    Get.to(() => const HelpSupportScreen());
                  } else if (item['label'] == 'Terms & Conditions') {
                    Get.to(() => const TermsConditionsScreen());
                  } else if (item['label'] == 'Privacy & Security') {
                    Get.to(
                      () => const TermsConditionsScreen(
                        title: 'Privacy & Security',
                      ),
                    );
                  } else if (item['label'] == 'About Us') {
                    Get.to(
                      () => const TermsConditionsScreen(
                        title: 'About Us',
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(18) : Radius.zero,
                  bottom: isLast ? const Radius.circular(18) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      item['asset'] != null
                          ? Image.asset(
                              item['asset'] as String,
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              color: Colors.black,
                            )
                          : Icon(
                              item['icon'] as IconData,
                              color: isLogout
                                  ? AppColors.primaryOrange
                                  : Colors.black,
                              size: 20,
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['label'] as String,
                          style: GoogleFonts.outfit(
                            color: isLogout
                                ? AppColors.primaryOrange
                                : const Color(0xFF2C2520),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item['trailing'] != null) ...[
                        Text(
                          item['trailing'] as String,
                          style: GoogleFonts.outfit(
                            color: AppColors.primaryOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isLogout
                            ? AppColors.primaryOrange
                            : const Color(0xFFA59A94),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF3EFEA),
                  indent: 46,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSocialRow() {
    final socials = [
      {
        'label': 'Instagram',
        'asset': 'lib/assets/images/Instagram.png',
      },
      {
        'label': 'Facebook',
        'asset': 'lib/assets/images/facebook.png',
      },
      {
        'label': 'WhatsApp',
        'asset': 'lib/assets/images/whatsapp.png',
      },
      {
        'label': 'YouTube',
        'asset': 'lib/assets/images/youtube.png',
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: socials.map((social) {
          return Column(
            children: [
              ClipOval(
                child: Image.asset(
                  social['asset'] as String,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                social['label'] as String,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DeleteAccountSheet extends StatelessWidget {
  const _DeleteAccountSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        28,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Delete Account',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Are you sure you want to delete your account?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF7A6A60),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.back();
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EA),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      'Yes',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      'No',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        28,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Logout',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EA),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      'No',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.back();
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      'Yes',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
