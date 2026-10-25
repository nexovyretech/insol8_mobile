import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/main.dart';

void main() {
  testWidgets('changing signup contact method starts with an empty field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Insol8App());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    final nameFields = find.byType(TextFormField);
    await tester.enterText(nameFields.at(0), 'Jane');
    await tester.enterText(nameFields.at(1), 'Doe');
    await tester.pump();
    final continueButton = find.text('Continue');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'jane@example.com');
    await tester.pump();
    await tester.tap(find.text('sign up with mobile number'));
    await tester.pumpAndSettle();

    var mobileField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(find.text('Enter your mobile number'), findsOneWidget);
    expect(mobileField.controller!.text, isEmpty);

    await tester.enterText(find.byType(TextFormField).first, '9123456789');
    await tester.pump();
    await tester.tap(find.text('sign up with email'));
    await tester.pumpAndSettle();

    final switchedBackField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(switchedBackField.controller!.text, isEmpty);
  });

  testWidgets('opens forgot-password verification from login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Insol8App());
    await tester.pumpAndSettle();

    expect(find.text('A Smarter Way to Dry'), findsOneWidget);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
    await tester.tap(find.text('Forgot Password'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
    final mobileField = find.byType(TextFormField).first;
    await tester.enterText(mobileField, '9123456789');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Code'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your mobile'), findsOneWidget);
    final codeFields = find.byType(TextField);
    expect(codeFields, findsNWidgets(6));
    for (var index = 0; index < 6; index++) {
      await tester.enterText(codeFields.at(index), '$index');
      await tester.pump();
    }
    final verifyButton = find.text('Verify');
    await tester.ensureVisible(verifyButton);
    await tester.tap(verifyButton);
    await tester.pumpAndSettle();

    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Set New Password'), findsOneWidget);
  });
}
