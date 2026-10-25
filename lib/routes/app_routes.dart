import 'package:flutter/material.dart';

import 'package:insol8_mobile/pages/auth/forgot_password/forgot_password_page.dart';
import 'package:insol8_mobile/pages/auth/get_started_page.dart';
import 'package:insol8_mobile/pages/auth/login_page.dart';
import 'package:insol8_mobile/pages/auth/signup/sign_up_screen.dart';
import 'package:insol8_mobile/pages/home/home_page.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_page.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';

abstract final class AppRoutes {
  static const getStarted = '/';
  static const login = '/login';
  static const signUp = '/signup';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';
  static const home = '/home';

  static Map<String, WidgetBuilder> build(
    AuthRepository authRepository,
    OnboardingRepository onboardingRepository,
  ) => {
    getStarted: (_) => const GetStartedPage(),
    login: (_) => LoginPage(authRepository: authRepository),
    signUp: (_) => SignUpScreen(authRepository: authRepository),
    forgotPassword: (_) => ForgotPasswordPage(authRepository: authRepository),
    onboarding: (_) => OnboardingPage(repository: onboardingRepository),
    // HomePage checks the session itself and returns to getStarted without one.
    home: (_) => HomePage(authRepository: authRepository),
  };
}
