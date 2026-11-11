import 'dart:math';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart'
    hide ApiException, UserProfile;

import 'package:insol8_mobile/models/sign_up_data.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/auth_repository.dart';

/// Authentication backed by the InSOL8 Cognito user pool (via Amplify) and the
/// InSOL8 API for app profiles stored in Neon.
///
/// Sign-up UI order is name → email or mobile → code → password → username,
/// but Cognito needs a password before it sends the confirmation code. To keep
/// that order without storing anything sensitive, sign-up registers the
/// account with a random one-time password held only in memory, confirms the
/// code (emailed, or texted by the backend's Custom SMS sender for mobile
/// numbers), signs in with that one-time password, and then replaces it with
/// the user's chosen password through Cognito's change-password API. If the
/// app closes between those steps, the verified account can still be
/// recovered with "Forgot password".
///
/// Mobile numbers must be Philippine mobiles (+639XXXXXXXXX); the backend's
/// Pre sign-up trigger and profile API reject anything else.
class CognitoAuthRepository implements AuthRepository {
  CognitoAuthRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  _PendingSignUp? _pending;

  static final _random = Random.secure();
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  bool get isConfigured => true;

  @override
  Future<bool> hasActiveSession() async {
    try {
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      if (!session.isSignedIn) return false;
      // Throws when the refresh token has expired or was revoked.
      session.userPoolTokensResult.value;
      return true;
    } on SessionExpiredException {
      await Amplify.Auth.signOut();
      return false;
    } on SignedOutException {
      return false;
    } on NetworkException {
      // Offline at launch with a stored session: keep the user signed in;
      // the home screen shows a retry until the connection is back.
      return true;
    } on AuthException {
      return false;
    }
  }

  @override
  Future<UserProfile> loadProfile() async => (await _loadOrCreateProfile()).$1;

  /// Returns the profile and whether it was created just now, which marks a
  /// brand-new account (email sign-up finished elsewhere, or first Google
  /// sign-in) that still needs onboarding.
  Future<(UserProfile, bool)> _loadOrCreateProfile() async {
    try {
      return (UserProfile.fromJson(await _api.get('/me')), false);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return (await _createProfileFromAccount(), true);
      }
      throw _apiFailure(error);
    } on SessionExpiredException {
      throw const AuthFailure(
        'Your session has expired. Please sign in again.',
      );
    } on SignedOutException {
      throw const AuthFailure('Please sign in again.');
    } on AuthException catch (error) {
      safePrint('Profile load failed: ${error.runtimeType}: ${error.message}');
      throw const AuthFailure(
        'You’re signed in, but we couldn’t load your profile. Please try again.',
      );
    }
  }

  /// Creates the Neon profile from the signed-in account; the API generates a
  /// username. Used when sign-up was interrupted or for Google accounts.
  ///
  /// Reads the ID token claims rather than calling fetchUserAttributes(),
  /// because tokens from Google (hosted UI) sign-in only carry the
  /// openid/email/profile scopes, and Cognito's GetUser API rejects them.
  Future<UserProfile> _createProfileFromAccount() async {
    final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    final idToken = session.userPoolTokensResult.value.idToken;
    final email = idToken.email;
    // The API only accepts a mobile number Cognito has verified.
    final mobileNumber = idToken.phoneNumberVerified == true
        ? idToken.phoneNumber
        : null;
    final fullName = (idToken.name ?? '').trim().split(RegExp(r'\s+'));
    var firstName =
        idToken.givenName ??
        (fullName.first.isNotEmpty ? fullName.first : null);
    var lastName =
        idToken.familyName ??
        (fullName.length > 1 ? fullName.skip(1).join(' ') : null);
    firstName ??= email?.split('@').first ?? 'inSOL8';
    lastName ??= 'User';
    // The API caps names at 120 characters; a long Google name must not
    // block sign-in.
    String clamp(String value) =>
        value.length > 120 ? value.substring(0, 120) : value;
    try {
      return UserProfile.fromJson(
        await _api.post('/me', {
          'firstName': clamp(firstName),
          'lastName': clamp(lastName),
          'email': ?email,
          'mobileNumber': ?mobileNumber,
        }),
      );
    } on ApiException catch (error) {
      throw _apiFailure(error);
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final data = await _api.get(
        '/auth/username-availability?username=${Uri.encodeQueryComponent(username)}',
        authenticated: false,
      );
      return data['available'] == true;
    } on ApiException catch (error) {
      throw _apiFailure(error);
    }
  }

  @override
  Future<UserProfile> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    try {
      return UserProfile.fromJson(
        await _api.patch('/me', {
          'username': ?username,
          'firstName': ?firstName,
          'lastName': ?lastName,
        }),
      );
    } on ApiException catch (error) {
      throw _apiFailure(error);
    }
  }

  @override
  Future<void> requestEmailChange(String email) async {
    // Google accounts get their email from Google on every sign-in, and their
    // tokens lack the scope Cognito needs to update attributes.
    final session = await _guard(Amplify.Auth.fetchAuthSession)
        as CognitoAuthSession;
    final idToken = session.userPoolTokensResult.value.idToken;
    if (idToken.claims.customClaims['identities'] != null) {
      throw const AuthFailure(
        'This email is managed by your Google account and can’t be changed here.',
      );
    }
    await _guard(
      () => Amplify.Auth.updateUserAttribute(
        userAttributeKey: AuthUserAttributeKey.email,
        value: email.trim().toLowerCase(),
      ),
    );
  }

  @override
  Future<UserProfile> confirmEmailChange({
    required String email,
    required String code,
  }) async {
    await _guard(
      () => Amplify.Auth.confirmUserAttribute(
        userAttributeKey: AuthUserAttributeKey.email,
        confirmationCode: code.trim(),
      ),
    );
    try {
      return UserProfile.fromJson(
        await _api.patch('/me', {'email': email.trim().toLowerCase()}),
      );
    } on ApiException catch (error) {
      throw _apiFailure(error);
    }
  }

  @override
  Future<void> requestVerificationCode({
    required String contact,
    required SignUpContactMethod method,
    String? firstName,
    String? lastName,
  }) async {
    final normalized = _normalizeContact(contact, method);
    final pending = _pending;
    if (pending != null &&
        pending.contact == normalized &&
        pending.method == method &&
        !pending.confirmed) {
      // Same contact as an unfinished attempt: resend instead of creating
      // another unconfirmed account.
      await _guard(
        () => Amplify.Auth.resendSignUpCode(username: pending.username),
      );
      return;
    }
    await _signOutIfSignedIn();
    final next = _PendingSignUp(
      username: _randomId(),
      oneTimePassword: _randomPassword(),
      contact: normalized,
      method: method,
    );
    await _guard(
      () => Amplify.Auth.signUp(
        username: next.username,
        password: next.oneTimePassword,
        options: SignUpOptions(
          userAttributes: {
            if (method == SignUpContactMethod.email)
              AuthUserAttributeKey.email: normalized
            else
              AuthUserAttributeKey.phoneNumber: normalized,
            AuthUserAttributeKey.givenName: ?firstName,
            AuthUserAttributeKey.familyName: ?lastName,
          },
        ),
      ),
    );
    _pending = next;
  }

  /// One spelling per contact, so "Juan@Mail.com" can't become a second
  /// account next to "juan@mail.com", and "0917…" matches "+63917…" (the
  /// backend trigger checks both).
  static String _normalizeContact(String contact, SignUpContactMethod method) {
    if (method == SignUpContactMethod.email) {
      return contact.trim().toLowerCase();
    }
    return _normalizePhilippineMobile(contact) ??
        (throw const AuthFailure(
          'Enter a Philippine mobile number that starts with 9, like 917 123 4567.',
        ));
  }

  @override
  Future<void> resendVerificationCode({
    required String contact,
    required SignUpContactMethod method,
  }) async {
    final pending = _requirePending();
    await _guard(
      () => Amplify.Auth.resendSignUpCode(username: pending.username),
    );
  }

  @override
  Future<void> verifyContact({
    required String contact,
    required SignUpContactMethod method,
    required String code,
  }) async {
    final pending = _requirePending();
    if (!pending.confirmed) {
      await _guard(
        () => Amplify.Auth.confirmSignUp(
          username: pending.username,
          confirmationCode: code,
        ),
      );
      pending.confirmed = true;
    }
    final result = await _guard(
      () => Amplify.Auth.signIn(
        username: pending.username,
        password: pending.oneTimePassword,
      ),
    );
    if (!result.isSignedIn) {
      throw AuthFailure(
        pending.method == SignUpContactMethod.email
            ? 'Your email is verified. Please sign in to continue.'
            : 'Your mobile number is verified. Please sign in to continue.',
      );
    }
  }

  @override
  Future<void> beginSignUp(SignUpData data) async {
    final pending = _requirePending();
    if (!pending.confirmed) {
      throw AuthFailure(
        pending.method == SignUpContactMethod.email
            ? 'Verify your email before creating your account.'
            : 'Verify your mobile number before creating your account.',
      );
    }
    // Usernames are unique regardless of case; the API stores them lowercase.
    final username = data.username.trim().toLowerCase();
    if (!await isUsernameAvailable(username)) {
      throw const AuthFailure(
        'That username is already taken. Try another one.',
      );
    }
    if (!pending.passwordSet) {
      await _guard(
        () => Amplify.Auth.updatePassword(
          oldPassword: pending.oneTimePassword,
          newPassword: data.password,
        ),
      );
      pending.passwordSet = true;
    }
    try {
      await _api.post('/me', {
        'firstName': data.firstName,
        'lastName': data.lastName,
        if (pending.method == SignUpContactMethod.email)
          'email': pending.contact
        else
          'mobileNumber': pending.contact,
        'username': username,
      });
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        throw const AuthFailure(
          'That username is already taken. Try another one.',
        );
      }
      throw _apiFailure(error);
    }
    _pending = null;
  }

  @override
  Future<AuthLanding> signIn({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    final signInName = await _signInNameFor(identifier);
    await _signOutIfSignedIn();
    final result = await _guard(
      () => Amplify.Auth.signIn(username: signInName, password: password),
    );
    switch (result.nextStep.signInStep) {
      case AuthSignInStep.done:
        return _landingAfterSignIn();
      case AuthSignInStep.confirmSignUp:
        throw const AuthFailure(
          'This account hasn’t been verified. Please sign up again with the same email or mobile number to get a new code.',
        );
      case AuthSignInStep.resetPassword:
        throw const AuthFailure(
          'You need to reset your password. Use “Forgot password” to continue.',
        );
      default:
        throw const AuthFailure('This sign-in method isn’t supported yet.');
    }
  }

  /// A profile created during this sign-in means the account is new (first
  /// Google sign-in, or an email sign-up that was interrupted), so it still
  /// needs onboarding; an existing profile goes straight to the dashboard.
  Future<AuthLanding> _landingAfterSignIn() async {
    final (_, created) = await _loadOrCreateProfile();
    return created ? AuthLanding.onboarding : AuthLanding.home;
  }

  /// Emails and phone numbers are Cognito aliases; app usernames live in Neon
  /// and are resolved to the Cognito username by the API.
  Future<String> _signInNameFor(String identifier) async {
    final value = identifier.trim();
    if (_emailPattern.hasMatch(value)) return value.toLowerCase();
    final phone = _normalizePhilippineMobile(value);
    if (phone != null) return phone;
    try {
      final data = await _api.post('/auth/resolve-sign-in', {
        'identifier': value,
      }, authenticated: false);
      return data['signInName'] as String? ?? value;
    } on ApiException catch (error) {
      throw _apiFailure(error);
    }
  }

  @override
  Future<void> signOut() async {
    _pending = null;
    await Amplify.Auth.signOut();
  }

  /// Reset identifiers are emails (stored lowercase) or Philippine mobile
  /// numbers (+639XXXXXXXXX). Both are Cognito sign-in aliases, which work
  /// once verified, so Cognito finds the account from either.
  static String _resetIdentifier(String identifier) {
    final value = identifier.trim();
    if (_emailPattern.hasMatch(value)) return value.toLowerCase();
    return _normalizePhilippineMobile(value) ??
        (throw const AuthFailure(
          'Enter the email or Philippine mobile number on your account.',
        ));
  }

  /// Cognito sends the code to the account's verified email if it has one,
  /// otherwise by SMS to its verified mobile number (the pool's account
  /// recovery order), whichever identifier was entered.
  @override
  Future<void> requestPasswordReset({required String identifier}) async {
    final username = _resetIdentifier(identifier);
    // With user-existence errors prevented, Cognito responds the same way for
    // unknown emails and numbers, so the UI never reveals whether an account
    // exists.
    await _guard(() => Amplify.Auth.resetPassword(username: username));
  }

  @override
  Future<void> resendPasswordResetCode({required String identifier}) =>
      requestPasswordReset(identifier: identifier);

  /// Checks a reset code before the user picks a new password.
  ///
  /// Cognito has no "verify code only" API, so this submits the code with a
  /// throwaway password that can never meet the pool's password policy
  /// (lowercase only; template.yaml requires uppercase and a number).
  /// Cognito checks the code first: a wrong or expired code is rejected
  /// with CodeMismatch/ExpiredCode, while a valid code fails only on the
  /// password policy, which changes nothing and leaves the code usable for
  /// [resetPassword].
  @override
  Future<void> verifyPasswordResetCode({
    required String identifier,
    required String code,
  }) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const AuthFailure('Enter the 6-digit code we sent you.');
    }
    final username = _resetIdentifier(identifier);
    try {
      await Amplify.Auth.confirmResetPassword(
        username: username,
        newPassword: _unacceptablePassword(),
        confirmationCode: code,
      );
    } on InvalidPasswordException {
      return; // Code accepted; only the placeholder password was refused.
    } on AuthException catch (error) {
      safePrint('Auth error: ${error.runtimeType}: ${error.message}');
      throw AuthFailure(
        _messageFor(error),
        isCodeError:
            error is CodeMismatchException || error is ExpiredCodeException,
      );
    }
    // Reaching here means the pool accepted the placeholder, i.e. the
    // password policy was relaxed below this probe. Fail loudly.
    throw const AuthFailure(
      'Your password was reset unexpectedly. Please request a new code.',
    );
  }

  /// Random, lowercase-only, 12 characters: valid for the API's length rule,
  /// invalid for the pool policy, and never reused.
  static String _unacceptablePassword() => List.generate(
    12,
    (_) => 'abcdefghijklmnopqrstuvwxyz'[_random.nextInt(26)],
  ).join();

  @override
  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    final username = _resetIdentifier(identifier);
    await _guard(
      () => Amplify.Auth.confirmResetPassword(
        username: username,
        newPassword: newPassword,
        confirmationCode: code,
      ),
    );
  }

  @override
  Future<AuthLanding> signInWithGoogle() async {
    await _signOutIfSignedIn();
    final SignInResult result;
    try {
      result = await _guard(
        () => Amplify.Auth.signInWithWebUI(provider: AuthProvider.google),
      );
    } on AuthFailure {
      rethrow;
    } on Exception catch (error) {
      // Platform errors (no browser, redirect not registered) are not
      // AuthExceptions; log the cause so it shows up in device logs.
      safePrint('Google sign-in failed: ${error.runtimeType}: $error');
      throw const AuthFailure(
        'Couldn’t open Google sign in. Make sure a browser such as Chrome is installed and try again.',
      );
    }
    if (!result.isSignedIn) {
      throw const AuthFailure('Google sign in was not completed.');
    }
    // First Google sign-in creates the account and profile: onboarding.
    return _landingAfterSignIn();
  }

  _PendingSignUp _requirePending() =>
      _pending ??
      (throw const AuthFailure(
        'Your sign-up session has expired. Please enter your email or mobile number again.',
      ));

  Future<void> _signOutIfSignedIn() async {
    final session = await Amplify.Auth.fetchAuthSession();
    if (session.isSignedIn) await Amplify.Auth.signOut();
  }

  /// Runs an Amplify call and converts its errors to user-facing messages.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (error) {
      // Type and Cognito's message only; never credentials or codes.
      safePrint('Auth error: ${error.runtimeType}: ${error.message}');
      throw AuthFailure(
        _messageFor(error),
        isCodeError:
            error is CodeMismatchException || error is ExpiredCodeException,
      );
    }
  }

  static String _messageFor(AuthException error) => switch (error) {
    NotAuthorizedServiceException() =>
      'Incorrect username, email, or password.',
    UserNotFoundException() => 'Incorrect username, email, or password.',
    UserNotConfirmedException() => 'This account hasn’t been verified yet. Please sign up again with the same email or mobile number.',
    PasswordResetRequiredException() =>
      'You need to reset your password. Use “Forgot password” to continue.',
    CodeMismatchException() =>
      'That code is incorrect. Check it and try again.',
    ExpiredCodeException() => 'That code has expired. Request a new one.',
    AliasExistsException() => 'An account with this email or mobile number already exists. Sign in or reset your password.',
    UsernameExistsException() =>
      'An account with these details already exists. Sign in instead.',
    InvalidPasswordException() => 'Use at least 8 characters with an uppercase letter, a lowercase letter, and a number.',
    CodeDeliveryFailureException() =>
      'We couldn’t deliver the code. Check your email or mobile number and try again.',
    LimitExceededException() ||
    TooManyRequestsException() ||
    TooManyFailedAttemptsException() =>
      'Too many attempts. Please wait a few minutes and try again.',
    NetworkException() => 'Check your internet connection and try again.',
    UserCancelledException() => 'Sign in was cancelled.',
    // Raised by the backend Pre sign-up trigger (signup-guard-service.js) for
    // both email sign-up and Google sign-in.
    LambdaException(:final message)
        when message.contains('EMAIL_IN_USE_GOOGLE') =>
      'This email is registered with Google. Use “Continue with Google” to sign in.',
    LambdaException(:final message) when message.contains('EMAIL_IN_USE') => 'An account with this email already exists. Sign in with your email and password, or reset your password.',
    LambdaException(:final message) when message.contains('PHONE_IN_USE') =>
      'An account with this mobile number already exists. Sign in with your mobile number and password, or reset your password.',
    LambdaException(:final message)
        when message.contains('PHONE_NOT_SUPPORTED') =>
      'Only Philippine mobile numbers (+63 9XX XXX XXXX) are supported.',
    LambdaException(:final message)
        when message.contains('EMAIL_OR_PHONE_REQUIRED') =>
      'Enter an email address or a mobile number.',
    _ => 'Something went wrong. Please try again.',
  };

  static AuthFailure _apiFailure(ApiException error) =>
      AuthFailure(switch (error.statusCode) {
        0 => error.message,
        401 => 'Your session has expired. Please sign in again.',
        400 => 'Some of your details aren’t valid. Check them and try again.',
        409 when error.code == 'EMAIL_NOT_VERIFIED' =>
          'Your new email isn’t verified yet. Please request a new code.',
        409 when error.code == 'MOBILE_NUMBER_NOT_VERIFIED' =>
          'Your mobile number isn’t verified yet. Please request a new code.',
        409 => 'That username is already taken. Try another one.',
        _ => 'We couldn’t reach inSOL8 right now. Please try again.',
      });

  static String? _normalizePhilippineMobile(String value) {
    final digits = value.replaceAll(RegExp(r'[\s()-]'), '');
    final match = RegExp(r'^(?:\+63|63|0)?(9\d{9})$').firstMatch(digits);
    return match == null ? null : '+63${match.group(1)}';
  }

  static String _randomId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Satisfies the pool policy (upper, lower, digit, ≥ 8); never persisted.
  static String _randomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final body = List.generate(
      28,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return 'Aa1$body';
  }
}

class _PendingSignUp {
  _PendingSignUp({
    required this.username,
    required this.oneTimePassword,
    required this.contact,
    required this.method,
  });

  final String username;
  final String oneTimePassword;

  /// Lowercase email or +639XXXXXXXXX mobile number, per [method].
  final String contact;
  final SignUpContactMethod method;
  bool confirmed = false;
  bool passwordSet = false;
}
