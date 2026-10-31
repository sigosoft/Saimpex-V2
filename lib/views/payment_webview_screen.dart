import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/app_back_button.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;

  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  var _loading = true;
  var _closed = false;

  bool? _paymentResult(String url) {
    final value = url.toLowerCase();
    if (value.contains('/payment/success')) return true;
    if (value.contains('/payment/failed') ||
        value.contains('/payment/cancelled')) {
      return false;
    }
    return null;
  }

  void _close(bool paid) {
    if (_closed || !mounted) return;
    _closed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(paid);
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[PAYMENT] ${widget.url}');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final result = _paymentResult(request.url);
            if (result == null) return NavigationDecision.navigate;
            _close(result);
            return NavigationDecision.prevent;
          },
          onPageFinished: (url) {
            final result = _paymentResult(url);
            if (result != null) {
              _close(result);
              return;
            }
            if (mounted && !_closed) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted && !_closed) setState(() => _loading = false);
          },
        ),
      );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _closed) return;
      _controller.loadRequest(Uri.parse(widget.url));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsetsDirectional.only(start: 12),
          child: Center(child: AppBackButton()),
        ),
        title: Text(
          'core_payment_title'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
            ),
        ],
      ),
    );
  }
}
