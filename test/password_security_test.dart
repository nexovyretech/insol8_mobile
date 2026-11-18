import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/settings/password_security_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';

import 'support/code_entry.dart';
import 'support/fake_repositories.dart';
import 'support/password_checklist.dart';

class _SecurityAuth extends UnconfiguredAuthRepository {
  _SecurityAuth({required this.profile, required this.google});

  final UserProfile profile;
  final bool google;
  final calls = <String>[];

  @override
  Future<UserProfile> loadProfile() async => profile;

  @override
  Future<bool> isGoogleAccount() async => google;

  @override
  Future<void> sendPasswordCreationCode({required bool toEmail}) async =>
      calls.add('send:${toEmail ? 'email' : 'mobile'}');

  @override
  Future<void> createPassword({
    required bool toEmail,
    required String code,
    required String password,
  }) async {
    calls.add('create:$code:$password');
    if (code == '000000') {
      throw const AuthFailure('That code is incorrect.', isCodeError: true);
    }
  }

  @override
  Future<void> verifyCurrentPassword(String password) async {
    calls.add('verify:$password');
    if (password != 'OldPass#1') {
      throw const AuthFailure('Your current password is incorrect.');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => calls.add('change:$currentPassword:$newPassword');
}

Widget _page(AuthRepository auth) => MaterialApp(
  routes: {AppRoutes.login: (_) => const Text('Login screen')},
  home: PasswordSecurityPage(
    authRepository: auth,
    subscriptionRepository: const FakeSubscriptionRepository(
      SubscriptionPlanIds.basic,
    ),
  ),
);

const _password = 'Secret#123';

Future<void> _enter(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextFormField).last, text);
  // OK enables once the typed value is valid; let it rebuild first.
  await tester.pump();
  await tester.tap(find.text('OK').last);
  await tester.pumpAndSettle();
}

bool _okEnabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'OK'))
        .onPressed !=
    null;

UserProfile _google({String? email, String? mobile}) => UserProfile(
  username: 'juan',
  firstName: 'Juan',
  lastName: 'Cruz',
  email: email,
  mobileNumber: mobile,
  googleEmail: 'juan@gmail.com',
);

void main() {
  testWidgets('a Google sign-up without a contact is asked to add one first', (
    tester,
  ) async {
    final auth = _SecurityAuth(google: true, profile: _google());
    await tester.pumpWidget(_page(auth));
    await tester.pumpAndSettle();

    expect(find.text('juan@gmail.com'), findsOneWidget);
    await tester.tap(find.text('Create password'));
    await tester.pumpAndSettle();
    expect(find.text('Add an Email or Mobile First'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets(
    'create password: password, confirm, code, created, still signed in',
    (tester) async {
      final auth = _SecurityAuth(
        google: true,
        profile: _google(email: 'juan@example.com'),
      );
      await tester.pumpWidget(_page(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create password'));
      await tester.pumpAndSettle();
      // The eye shows and hides the password.
      await tester.enterText(find.byType(TextFormField).last, 'weak');
      await tester.pump();
      TextField field() =>
          tester.widget<TextField>(find.byType(TextField).last);
      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(field().obscureText, isFalse);
      // The checklist updates live: lowercase met, the rest not yet.
      await tester.pumpAndSettle();
      expect(
        checklistIcon(tester, 'A lowercase letter'),
        Icons.check_circle_rounded,
      );
      expect(checklistIcon(tester, 'A number'), Icons.cancel_rounded);
      // OK stays greyed out until every requirement is met.
      expect(_okEnabled(tester), isFalse);
      await _enter(tester, _password);
      await _enter(tester, _password);

      // No extra confirmation: the code is sent straight after confirming.
      expect(auth.calls, ['send:email']);
      expect(find.text('Enter Code'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsOneWidget);

      // A wrong code can be retried.
      await enterCode(tester, '000000');
      expect(find.text('Enter Code'), findsOneWidget);
      await enterCode(tester, '123456');
      expect(auth.calls.sublist(1), [
        'create:000000:$_password',
        'create:123456:$_password',
      ]);
      expect(find.text('Password Created!'), findsOneWidget);
      expect(find.text('Login screen'), findsNothing);
    },
  );

  testWidgets('resend becomes available after the countdown', (tester) async {
    final auth = _SecurityAuth(
      google: true,
      profile: _google(mobile: '+639171234567'),
    );
    await tester.pumpWidget(_page(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create password'));
    await tester.pumpAndSettle();
    await _enter(tester, _password);
    await _enter(tester, _password);
    expect(find.textContaining('+63 917 123 4567'), findsOneWidget);
    expect(find.text('Resend code'), findsNothing);

    await tester.pump(const Duration(seconds: 61));
    await tester.tap(find.text('Resend code'));
    await tester.pumpAndSettle();
    expect(auth.calls, ['send:mobile', 'send:mobile']);
    expect(find.textContaining('Resend code in'), findsOneWidget);

    // Cancelling the code keeps the user here, signed in.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Login screen'), findsNothing);
    expect(find.text('Create password'), findsOneWidget);
  });

  testWidgets('update password stops at a wrong current password', (
    tester,
  ) async {
    final auth = _SecurityAuth(
      google: false,
      profile: const UserProfile(
        username: 'jane',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
      ),
    );
    await tester.pumpWidget(_page(auth));
    await tester.pumpAndSettle();

    expect(find.text('Create password'), findsNothing);
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Wrong#123');
    expect(
      inErrorBanner('Your current password is incorrect.'),
      findsOneWidget,
    );
    expect(find.text('Enter Password'), findsOneWidget);
    expect(find.text('New Password'), findsNothing);

    await _enter(tester, 'OldPass#1');
    expect(find.text('New Password'), findsOneWidget);
    await _enter(tester, _password);
    await _enter(tester, _password);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(auth.calls, [
      'verify:Wrong#123',
      'verify:OldPass#1',
      'change:OldPass#1:$_password',
    ]);
    expect(find.text('Password Updated!'), findsOneWidget);
  });
}
