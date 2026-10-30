import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../../models/order_repository.dart';
import '../../../utils/api_language.dart';

/// Loads one order's detail from the API and passes it to [builder].
/// `detail` is null until the response arrives, and stays null if it fails.
class PharmacyOrderDetailLoader extends StatefulWidget {
  const PharmacyOrderDetailLoader({
    super.key,
    required this.apiOrderId,
    required this.builder,
  });

  final int? apiOrderId;
  final Widget Function(BuildContext context, Map<String, dynamic>? detail)
  builder;

  @override
  State<PharmacyOrderDetailLoader> createState() =>
      _PharmacyOrderDetailLoaderState();
}

class _PharmacyOrderDetailLoaderState extends State<PharmacyOrderDetailLoader> {
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.apiOrderId;
    if (id == null || id < 1 || !Get.isRegistered<OrderRepository>()) return;
    try {
      // orderDetails already returns the response's data object.
      final result = await Get.find<OrderRepository>().orderDetails(
        orderId: id,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() => _detail = result);
    } on ApiException {
      // Keep the placeholders; the screen still opens
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _detail);
}

/// "400.00" or 400 becomes "400 MRU". Missing values show "— MRU".
/// With [negative], a positive amount is shown as a deduction ("-50 MRU").
String orderMoneyText(dynamic value, {bool negative = false}) {
  final number = double.tryParse('${value ?? ''}');
  if (number == null) return '— MRU';
  final text = '${number.round()} MRU';
  return negative && number > 0 ? '-$text' : text;
}
