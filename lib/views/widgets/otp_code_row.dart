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
          ),
        ),
      ),
    );
  }
}
