import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/widgets/auth/verification_code_input.dart';

/// Types [code] into the six code boxes, one digit per box. The last digit
/// submits the code on its own.
Future<void> enterCode(WidgetTester tester, String code) async {
  final boxes = find.descendant(
    of: find.byType(VerificationCodeInput),
    matching: find.byType(TextField),
  );
  expect(boxes, findsNWidgets(6));
  for (var index = 0; index < 6; index++) {
    await tester.enterText(boxes.at(index), code[index]);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
