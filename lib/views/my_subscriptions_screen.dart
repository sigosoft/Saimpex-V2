import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/network/api_exception.dart';
import '../models/water_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import 'home_screen.dart';
import 'water/water_subscription_screen.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  int _selectedTab = 0; // 0 = Active, 1 = Inactive
  List<Map<String, dynamic>> _subscriptions = const [];
  bool _loading = true;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Get.isRegistered<WaterRepository>()) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await Get.find<WaterRepository>().fetchSubscriptions(
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() => _subscriptions = list.map(_cardData).toList());
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Adds the labels each card shows for its subscription state.
  Map<String, dynamic> _cardData(Map<String, dynamic> sub) {
    final state = '${sub['state']}';
    final card = Map<String, dynamic>.from(sub);
    switch (state) {
      case 'paused':
        card.addAll({
          'leftLabel': 'Paused Until',
          'leftValue': _orDash(sub['pauseUntil']),
          'rightLabel': 'Type',
          'rightValue': _orDash(sub['frequency']),
          'action': 'Resume Subscription',
          'actionIcon': Icons.play_arrow_rounded,
        });
      case 'cancelled':
        card.addAll({
          'leftLabel': 'Started On',
          'leftValue': _orDash(sub['startDate']),
          'rightLabel': 'Ends On',
          'rightValue': _orDash(sub['endDate']),
          'action': 'Subscribe Again',
        });
      default:
        card.addAll({
          'leftLabel': 'Next Delivery',
          'leftValue': _orDash(sub['nextDelivery']),
          'rightLabel': 'Type',
          'rightValue': _orDash(sub['frequency']),
        });
    }
    return card;
  }

  String _orDash(dynamic value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? '—' : text;
  }

  bool _isActiveState(String state) => state == 'active' || state == 'new';

  Future<void> _changeSubscription(
    Map<String, dynamic> item,
    Future<String> Function(WaterRepository repo, int id) action,
  ) async {
    final id = item['id'];
    if (id is! int || id < 1 || _busyId != null) return;
    setState(() => _busyId = id);
    try {
      final message = await action(Get.find<WaterRepository>(), id);
      if (!mounted) return;
      if (message.isNotEmpty) {
        showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      }
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _confirmCancel(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: const Text('Future deliveries for this plan will stop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _changeSubscription(
      item,
      (repo, id) => repo.cancelSubscription(
        subscriptionId: id,
        language: apiLanguageCode(),
      ),
    );
  }

  void _onInactiveAction(Map<String, dynamic> item) {
    if (item['state'] == 'paused') {
      _changeSubscription(
        item,
        (repo, id) => repo.resumeSubscription(
          subscriptionId: id,
          language: apiLanguageCode(),
        ),
      );
      return;
    }
    Get.to(() => const WaterSubscriptionScreen());
  }

  Widget _subscriptionImage(Map<String, dynamic> item) {
    final url = '${item['imageUrl'] ?? ''}';
    const fallback = 'lib/assets/images/19L water.png';
    if (url.isEmpty) return Image.asset(fallback, fit: BoxFit.contain);
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Image.asset(fallback, fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _subscriptions
        .where(
          (sub) => _isActiveState('${sub['state']}') == (_selectedTab == 0),
        )
        .toList();

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _buildTabs(),
            ),
            Expanded(
              child: _loading && _subscriptions.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5E00),
                      ),
                    )
                  : list.isEmpty
                  ? Center(
                      child: Text(
                        _selectedTab == 0
                            ? 'No active subscriptions'
                            : 'No inactive subscriptions',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return _buildSubscriptionCard(list[index]);
                      },
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
          AppBackButton(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Get.back();
              } else {
                Get.offAll(() => const HomeScreen());
              }
            },
          ),
          Expanded(
            child: Text(
              'My Subscriptions',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
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

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              label: 'Active Subscriptions',
              index: 0,
              badgeCount: _subscriptions
                  .where((sub) => _isActiveState('${sub['state']}'))
                  .length,
            ),
          ),
          Expanded(
            child: _buildTabItem(
              label: 'Inactive Subscriptions',
              index: 1,
              badgeCount: _subscriptions
                  .where((sub) => !_isActiveState('${sub['state']}'))
                  .length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required int index,
    required int badgeCount,
  }) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFF5E00) : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: selected ? Colors.white : const Color(0xFF8C7E75),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (selected && badgeCount > 0)
            Positioned(
              top: -5,
              right: 6,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E00),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFFE8F5E9);
      case 'Cancelled':
        return const Color(0xFFFFEAEA);
      case 'Expired':
        return const Color(0xFFBDB8B3);
      case 'Paused':
        return const Color(0xFFFFF4CC);
      default:
        return const Color(0xFFF0EAE3);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF2E7D32);
      case 'Cancelled':
        return const Color(0xFFD32F2F);
      case 'Expired':
        return const Color(0xFF5A5A5A);
      case 'Paused':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF8A7E76);
    }
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString();
    final isExpired = item['state'] == 'cancelled';
    final isActive = _isActiveState('${item['state']}');
    final busy = _busyId != null && _busyId == item['id'];
    final primaryText =
        isExpired ? const Color(0xFF6B6662) : const Color(0xFF1A1A1A);
    final secondaryText =
        isExpired ? const Color(0xFF8A847E) : const Color(0xFF8C7E75);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(isActive ? 16 : 14),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xFFD8D4CF) : Colors.white,
        borderRadius: BorderRadius.circular(isActive ? 24 : 20),
        border: isActive
            ? null
            : Border.all(
                color: isExpired
                    ? const Color(0xFFC9C5C1)
                    : const Color(0xFFE8E0D8),
                width: 1,
              ),
        boxShadow: isExpired
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: isActive ? 14 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          if (isActive)
            _buildActiveHeader(item)
          else
            _buildInactiveHeader(
              item,
              primaryText: primaryText,
              secondaryText: secondaryText,
              isExpired: isExpired,
              status: status,
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  label: (item['leftLabel'] ?? '').toString(),
                  value: (item['leftValue'] ?? '').toString(),
                  muted: isExpired,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBox(
                  label: (item['rightLabel'] ?? '').toString(),
                  value: (item['rightValue'] ?? '').toString(),
                  muted: isExpired,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isActive)
            Row(
              children: [
                Expanded(
                  child: _buildCancelButton(
                    label: 'Cancel Subscription',
                    onTap: busy ? () {} : () => _confirmCancel(item),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGradientButton(
                    icon: Icons.pause_rounded,
                    label: busy ? 'Please wait...' : 'Pause Subscription',
                    onTap: busy
                        ? () {}
                        : () => _changeSubscription(
                            item,
                            (repo, id) => repo.pauseSubscription(
                              subscriptionId: id,
                              language: apiLanguageCode(),
                            ),
                          ),
                    pill: true,
                  ),
                ),
              ],
            )
          else
            _buildGradientButton(
              icon: item['actionIcon'] as IconData?,
              label: busy
                  ? 'Please wait...'
                  : (item['action'] ?? 'Subscribe Again').toString(),
              onTap: busy ? () {} : () => _onInactiveAction(item),
              fullWidth: true,
            ),
        ],
      ),
    );
  }

  Widget _buildActiveHeader(Map<String, dynamic> item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4FC),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(6),
          child: _subscriptionImage(item),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (item['title'] ?? '').toString(),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                (item['subtitle'] ?? '').toString(),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8C7E75),
                  fontSize: 12,
                ),
              ),
              Text(
                (item['size'] ?? '').toString(),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (item['qty'] ?? '').toString(),
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5722),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFAE00),
                  size: 14,
                ),
                const SizedBox(width: 2),
                Text(
                  (item['rating'] ?? '').toString(),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8C7E75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildStatusBadge('${item['status'] ?? 'Active'}'),
          ],
        ),
      ],
    );
  }

  Widget _buildInactiveHeader(
    Map<String, dynamic> item, {
    required Color primaryText,
    required Color secondaryText,
    required bool isExpired,
    required String status,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isExpired
                ? const Color(0xFFCBC7C2)
                : const Color(0xFFE8F4FC),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(6),
          child: _subscriptionImage(item),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (item['title'] ?? '').toString(),
                      style: GoogleFonts.outfit(
                        color: primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: isExpired
                            ? const Color(0xFFB0A89F)
                            : const Color(0xFFFFAE00),
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        (item['rating'] ?? '').toString(),
                        style: GoogleFonts.outfit(
                          color: isExpired
                              ? secondaryText
                              : const Color(0xFFFF5E00),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                (item['subtitle'] ?? '').toString(),
                style: GoogleFonts.outfit(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
              Text(
                (item['size'] ?? '').toString(),
                style: GoogleFonts.outfit(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    (item['qty'] ?? '').toString(),
                    style: GoogleFonts.outfit(
                      color: isExpired
                          ? const Color(0xFFA59A94)
                          : const Color(0xFFFF5E00),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(status),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _statusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: GoogleFonts.outfit(
              color: _statusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String label,
    required String value,
    bool muted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFCBC7C2) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: muted ? const Color(0xFF8A847E) : const Color(0xFF8C7E75),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: muted ? const Color(0xFF6B6662) : const Color(0xFF1A1A1A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F1E6),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    bool fullWidth = false,
    bool pill = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(pill || fullWidth ? 23 : 16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5722), Color(0xFFFFC107)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    );
  }
}
