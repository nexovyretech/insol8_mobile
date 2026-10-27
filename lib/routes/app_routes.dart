import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/pages/auth/forgot_password/forgot_password_page.dart';
import 'package:insol8_mobile/pages/auth/get_started_page.dart';
import 'package:insol8_mobile/pages/auth/login_page.dart';
import 'package:insol8_mobile/pages/auth/signup/sign_up_screen.dart';
import 'package:insol8_mobile/pages/devices/devices_page.dart';
import 'package:insol8_mobile/pages/devices/device_detail_page.dart';
import 'package:insol8_mobile/pages/devices/device_search_page.dart';
import 'package:insol8_mobile/pages/home/home_page.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_page.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/dashboard_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';

abstract final class AppRoutes {
  static const getStarted = '/';
  static const login = '/login';
  static const signUp = '/signup';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const devices = '/devices';
  static const deviceSearch = '/devices/search';
  static const deviceDetails = '/devices/details';
  static const addDevice = '/devices/add';

  static Map<String, WidgetBuilder> build(
    AuthRepository authRepository,
    OnboardingRepository onboardingRepository, {
    DashboardRepository dashboardRepository = const MockDashboardRepository(),
    DeviceRepository deviceRepository = const MockDeviceRepository(),
  }) => {
    getStarted: (_) => const GetStartedPage(),
    login: (_) => LoginPage(authRepository: authRepository),
    signUp: (_) => SignUpScreen(authRepository: authRepository),
    forgotPassword: (_) => ForgotPasswordPage(authRepository: authRepository),
    onboarding: (_) => OnboardingPage(repository: onboardingRepository),
    // HomePage checks the session itself and returns to getStarted without one.
    home: (_) => HomePage(
      authRepository: authRepository,
      dashboardRepository: dashboardRepository,
      deviceRepository: deviceRepository,
      onboardingRepository: onboardingRepository,
    ),
    devices: (_) => DevicesPage(
      authRepository: authRepository,
      deviceRepository: deviceRepository,
      onboardingRepository: onboardingRepository,
    ),
    deviceSearch: (_) => DeviceSearchPage(
      authRepository: authRepository,
      deviceRepository: deviceRepository,
    ),
    addDevice: (_) =>
        OnboardingPage(repository: onboardingRepository, deviceOnly: true),
    deviceDetails: (context) => DeviceDetailPage(
      device: ModalRoute.of(context)!.settings.arguments! as DeviceData,
      authRepository: authRepository,
      deviceRepository: deviceRepository,
    ),
  };
}
