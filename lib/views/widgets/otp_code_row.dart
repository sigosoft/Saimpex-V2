import 'package:flutter/material.dart';

import 'otp_input_box.dart';

/// The verification code boxes. Always laid out left to right, also in
/// Arabic: digits are read left to right, so the first digit goes in the
/// left box and typing moves right. In a right-to-left Row the code 123456
/// showed as 654321.
class OtpCodeRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  const OtpCodeRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
  }) : assert(controllers.length == focusNodes.length);

  @override
  Widget build(BuildContext context) {
    final count = controllers.length;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          count,
          (index) => OtpInputBox(
            key: ValueKey('otp_box_$index'),
            controller: controllers[index],
            focusNode: focusNodes[index],
            nextFocusNode: index < count - 1 ? focusNodes[index + 1] : null,
            prevFocusNode: index > 0 ? focusNodes[index - 1] : null,
            onSeveralDigits: (digits) => _spread(index, digits),
          ),
        ),
      ),
    );
  }

  /// Puts several digits received in box [from] into that box and the ones
  /// after it, then moves to the next empty box (or closes the keyboard when
  /// the code is complete). A whole 6-digit code fills every box from the first.
  void _spread(int from, String digits) {
    final count = controllers.length;
    final start = digits.length >= count ? 0 : from;
    var index = start;
    for (final digit in digits.split('')) {
      if (index >= count) break;
      controllers[index].text = digit;
      index++;
    }
    if (index < count) {
      focusNodes[index].requestFocus();
    } else {
      focusNodes[count - 1].unfocus();
    }
  }
}
