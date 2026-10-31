import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/select_location_controller.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../models/profile_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import 'cart_screen.dart';
import 'redeem_detail_sheet.dart';

/// Points balance, tier, redeemable baskets, weekly missions, referral and
/// points history, from customer/userPoints, loyalty, rewardList and
/// transactionHistory.
class RewardsReferralScreen extends StatefulWidget {
  const RewardsReferralScreen({super.key});

  @override
  State<RewardsReferralScreen> createState() => _RewardsReferralScreenState();
}

class _RewardsReferralScreenState extends State<RewardsReferralScreen> {
  num _points = 0;
  num _redeemableAmount = 0;
  Map<String, dynamic> _tier = const {};
  List<Map<String, dynamic>> _missions = const [];
  Map<String, dynamic> _referral = const {};
  List<Map<String, dynamic>> _baskets = const [];
  List<Map<String, dynamic>> _history = const [];
  bool _loading = true;
  String? _error;
  int? _claimingId;

  ProfileRepository get _repo => Get.find<ProfileRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Get.isRegistered<ProfileRepository>()) return;
    final language = apiLanguageCode();
    try {
      final results = await Future.wait([
        _repo.fetchUserPoints(language),
        _repo.loyalty(language),
      ]);
      final points = results[0] as ({num userPoints, num redeemableAmount});
      final loyalty = results[1] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _points = points.userPoints;
        _redeemableAmount = points.redeemableAmount;
        _tier = _map(loyalty['tier']);
        _missions = _list(loyalty['missions']);
        _referral = _map(loyalty['referral']);
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    // Baskets and history are secondary; a failure just hides them.
    try {
      final baskets = await _repo.rewardBaskets(
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: language,
      );
      if (mounted) setState(() => _baskets = baskets);
    } on ApiException {
      // Leave the section hidden.
    }
    try {
      final history = await _repo.rewardHistory(language);
      if (mounted) setState(() => _history = history);
    } on ApiException {
      // Leave the section hidden.
    }
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static List<Map<String, dynamic>> _list(dynamic value) => [
    if (value is List)
      for (final row in value)
        if (row is Map) Map<String, dynamic>.from(row),
  ];

  static num _num(dynamic value) => num.tryParse('${value ?? ''}') ?? 0;

  /// 1820 → "1,820".
  static String _grouped(num value) {
    final digits = value.round().toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  String _localized(Map<String, dynamic> row, String key) {
    final language = apiLanguageCode();
    final value = '${row['${key}_$language'] ?? ''}'.trim();
    return value.isNotEmpty ? value : '${row['${key}_en'] ?? ''}'.trim();
  }

  Future<void> _claim(Map<String, dynamic> mission) async {
    final id = int.tryParse('${mission['id']}');
    if (id == null || _claimingId != null) return;
    setState(() => _claimingId = id);
    try {
      final message = await _repo.claimMission(
        missionId: id,
        language: apiLanguageCode(),
      );
      showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      await _load();
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _claimingId = null);
    }
  }

  Future<void> _redeem(Map<String, dynamic> basket) async {
    final basketId = int.tryParse('${basket['id']}');
    final vendorId = int.tryParse('${basket['vendor_id']}');
    if (basketId == null || vendorId == null) return;
    try {
      final message = await _repo.redeemBasket(
        basketId: basketId,
        vendorId: vendorId,
        language: apiLanguageCode(),
      );
      showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      Get.to(() => const CartScreen(isFoodOrGrocery: true));
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  void _copyInvite() {
    final code = '${_referral['code'] ?? ''}';
    if (code.isEmpty) return;
    final amount = _num(_referral['reward_amount']).round();
    Clipboard.setData(
      ClipboardData(
        text: 'core_rewards_invite_message'.trParams({
          'code': code,
          'amount': '$amount',
        }),
      ),
    );
    showAppToast(
      'core_rewards_invite_copied'.tr,
      backgroundColor: const Color(0xFFFF5E00),
    );
  }

  Future<void> _enterCode() async {
    final controller = TextEditingController();
    final code = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'core_rewards_enter_code_title'.tr,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(hintText: 'core_rewards_code_hint'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: GoogleFonts.outfit(color: const Color(0xFF7A6A60)),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: controller.text.trim()),
            child: Text(
              'core_rewards_apply'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty) return;
    try {
      final message = await _repo.applyReferral(
        code: code,
        language: apiLanguageCode(),
      );
      showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      await _load();
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

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
              child: _loading && _tier.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5E00),
                      ),
                    )
                  : _tier.isEmpty && _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFFF5E00),
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBalanceCard(),
                            if (_baskets.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildSectionTitle(
                                '🎁  ${'core_rewards_redeem_rewards'.tr}',
                              ),
                              const SizedBox(height: 12),
                              _buildRedeemList(),
                            ],
                            if (_missions.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildSectionTitle(
                                '🎯  ${'core_rewards_weekly_mission'.tr}',
                              ),
                              const SizedBox(height: 12),
                              for (var i = 0; i < _missions.length; i++) ...[
                                if (i > 0) const SizedBox(height: 10),
                                _buildMissionCard(_missions[i]),
                              ],
                            ],
                            const SizedBox(height: 22),
                            _buildSectionTitle(
                              'core_rewards_invite_earn'.tr,
                              iconAsset:
                                  'lib/assets/images/invite_earn_icon.png',
                            ),
                            const SizedBox(height: 12),
                            _buildInviteCard(),
                            if (_referral['can_apply_code'] == true) ...[
                              const SizedBox(height: 10),
                              Center(
                                child: GestureDetector(
                                  onTap: _enterCode,
                                  child: Text(
                                    'core_rewards_have_code'.tr,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFF5E00),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (_history.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildSectionTitle(
                                'core_rewards_points_history'.tr,
                              ),
                              const SizedBox(height: 12),
                              _buildHistory(),
                            ],
                          ],
                        ),
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
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'core_rewards_title'.tr,
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

  Widget _buildSectionTitle(String title, {String? iconAsset}) {
    return Row(
      children: [
        if (iconAsset != null) ...[
          Image.asset(iconAsset, width: 20, height: 20, fit: BoxFit.contain),
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
      ],
    );
  }

  Widget _buildBalanceCard() {
    final tierName = '${_tier['name'] ?? ''}';
    final nextName = '${_tier['next_name'] ?? ''}';
    final toNext = _num(_tier['next_points']) - _num(_tier['points']);
    final perks = [
      for (final perk in (_tier['perks'] as List? ?? const [])) '$perk',
    ];
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
                      'core_rewards_reward_balance'.tr,
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
                          _grouped(_points),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'core_rewards_pts_approx'.trParams({
                            'amount': _grouped(_redeemableAmount),
                          }),
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
              if (tierName.isNotEmpty)
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
                        'core_rewards_tier_badge'.trParams({
                          'tier': tierName.toUpperCase(),
                        }),
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
              nextName.isEmpty
                  ? 'core_rewards_top_tier'.tr
                  : 'core_rewards_to_next_tier'.trParams({
                      'points': _grouped(toNext < 0 ? 0 : toNext),
                      'tier': nextName,
                    }),
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
          if (perks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < perks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _buildBenefitChip(perks[i])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTierProgress() {
    final tiers = [
      for (final tier in (_tier['tiers'] as List? ?? const []))
        if (tier is Map) '${tier['name']}',
    ];
    if (tiers.length < 2) return const SizedBox.shrink();
    final currentIndex = tiers.indexOf('${_tier['name'] ?? ''}');
    final within = _num(_tier['progress']).toDouble().clamp(0.0, 1.0);
    // Each gap between tier dots is one segment of the bar.
    final progress = currentIndex < 0
        ? 0.0
        : ((currentIndex + (currentIndex < tiers.length - 1 ? within : 0)) /
                  (tiers.length - 1))
              .clamp(0.0, 1.0);

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
            final active = index <= currentIndex;
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

  Widget _buildBenefitChip(String label) {
    final asset = switch (label) {
      'Free Delivery' => 'lib/assets/images/delivery_icon.png',
      'Priority' => 'lib/assets/images/priority_icon.png',
      _ => null,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset != null)
            Image.asset(asset, width: 24, height: 24, fit: BoxFit.contain)
          else
            const Icon(
              Icons.percent_rounded,
              color: Color(0xFFFF5E00),
              size: 24,
            ),
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

  /// A rewardList basket in the shape RedeemDetailSheet and the cards use.
  Map<String, dynamic> _basketCard(Map<String, dynamic> basket) {
    final needed = _num(basket['basket_redeem_points']);
    final have = _num(basket['user_points']);
    final language = apiLanguageCode();
    final vendor = '${basket['vendor_name_$language'] ?? ''}'.trim();
    return {
      'store': vendor.isNotEmpty ? vendor : '${basket['vendor_name'] ?? ''}',
      'title': _localized(basket, 'name'),
      'subtitle': _localized(basket, 'description'),
      'points': 'core_rewards_pts'.trParams({'points': _grouped(needed)}),
      'progress': needed <= 0 ? 1.0 : (have / needed).toDouble(),
      'redeemable':
          basket['can_redeem'] == true &&
          basket['available'] != false &&
          basket['purchase_available'] != false,
      'rewardValue': 'core_rewards_basket_value'.trParams({
        'amount': _grouped(_num(basket['basket_price'])),
      }),
      'image': ApiConstants.mediaUrl('${basket['image'] ?? ''}') ?? '',
    };
  }

  Widget _buildRedeemList() {
    return SizedBox(
      height: 268,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _baskets.length,
        itemBuilder: (context, index) {
          final basket = _baskets[index];
          final item = _basketCard(basket);
          final progress = (item['progress'] as double).clamp(0.0, 1.0);
          final redeemable = item['redeemable'] == true;
          final placeholder = Container(
            color: const Color(0xFFD9D3CC),
            child: const Icon(Icons.card_giftcard_rounded),
          );
          final imageUrl = item['image'] as String;
          final image = imageUrl.isEmpty
              ? placeholder
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder,
                );

          return GestureDetector(
            onTap: () => RedeemDetailSheet.show(
              context,
              item,
              onRedeem: () => _redeem(basket),
            ),
            child: Container(
              width: 220,
              margin: EdgeInsetsDirectional.only(
                end: index == _baskets.length - 1 ? 0 : 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                              0.2126, 0.7152, 0.0722, 0, 0, //
                              0.2126, 0.7152, 0.0722, 0, 0, //
                              0.2126, 0.7152, 0.0722, 0, 0, //
                              0, 0, 0, 1, 0,
                            ]),
                            child: image,
                          ),
                        if (!redeemable)
                          Container(
                            color: Colors.black.withValues(alpha: 0.28),
                          ),
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
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
                              Expanded(
                                child: Text(
                                  item['store'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: redeemable
                                        ? Colors.white
                                        : const Color(0xFFE8E4DF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                          _progressBar(
                            progress,
                            height: 6,
                            track: const Color(0xFFEDE8E2),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: redeemable ? () => _redeem(basket) : null,
                            child: Container(
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
                                'core_rewards_redeem'.tr,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
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
        },
      ),
    );
  }

  Widget _progressBar(double value, {double height = 7, Color? track}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clamped = value.clamp(0.0, 1.0);
        return Stack(
          children: [
            Container(
              height: height,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: track ?? const Color(0xFFEDE6DF),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            if (clamped > 0)
              Container(
                height: height,
                width: constraints.maxWidth * clamped,
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
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final metric = '${mission['metric'] ?? ''}';
    final done = _num(mission['done']).toInt();
    final target = _num(mission['target']).toInt();
    final asset = switch (metric) {
      'ratings' => 'lib/assets/images/star_icon.png',
      'referrals' => 'lib/assets/images/invitefriens_icon.png',
      _ => 'lib/assets/images/groceryorders_icon.png',
    };
    final progressKey = switch (metric) {
      'ratings' => 'core_rewards_mission_reviews',
      'referrals' => 'core_rewards_mission_referrals',
      _ => 'core_rewards_mission_orders',
    };
    final value = _num(mission['reward_value']).round();
    final reward = mission['reward_type'] == 'wallet'
        ? 'core_rewards_plus_mru'.trParams({'amount': '$value'})
        : 'core_rewards_plus_pts'.trParams({'points': '$value'});
    final claimed = mission['claimed'] == true;
    final claimable = mission['claimable'] == true;
    final claiming = _claimingId == int.tryParse('${mission['id']}');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                child: Image.asset(
                  asset,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mission['title'] ?? ''}',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      progressKey.trParams({
                        'done': '$done',
                        'target': '$target',
                      }),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8A7E76),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: claimable && !claiming ? () => _claim(mission) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: claimable ? null : const Color(0xFFFFF0E6),
                    gradient: claimable
                        ? const LinearGradient(
                            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    claimed
                        ? 'core_rewards_claimed'.tr
                        : claimable
                        ? (claiming
                              ? 'core_rewards_claiming'.tr
                              : 'core_rewards_claim'.trParams({
                                  'reward': reward,
                                }))
                        : reward,
                    style: GoogleFonts.outfit(
                      color: claimable ? Colors.white : const Color(0xFFFF5E00),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _progressBar(target <= 0 ? 0 : done / target),
        ],
      ),
    );
  }

  Widget _buildInviteCard() {
    final amount = _grouped(_num(_referral['reward_amount']));
    final code = '${_referral['code'] ?? ''}';
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
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'core_rewards_refer_title'.trParams({'amount': amount}),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'core_rewards_refer_body'.trParams({'amount': amount}),
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          _buildGlassPill(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'core_rewards_your_code'.tr,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        code.isEmpty ? '—' : code,
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
                GestureDetector(
                  onTap: _copyInvite,
                  child: Container(
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
                          Icons.copy_rounded,
                          color: Color(0xFFFF5E00),
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'core_rewards_copy'.tr,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInviteStat(
                  value: '${_num(_referral['rewarded']).toInt()}',
                  label: 'core_rewards_joined'.tr,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInviteStat(
                  value: _grouped(_num(_referral['earned'])),
                  label: 'core_rewards_earned_mru'.tr,
                ),
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
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }

  Widget _buildInviteStat({required String value, required String label}) {
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

  Widget _buildHistory() {
    final language = apiLanguageCode();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAD8C9)),
      ),
      child: Column(
        children: List.generate(_history.length, (index) {
          final row = _history[index];
          final credited = _num(row['type']).toInt() == 1;
          final basket =
              '${row['basket_name_$language'] ?? row['basket_name_en'] ?? ''}'
                  .trim();
          // The API spells it "vedor_name".
          final vendor =
              '${row['vedor_name_$language'] ?? row['vedor_name_en'] ?? ''}'
                  .trim();
          final code = '${row['order_code'] ?? ''}'.trim();
          final date = '${row['date'] ?? ''}'.split('T').first.split(' ').first;
          final points = _num(row['points']).abs();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: credited
                            ? const Color(0xFFE6F6EC)
                            : const Color(0xFFFFF0E6),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        basket.isNotEmpty
                            ? 'lib/assets/images/referralreward_icon.png'
                            : 'lib/assets/images/grocery_icon.png',
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
                            vendor.isNotEmpty
                                ? vendor
                                : (basket.isNotEmpty
                                      ? basket
                                      : 'core_rewards_points'.tr),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              date,
                              if (basket.isNotEmpty && vendor.isNotEmpty)
                                basket,
                              if (code.isNotEmpty) '#$code',
                            ].where((part) => part.isNotEmpty).join(' · '),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8A7E76),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${credited ? '+' : '-'}${'core_rewards_pts'.trParams({'points': _grouped(points)})}',
                      style: GoogleFonts.outfit(
                        color: credited
                            ? const Color(0xFF1FAF5A)
                            : const Color(0xFFFF5E00),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (index != _history.length - 1)
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
