import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class OtpInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final FocusNode? prevFocusNode;

  const OtpInputBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    this.prevFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.inputBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: KeyboardListener(
        focusNode: focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (controller.text.isEmpty && prevFocusNode != null) {
              prevFocusNode!.requestFocus();
            }
          }
        },
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: "",
          ),
          onChanged: (value) {
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
