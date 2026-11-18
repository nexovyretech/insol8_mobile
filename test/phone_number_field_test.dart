// Hidden (size 0) inline errors stay in the tree, so only visible text is counted.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/utils/phone_number.dart';
import 'package:insol8_mobile/widgets/auth/phone_number_field.dart';

void main() {
  testWidgets('sign-up style field shows the Smart/TNT notice and blocks it', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PhoneNumberField(
              controller: controller,
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Enter your mobile number.' : null,
              blockSmartNetwork: true,
            ),
          ),
        ),
      ),
    );

    // Shown as soon as a Smart/TNT prefix is typed, before any submit.
    await tester.enterText(find.byType(TextFormField), '918');
    await tester.pump();
    expect(
      find.text(smartNetworkUnsupportedMessage).hitTestable(),
      findsOneWidget,
    );
    expect(formKey.currentState!.validate(), isFalse);

    // A Globe number clears it and passes.
    await tester.enterText(find.byType(TextFormField), '9171234567');
    await tester.pump();
    expect(
      find.text(smartNetworkUnsupportedMessage).hitTestable(),
      findsNothing,
    );
    expect(formKey.currentState!.validate(), isTrue);

    // Other errors appear under the row too, once.
    await tester.enterText(find.byType(TextFormField), '');
    formKey.currentState!.validate();
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Enter your mobile number.').hitTestable(),
      findsOneWidget,
    );
  });
}
