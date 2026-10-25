// Live checks of CognitoAuthRepository against the deployed dev stack.
// Skipped unless INSOL8_LIVE=1. Credentials come from environment variables
// so they never appear in source or command lines:
//   QA_EMAIL, QA_PASSWORD, QA_APP_USERNAME     account with a Neon profile
//   QA2_EMAIL, QA2_PASSWORD                    account without a profile yet
//   QA_SIGNUP_EMAIL                            unused address for sign-up
@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:amplify_auth_cognito_dart/amplify_auth_cognito_dart.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/amplifyconfiguration.dart';
import 'package:insol8_mobile/models/sign_up_data.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/cognito_auth_repository.dart';

final _env = Platform.environment;
String _need(String key) => _env[key] ?? (throw StateError('$key is not set'));

void main() {
  final live = _env['INSOL8_LIVE'] == '1';
  late CognitoAuthRepository auth;

  setUpAll(() async {
    if (!live) return;
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null; // flutter_test blocks real HTTP by default.
    await Amplify.addPlugin(AmplifyAuthCognitoDart());
    await Amplify.configure(jsonEncode(amplifyConfig.toJson()));
    auth = CognitoAuthRepository();
    await auth.signOut();
  });

  group('live Cognito + API', skip: !live ? 'set INSOL8_LIVE=1' : null, () {
    test('wrong password gives a clear, generic error', () async {
      await expectLater(
        auth.signIn(
          identifier: _need('QA_EMAIL'),
          password: 'Wrong-Password-1',
          rememberMe: true,
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          'Incorrect username, email, or password.',
        )),
      );
      expect(await auth.hasActiveSession(), isFalse);
    });

    test('email sign-in loads the profile; session persists; sign-out clears it', () async {
      await auth.signIn(
        identifier: _need('QA_EMAIL'),
        password: _need('QA_PASSWORD'),
        rememberMe: true,
      );
      expect(await auth.hasActiveSession(), isTrue);
      final profile = await auth.loadProfile();
      expect(profile.username, _need('QA_APP_USERNAME'));
      expect(profile.email, _need('QA_EMAIL'));

      await auth.signOut();
      expect(await auth.hasActiveSession(), isFalse);
      await expectLater(auth.loadProfile(), throwsA(isA<AuthFailure>()));
    });

    test('app-username sign-in resolves through the API', () async {
      await auth.signIn(
        identifier: _need('QA_APP_USERNAME'),
        password: _need('QA_PASSWORD'),
        rememberMe: true,
      );
      expect((await auth.loadProfile()).username, _need('QA_APP_USERNAME'));
      await auth.signOut();
    });

    test('password change API works for a signed-in user (used by sign-up)', () async {
      final original = _need('QA_PASSWORD');
      const temporary = 'Changed-Pass-9';
      await auth.signIn(identifier: _need('QA_EMAIL'), password: original, rememberMe: true);
      await Amplify.Auth.updatePassword(oldPassword: original, newPassword: temporary);
      await auth.signOut();
      await auth.signIn(identifier: _need('QA_EMAIL'), password: temporary, rememberMe: true);
      await Amplify.Auth.updatePassword(oldPassword: temporary, newPassword: original);
      await auth.signOut();
    });

    test('first sign-in without a profile creates one from Cognito attributes', () async {
      await auth.signIn(
        identifier: _need('QA2_EMAIL'),
        password: _need('QA2_PASSWORD'),
        rememberMe: true,
      );
      final profile = await auth.loadProfile();
      expect(profile.firstName, 'Profile');
      expect(profile.lastName, 'Later');
      expect(profile.username, matches(RegExp(r'^profilelater\d{4}$')));
      await auth.signOut();
    });

    test('username availability reflects taken names', () async {
      expect(await auth.isUsernameAvailable(_need('QA_APP_USERNAME')), isFalse);
      expect(await auth.isUsernameAvailable('free.${DateTime.now().millisecondsSinceEpoch}'), isTrue);
    });

    test('sign-up sends a code and rejects a wrong one', () async {
      final email = _need('QA_SIGNUP_EMAIL');
      await auth.requestVerificationCode(
        contact: email,
        method: SignUpContactMethod.email,
        firstName: 'Sign',
        lastName: 'Up',
      );
      await auth.resendVerificationCode(contact: email, method: SignUpContactMethod.email);
      await expectLater(
        auth.verifyContact(contact: email, method: SignUpContactMethod.email, code: '000000'),
        throwsA(isA<AuthFailure>().having((e) => e.isCodeError, 'isCodeError', isTrue)),
      );
    });

    test('mobile sign-up and mobile reset are refused honestly', () async {
      await expectLater(
        auth.requestVerificationCode(contact: '+639171234567', method: SignUpContactMethod.mobile),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(
        auth.requestPasswordReset(identifier: '+639171234567'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('password reset: request succeeds; a wrong code is reported as a code error', () async {
      await auth.requestPasswordReset(identifier: _need('QA_EMAIL'));
      await expectLater(
        auth.resetPassword(identifier: _need('QA_EMAIL'), code: '000000', newPassword: 'Another-Pass-7'),
        throwsA(isA<AuthFailure>().having((e) => e.isCodeError, 'isCodeError', isTrue)),
      );
    });

    test('the reset code screen rejects a wrong code without changing anything', () async {
      await auth.requestPasswordReset(identifier: _need('QA_EMAIL'));
      await expectLater(
        auth.verifyPasswordResetCode(identifier: _need('QA_EMAIL'), code: '000000'),
        throwsA(isA<AuthFailure>().having((e) => e.isCodeError, 'isCodeError', isTrue)),
      );
    });

    test('reset request for an unknown email looks the same as a known one', () async {
      await auth.requestPasswordReset(identifier: 'nobody.${DateTime.now().millisecondsSinceEpoch}@example.com');
    });
  });
}
