import 'package:flutter/material.dart';

import 'package:insol8_mobile/pages/get_started_page.dart';
import 'package:insol8_mobile/pages/forgot_password_page.dart';
import 'package:insol8_mobile/pages/home_page.dart';
import 'package:insol8_mobile/pages/login_page.dart';
import 'package:insol8_mobile/pages/sign_up_screen.dart';
import 'package:insol8_mobile/services/auth_repository.dart';

abstract final class AppRoutes {
  static const getStarted = '/';
  static const login = '/login';
  static const signUp = '/signup';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';

  static Map<String, WidgetBuilder> build(AuthRepository authRepository) => {
    getStarted: (_) => const GetStartedPage(),
    login: (_) => LoginPage(authRepository: authRepository),
    signUp: (_) => SignUpScreen(authRepository: authRepository),
    forgotPassword: (_) => ForgotPasswordPage(authRepository: authRepository),
    // HomePage checks the session itself and returns to getStarted without one.
    home: (_) => HomePage(authRepository: authRepository),
  };
}
