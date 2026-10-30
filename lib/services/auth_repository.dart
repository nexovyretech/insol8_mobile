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

  /// Saves username and name changes; returns the stored profile.
  Future<UserProfile> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
  });

  /// Starts an email change: Cognito emails a code to [email] and keeps the
  /// current address active until [confirmEmailChange] succeeds.
  Future<void> requestEmailChange(String email);

  /// Confirms the code sent to [email] and saves it to the profile.
  Future<UserProfile> confirmEmailChange({
    required String email,
    required String code,
  });

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

  /// Returns where the user should go: onboarding for an account that has
  /// no profile yet (first sign-in), home for an existing account.
  Future<AuthLanding> signIn({
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

  /// Signs in or signs up with Google; same landing rule as [signIn].
  Future<AuthLanding> signInWithGoogle();
}

/// Where to send a user after they sign in.
enum AuthLanding {
  /// New account (its profile was just created): run onboarding first.
  onboarding,

  /// Existing account: go straight to the dashboard.
  home,
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
  const UnconfiguredAuthRepository();

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
  Future<UserProfile> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
  }) => Future<UserProfile>.error(const AuthNotConfiguredException());

  @override
  Future<void> requestEmailChange(String email) =>
      Future<void>.error(const AuthNotConfiguredException());

  @override
  Future<UserProfile> confirmEmailChange({
    required String email,
    required String code,
  }) => Future<UserProfile>.error(const AuthNotConfiguredException());

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
  Future<AuthLanding> signIn({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) => Future<AuthLanding>.error(const AuthNotConfiguredException());

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
  Future<AuthLanding> signInWithGoogle() =>
      Future<AuthLanding>.error(const AuthNotConfiguredException());
}

class AuthNotConfiguredException implements Exception {
  const AuthNotConfiguredException();
}
