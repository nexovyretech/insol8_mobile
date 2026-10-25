import 'package:insol8_mobile/models/sign_up_data.dart';

/// Contract for the authentication backend. Implement this with the API or
/// identity provider selected by the team once its endpoint and payload are set.
abstract interface class AuthRepository {
  /// False for the local preview adapter; true when backed by a real auth API.
  bool get isConfigured;

  Future<void> requestVerificationCode({
    required String contact,
    required SignUpContactMethod method,
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

/// Keeps the UI runnable before the team backend is available, without
/// pretending a registration or verification succeeded.
class UnconfiguredAuthRepository implements AuthRepository {
  @override
  bool get isConfigured => false;

  @override
  Future<void> requestVerificationCode({
    required String contact,
    required SignUpContactMethod method,
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
