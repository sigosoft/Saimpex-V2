import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';

import '../../utils/app_fonts.dart';
class OtpInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final FocusNode? prevFocusNode;

  /// Called when this box receives more than one digit (fast typing, a pasted
  /// or auto-filled code) so the row can spread them over the next boxes.
  final ValueChanged<String>? onSeveralDigits;

  const OtpInputBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    this.prevFocusNode,
    this.onSeveralDigits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Focus(
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (controller.text.isEmpty && prevFocusNode != null) {
              prevFocusNode!.requestFocus();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          focusNode: focusNode,
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: AppFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          // No one-digit limit here: a second digit typed before the focus
          // moves (or a whole pasted code) goes to onSeveralDigits instead
          // of being dropped.
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: "",
          ),
          onTap: () {
            if (controller.text.isNotEmpty) {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            }
          },
          onChanged: (value) {
            if (value.length > 1 && onSeveralDigits != null) {
              onSeveralDigits!(value);
              return;
            }
            if (value.length > 1) {
              controller.text = value.substring(value.length - 1);
            }
            if (value.isNotEmpty) {
              if (nextFocusNode != null) {
                nextFocusNode!.requestFocus();
              } else {
                focusNode.unfocus();
              }
            } else {
              if (prevFocusNode != null) {
                prevFocusNode!.requestFocus();
              }
            }
          },
        ),
      ),
    );
  }
}
