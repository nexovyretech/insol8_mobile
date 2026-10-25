import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/main.dart';
import 'package:insol8_mobile/models/sign_up_data.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/widgets/auth/auth_password_field.dart';
import 'package:insol8_mobile/widgets/auth/verification_code_input.dart';

Widget _previewApp() => Insol8App(
  authRepository: UnconfiguredAuthRepository(),
  initialRoute: AppRoutes.getStarted,
);

/// Configured repository double: records calls and fails on demand.
class _FakeAuthRepository extends UnconfiguredAuthRepository {
  AuthFailure? signInFailure;
  AuthFailure? resetFailure;
  bool signedIn = false;
  final calls = <String>[];

  @override
  bool get isConfigured => true;

  @override
  Future<bool> hasActiveSession() async => signedIn;

  @override
  Future<UserProfile> loadProfile() async => const UserProfile(
    username: 'jane.doe',
    firstName: 'Jane',
    lastName: 'Doe',
    email: 'jane@example.com',
  );

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    calls.add('signIn:$identifier');
    if (signInFailure != null) throw signInFailure!;
    signedIn = true;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    signedIn = false;
  }

  @override
  Future<void> requestPasswordReset({required String identifier}) async =>
      calls.add('reset:$identifier');

  AuthFailure? verifyFailure;

  @override
  Future<void> verifyPasswordResetCode({
    required String identifier,
    required String code,
  }) async {
    calls.add('verifyCode:$code');
    if (verifyFailure != null) throw verifyFailure!;
  }

  @override
  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    calls.add('confirmReset:$code');
    if (resetFailure != null) throw resetFailure!;
  }

  @override
  Future<void> requestVerificationCode({
    required String contact,
    required SignUpContactMethod method,
    String? firstName,
    String? lastName,
  }) async => calls.add('signUp:$contact:$firstName $lastName');
}

Future<void> _signInWith(WidgetTester tester, String password) async {
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'jane@example.com');
  await tester.enterText(fields.at(1), password);
  await tester.pump();
  final submit = find.widgetWithText(FilledButton, 'Sign in');
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

final _codeFields = find.descendant(
  of: find.byType(VerificationCodeInput),
  matching: find.byType(TextField),
);

Future<void> _enterCode(WidgetTester tester, String code) async {
  for (var index = 0; index < code.length; index++) {
    await tester.enterText(_codeFields.at(index), code[index]);
    await tester.pump();
  }
}

Future<void> _enterNewPassword(WidgetTester tester, String password) async {
  final fields = find.descendant(
    of: find.byType(AuthPasswordField),
    matching: find.byType(TextField),
  );
  await tester.enterText(fields.at(0), password);
  await tester.enterText(fields.at(1), password);
  await tester.pump();
}

bool _isEnabled(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label)).onPressed != null;

/// Buttons sit below the default 800×600 test viewport, so scroll first.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
}

void main() {
  testWidgets('changing signup contact method starts with an empty field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_previewApp());
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
    await tester.pumpWidget(_previewApp());
    await tester.pumpAndSettle();

    expect(find.text('A Smarter Way to Dry'), findsOneWidget);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
    await tester.tap(find.text('Forgot Password'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
    await tester.tap(find.text('Use mobile number'));
    await tester.pumpAndSettle();
    final mobileField = find.byType(TextFormField).first;
    await tester.enterText(mobileField, '9123456789');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Code'));
    await tester.pumpAndSettle();

    // The code screen comes first, with no password fields yet.
    expect(find.text('Verify your mobile'), findsOneWidget);
    expect(_codeFields, findsNWidgets(6));
    expect(find.byType(AuthPasswordField), findsNothing);
    expect(_isEnabled(tester, 'Verify'), isFalse);

    await _enterCode(tester, '012345');
    await _tapVisible(tester, find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('New Password'), findsOneWidget);
    expect(find.byType(AuthPasswordField), findsNWidgets(2));
    expect(_isEnabled(tester, 'Set New Password'), isFalse);
    await _enterNewPassword(tester, 'NewPass12');
    expect(_isEnabled(tester, 'Set New Password'), isTrue);
  });

  testWidgets('shows the sign-in failure and stays on the login screen', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthRepository()
      ..signInFailure = const AuthFailure('Incorrect username, email, or password.');
    await tester.pumpWidget(
      Insol8App(authRepository: auth, initialRoute: AppRoutes.getStarted),
    );
    await tester.pumpAndSettle();
    await _signInWith(tester, 'WrongPass1');

    expect(auth.calls, ['signIn:jane@example.com']);
    expect(find.text('Incorrect username, email, or password.'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
  });

  testWidgets('signs in to the protected home screen and signs out', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthRepository();
    await tester.pumpWidget(
      Insol8App(authRepository: auth, initialRoute: AppRoutes.getStarted),
    );
    await tester.pumpAndSettle();
    await _signInWith(tester, 'GoodPass1');

    expect(find.text('Welcome, Jane!'), findsOneWidget);
    expect(find.text('@jane.doe'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.calls.last, 'signOut');
    expect(find.text('A Smarter Way to Dry'), findsOneWidget);
  });

  testWidgets('a restored session opens home; without one home redirects', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthRepository()..signedIn = true;
    await tester.pumpWidget(
      Insol8App(authRepository: auth, initialRoute: AppRoutes.home),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Jane!'), findsOneWidget);

    auth.signedIn = false;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      Insol8App(authRepository: auth, initialRoute: AppRoutes.home),
    );
    await tester.pumpAndSettle();
    expect(find.text('A Smarter Way to Dry'), findsOneWidget);
  });

  testWidgets('sign-up only shows the code step after the code is sent', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthRepository();
    await tester.pumpWidget(
      Insol8App(authRepository: auth, initialRoute: AppRoutes.signUp),
    );
    await tester.pumpAndSettle();
    final nameFields = find.byType(TextFormField);
    await tester.enterText(nameFields.at(0), 'Jane');
    await tester.enterText(nameFields.at(1), 'Doe');
    await tester.pump();
    await _tapVisible(tester, find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'jane@example.com');
    await tester.pump();
    await _tapVisible(tester, find.text('Continue'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signUp:jane@example.com:Jane Doe']);
    expect(find.text('Verify your email'), findsOneWidget);
  });

  testWidgets('a wrong reset code is rejected before the password screen', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthRepository()
      ..verifyFailure = const AuthFailure(
        'That code is incorrect. Check it and try again.',
        isCodeError: true,
      );
    await tester.pumpWidget(
      Insol8App(authRepository: auth, initialRoute: AppRoutes.forgotPassword),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'jane@example.com');
    await tester.pump();
    await _tapVisible(tester, find.text('Send Code'));
    await tester.pumpAndSettle();
    await _enterCode(tester, '111111');
    await _tapVisible(tester, find.text('Verify'));
    await tester.pumpAndSettle();

    // Rejected on the code screen: no password fields, code cleared.
    expect(auth.calls, ['reset:jane@example.com', 'verifyCode:111111']);
    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.byType(AuthPasswordField), findsNothing);
    expect(find.text('That code is incorrect. Check it and try again.'), findsOneWidget);
    for (final field in tester.widgetList<TextField>(_codeFields)) {
      expect(field.controller!.text, isEmpty);
    }

    // A correct code then opens the password screen and resets with it.
    auth.verifyFailure = null;
    await _enterCode(tester, '222222');
    await _tapVisible(tester, find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text('New Password'), findsOneWidget);
    await _enterNewPassword(tester, 'NewPass12');
    await _tapVisible(tester, find.text('Set New Password'));
    await tester.pumpAndSettle();
    expect(auth.calls.last, 'confirmReset:222222');
  });
}
