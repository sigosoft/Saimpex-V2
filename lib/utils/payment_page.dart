import 'package:get/get.dart';

import '../core/network/api_constants.dart';
import '../views/payment_webview_screen.dart';

/// The Masrvi payment page URL from an API value, or null when it isn't a
/// web address. Pages the server builds with a local or live host are moved
/// to the host the app talks to, which serves the same payment pages.
String? paymentPageUrl(dynamic value) {
  final raw = '${value ?? ''}'.trim();
  if (raw.isEmpty || raw == 'null') return null;
  final uri = Uri.tryParse(raw);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  final wrongHost =
      uri.host == 'localhost' ||
      uri.host == '127.0.0.1' ||
      uri.host == 'api.saimpexenterprise.com';
  if (wrongHost && uri.path.contains('/pay/')) {
    return Uri(
      scheme: 'https',
      host: Uri.parse(ApiConstants.baseUrl).host,
      path: uri.path,
      query: uri.hasQuery ? uri.query : null,
    ).toString();
  }
  return uri.toString();
}

/// Opens the Masrvi payment page. True when it reports success, false on
/// failure, null when the customer closed it.
Future<bool?> openPaymentPage(String url) async =>
    await Get.to<bool>(() => PaymentWebViewScreen(url: url));
