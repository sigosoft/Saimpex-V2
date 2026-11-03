// The verification code boxes stay left to right in Arabic, so 123456 reads
// 123456 and not 654321.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saimpex_v2/views/widgets/otp_code_row.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('first code box is on the left (${direction.name})', (
      tester,
    ) async {
      final controllers = List.generate(6, (_) => TextEditingController());
      final focusNodes = List.generate(6, (_) => FocusNode());
      addTearDown(() {
        for (final c in controllers) {
          c.dispose();
        }
        for (final f in focusNodes) {
          f.dispose();
        }
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: OtpCodeRow(
                controllers: controllers,
                focusNodes: focusNodes,
              ),
            ),
          ),
        ),
      );

      final xs = [
        for (var i = 0; i < 6; i++)
          tester.getCenter(find.byKey(ValueKey('otp_box_$i'))).dx,
      ];
      for (var i = 1; i < 6; i++) {
        expect(
          xs[i],
          greaterThan(xs[i - 1]),
          reason: 'box $i right of box ${i - 1}',
        );
      }

      // Typing a digit moves focus to the next box (to the right).
      await tester.tap(find.byKey(const ValueKey('otp_box_0')));
      await tester.enterText(find.byType(TextField).first, '1');
      await tester.pump();
      expect(controllers[0].text, '1');
      expect(focusNodes[1].hasFocus, isTrue);
    });
  }
}
