import 'package:insol8_mobile/models/sign_up_data.dart';
import 'package:insol8_mobile/models/user_profile.dart';

/// Contract for the authentication backend. [CognitoAuthRepository] is the
/// real implementation; [UnconfiguredAuthRepository] keeps the UI runnable
/// when Amplify cannot be configured.
abstract interface class AuthRepository {
  /// False for the local preview adapter; true when backed by a real auth API.
  bool get isConfigured;

  /// True when a valid (or refreshable) session was restored from the device.
  Future<bool> hasActiveSession();

  /// Loads the signed-in user's profile, creating it from the Cognito account
  /// when it does not exist yet (for example after an interrupted sign-up).
  Future<UserProfile> loadProfile();

  Future<bool> isUsernameAvailable(String username);

  Future<void> requestVerificationCode({
    required String contact,
    required SignUpContactMethod method,
    String? firstName,
    String? lastName,
  });

  Future<void> beginSignUp(SignUpData data);

  Future<void> verifyContact({
    required String contact,
    required SignUpContactMethod method,
    required String code,
  });

  Future<void> resendVerificationCode({
    required String contact,
    required SignUpContactMethod method,
  });

  Future<void> signIn({
    required String identifier,
    required String password,
    required bool rememberMe,
  });

  Future<void> signOut();

  Future<void> requestPasswordReset({required String identifier});

  Future<void> verifyPasswordResetCode({
    required String identifier,
    required String code,
  });

  Future<void> resendPasswordResetCode({required String identifier});

  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  });

  Future<void> signInWithGoogle();
}

/// A failure whose [message] is safe and useful to show to the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.isCodeError = false});

  final String message;

  /// True when a verification or reset code was wrong or expired.
  final bool isCodeError;

  @override
  String toString() => 'AuthFailure($message)';
}

/// Keeps the UI runnable before the team backend is available, without
/// pretending a registration or verification succeeded.
class UnconfiguredAuthRepository implements AuthRepository {
  @override
  bool get isConfigured => false;

  @override
  Future<bool> hasActiveSession() async => false;

  @override
  Future<UserProfile> loadProfile() =>
      Future<UserProfile>.error(const AuthNotConfiguredException());

  @override
  Future<bool> isUsernameAvailable(String username) =>
      Future<bool>.error(const AuthNotConfiguredException());

  @override
  Future<void> requestVerificationCode({
    required String contact,
    required SignUpContactMethod method,
    String? firstName,
    String? lastName,
  }) => Future<void>.error(const AuthNotConfiguredException());

  @override
  Future<void> beginSignUp(SignUpData data) =>
      Future<void>.error(const AuthNotConfiguredException());

  @override
  Future<void> verifyContact({
    required String contact,
    required SignUpContactMethod method,
    required String code,
  }) => Future<void>.error(const AuthNotConfiguredException());

  @override
  Future<void> resendVerificationCode({
    required String contact,
    required SignUpContactMethod method,
  }) => Future<void>.error(const AuthNotConfiguredException());

  @override
  Future<void> signIn({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) => Future<void>.error(const AuthNotConfiguredException());

  @override
  Future<void> signOut() async {}

  @override
  Future<void> requestPasswordReset({required String identifier}) =>
      Future<void>.error(const AuthNotConfiguredException());

  @override
  Future<void> verifyPasswordResetCode({
    required String identifier,
    required String code,
  }) => Future<void>.error(const AuthNotConfiguredException());

  @override
  Future<void> resendPasswordResetCode({required String identifier}) =>
      Future<void>.error(const AuthNotConfiguredException());

  @override
  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) => Future<void>.error(const AuthNotConfiguredException());

  @override
  Future<void> signInWithGoogle() =>
      Future<void>.error(const AuthNotConfiguredException());
}

class AuthNotConfiguredException implements Exception {
  const AuthNotConfiguredException();
}
