import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows [child] when online; otherwise the offline screen overlay.
class NoInternetGuard extends StatefulWidget {
  final Widget child;

  const NoInternetGuard({super.key, required this.child});

  @override
  State<NoInternetGuard> createState() => _NoInternetGuardState();
}

class _NoInternetGuardState extends State<NoInternetGuard> {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _hasInternet = true;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen(_updateStatus);
    _checkInitial();
  }

  Future<void> _checkInitial() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (!mounted) return;
      _updateStatus(results);
    } catch (_) {
      // Keep current UI if connectivity check fails.
    } finally {
      if (mounted) setState(() => _checked = true);
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (_hasInternet == online) return;
    if (!mounted) return;
    setState(() => _hasInternet = online);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_checked && !_hasInternet)
          const Positioned.fill(child: NoInternetScreen()),
      ],
    );
  }
}

/// Offline screen: centered tower image + "Try:" tips.
/// System fonts only — avoids GoogleFonts network fetch when offline.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  // Match the illustration's white canvas.
  static const _bg = Color(0xFFFFFFFF);
  static const _text = Color(0xFF5F6368);

  static const _tips = [
    'Turning off aeroplane mode',
    'Turning on mobile data or Wi-Fi',
    'Checking the signal in your area',
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _bg,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Image.asset(
                        'lib/assets/images/offline_tower.png',
                        width: 260,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.cell_tower_rounded,
                          size: 120,
                          color: Color(0xFF9AA0A6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'No Internet connection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3C4043),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Left-aligned tips, centered as a group on the screen
                    Center(
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Try:',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: _text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._tips.map(_buildTip),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, left: 2),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: _text,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: _text,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
