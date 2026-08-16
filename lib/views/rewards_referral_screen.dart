import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'redeem_detail_sheet.dart';

class RewardsReferralScreen extends StatelessWidget {
  const RewardsReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 22),
                    _buildSectionTitle('🎁  Redeem Rewards'),
                    const SizedBox(height: 12),
                    _buildRedeemList(),
                    const SizedBox(height: 22),
                    _buildSectionTitle(
                      '🎯  Weekly Mission',
                      trailing: true,
                    ),
                    const SizedBox(height: 12),
                    _buildMissionCard(
                      asset: 'lib/assets/images/groceryorders_icon.png',
                      title: 'Place 3 grocery orders',
                      subtitle: '2/3 orders completed this week',
                      reward: '+150 pts',
                      progress: 2 / 3,
                    ),
                    const SizedBox(height: 10),
                    _buildMissionCard(
                      asset: 'lib/assets/images/star_icon.png',
                      title: 'Rate 5 orders',
                      subtitle: '3/5 reviews submitted',
                      reward: '+75 pts',
                      progress: 3 / 5,
                    ),
                    const SizedBox(height: 10),
                    _buildMissionCard(
                      asset: 'lib/assets/images/invitefriens_icon.png',
                      title: 'Invite 5 friends',
                      subtitle: '0/5 referrals',
                      reward: '+100 MRU',
                      progress: 0,
                    ),
                    const SizedBox(height: 22),
                    _buildSectionTitle(
                      'Invite & Earn',
                      iconAsset: 'lib/assets/images/invite_earn_icon.png',
                    ),
                    const SizedBox(height: 12),
                    _buildInviteCard(),
                    const SizedBox(height: 22),
                    _buildSectionTitle(
                      'Cashback History',
                      trailing: true,
                    ),
                    const SizedBox(height: 12),
                    _buildCashbackHistory(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8DFD6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFF5E00),
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Rewards & Referral',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    bool trailing = false,
    String? iconAsset,
  }) {
    return Row(
      children: [
        if (iconAsset != null) ...[
          Image.asset(
            iconAsset,
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing)
          Text(
            'See All >',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REWARD BALANCE',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A9A9A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '1,820',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'pts ≈ 182 MRU',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFBDBDBD),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1208),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF904D25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFD87B3C),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'GOLD TIER',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFBE8D8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: Text(
              '550 pts to Platinum unlock',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFFCFCFCF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildTierProgress(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBenefitChip(
                  asset: 'lib/assets/images/delivery_icon.png',
                  label: 'Free Delivery',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBenefitChip(
                  icon: Icons.percent_rounded,
                  label: 'Offers',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBenefitChip(
                  asset: 'lib/assets/images/priority_icon.png',
                  label: 'Priority',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgress() {
    const tiers = ['Bronze', 'Silver', 'Gold', 'Platinum'];
    // Gold reached (index 2 of 3 segments) — ~75% filled toward platinum
    const progress = 0.78;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: width,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  height: 8,
                  width: width * progress,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(tiers.length, (index) {
            final active = index <= 2;
            return Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFFF5E00)
                        : const Color(0xFF6A6A6A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tiers[index],
                  style: GoogleFonts.outfit(
                    color: active
                        ? const Color(0xFFFF5E00)
                        : const Color(0xFF8A8A8A),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBenefitChip({
    IconData? icon,
    String? asset,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset != null)
            Image.asset(
              asset,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            )
          else if (icon != null)
            Icon(icon, color: const Color(0xFFFF5E00), size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemList() {
    final rewards = [
      {
        'store': 'Al Fantasia',
        'title': 'Premium Food Basket',
        'subtitle': 'Reach 5000 points to redeem your basket reward',
        'points': '5,000 pts',
        'progress': 0.6,
        'redeemable': false,
        'rewardValue': 'Free up to 1,000 MRU',
        'insides': ['Chicken Pasta', 'Chicken Tagine', 'Milk Dessert'],
        'image':
            'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800&auto=format&fit=crop',
      },
      {
        'store': 'Good Choice',
        'title': 'Free Delivery Pass',
        'subtitle': 'Reach 2500 points to unlock free delivery',
        'points': '2,500 pts',
        'progress': 0.55,
        'redeemable': false,
        'rewardValue': 'Free delivery for 30 days',
        'insides': ['Unlimited delivery', 'All stores', 'Priority support'],
        'image':
            'https://images.unsplash.com/photo-1513885535751-8b9238bd345a?w=500&auto=format&fit=crop',
      },
      {
        'store': 'Al Fantasia',
        'title': 'Premium Food Basket',
        'subtitle': 'Reach 5000 points to redeem your basket reward',
        'points': '5,000 pts',
        'progress': 1.0,
        'redeemable': true,
        'rewardValue': 'Free up to 1,000 MRU',
        'insides': ['Chicken Pasta', 'Chicken Tagine', 'Milk Dessert'],
        'image':
            'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800&auto=format&fit=crop',
      },
    ];

    return SizedBox(
      height: 268,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final item = rewards[index];
          final progress = (item['progress'] as double).clamp(0.0, 1.0);
          final redeemable = item['redeemable'] == true;

          final image = Image.network(
            item['image'] as String,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFD9D3CC),
              child: const Icon(Icons.card_giftcard_rounded),
            ),
          );

          return GestureDetector(
            onTap: () => RedeemDetailSheet.show(context, item),
            child: Container(
            width: 220,
            margin: EdgeInsets.only(
              right: index == rewards.length - 1 ? 0 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 105,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (redeemable)
                        image
                      else
                        ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                          child: image,
                        ),
                      if (!redeemable)
                        Container(color: Colors.black.withOpacity(0.28)),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: redeemable
                                    ? Colors.white
                                    : const Color(0xFFC8C2BC),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item['store'] as String,
                              style: GoogleFonts.outfit(
                                color: redeemable
                                    ? Colors.white
                                    : const Color(0xFFE8E4DF),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!redeemable)
                        const Center(
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['subtitle'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF8A8A8A),
                            fontSize: 10,
                            height: 1.3,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['points'] as String,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Container(
                                  height: 6,
                                  width: constraints.maxWidth,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE8E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                Container(
                                  height: 6,
                                  width: constraints.maxWidth * progress,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF5E00),
                                        Color(0xFFFFAE00),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: redeemable
                                ? null
                                : const Color(0xFFB0B0B0),
                            gradient: redeemable
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5E00),
                                      Color(0xFFFFAE00),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'Redeem',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
        },
      ),
    );
  }

  Widget _buildMissionCard({
    IconData? icon,
    String? asset,
    required String title,
    required String subtitle,
    required String reward,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                alignment: Alignment.center,
                child: asset != null
                    ? Image.asset(
                        asset,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      )
                    : Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8A7E76),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reward,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final value = progress.clamp(0.0, 1.0);
              return Stack(
                children: [
                  Container(
                    height: 7,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE6DF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  if (value > 0)
                    Container(
                      height: 7,
                      width: constraints.maxWidth * value,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5A00), Color(0xFFFF8F2E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refer a Friend, Earn 200 MRU',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Earn 200 MRU for every friend who joins SAIMPEX',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.95),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          _buildGlassPill(
            padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR CODE',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'AH-097',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.share,
                        color: Color(0xFFFF5E00),
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'SHARE',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInviteStat(value: '5', label: 'Joined'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInviteStat(value: '1000', label: 'Earned MRU'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPill({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 14,
    ),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }

  Widget _buildInviteStat({
    required String value,
    required String label,
  }) {
    return _buildGlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashbackHistory() {
    final items = [
      {
        'title': 'Marhaba grocery',
        'subtitle': '2 days ago · 3 order completed',
        'value': '+150 pts',
        'icon': 'lib/assets/images/grocery_icon.png',
      },
      {
        'title': 'Referral Reward',
        'subtitle': '2 days ago · 5 Referrals completed',
        'value': '+200 MRU',
        'icon': 'lib/assets/images/referralreward_icon.png',
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
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F6EC),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        item['icon'] as String,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['subtitle'] as String,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8A7E76),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item['value'] as String,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1FAF5A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEDE6DF),
                  indent: 14,
                  endIndent: 14,
                ),
            ],
          );
        }),
      ),
    );
  }
}