import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/pages/analytics/analytics_page.dart';
import 'package:insol8_mobile/pages/branches/branches_page.dart';
import 'package:insol8_mobile/pages/auth/forgot_password/forgot_password_page.dart';
import 'package:insol8_mobile/pages/auth/get_started_page.dart';
import 'package:insol8_mobile/pages/auth/login_page.dart';
import 'package:insol8_mobile/pages/auth/signup/sign_up_screen.dart';
import 'package:insol8_mobile/pages/devices/device_detail_page.dart';
import 'package:insol8_mobile/pages/devices/device_search_page.dart';
import 'package:insol8_mobile/pages/devices/devices_page.dart';
import 'package:insol8_mobile/pages/home/home_page.dart';
import 'package:insol8_mobile/pages/settings/settings_page.dart';
import 'package:insol8_mobile/pages/settings/account_profile_page.dart';
import 'package:insol8_mobile/pages/settings/password_security_page.dart';
import 'package:insol8_mobile/pages/settings/settings_content_page.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/analytics_repository.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/services/dashboard_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/live_telemetry.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';

/// Maps route paths to pages and passes page-specific repository dependencies.
abstract final class AppRouteRegistry {
  static Map<String, WidgetBuilder> build(
    AuthRepository authRepository,
    OnboardingRepository onboardingRepository, {
    required DashboardRepository dashboardRepository,
    required DeviceRepository deviceRepository,
    required AnalyticsRepository analyticsRepository,
    required BranchRepository branchRepository,
    required SubscriptionRepository subscriptionRepository,
    LiveTelemetrySource? liveTelemetry,
  }) => {
    AppRoutes.getStarted: (_) => const GetStartedPage(),
    AppRoutes.login: (_) => LoginPage(authRepository: authRepository),
    AppRoutes.signUp: (_) => SignUpScreen(authRepository: authRepository),
    AppRoutes.forgotPassword: (_) =>
        ForgotPasswordPage(authRepository: authRepository),
    AppRoutes.onboarding: (_) =>
        OnboardingPage(repository: onboardingRepository),
    // HomePage checks the session itself and returns to getStarted without one.
    AppRoutes.home: (_) => HomePage(
      authRepository: authRepository,
      dashboardRepository: dashboardRepository,
      deviceRepository: deviceRepository,
      onboardingRepository: onboardingRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.devices: (_) => DevicesPage(
      authRepository: authRepository,
      deviceRepository: deviceRepository,
      onboardingRepository: onboardingRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.branches: (_) => BranchesPage(
      authRepository: authRepository,
      branchRepository: branchRepository,
      deviceRepository: deviceRepository,
      onboardingRepository: onboardingRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.analytics: (_) => AnalyticsPage(
      authRepository: authRepository,
      analyticsRepository: analyticsRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.settings: (_) => SettingsPage(
      authRepository: authRepository,
      branchRepository: branchRepository,
      deviceRepository: deviceRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.accountProfile: (_) => AccountProfilePage(
      authRepository: authRepository,
      branchRepository: branchRepository,
      deviceRepository: deviceRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.passwordSecurity: (_) => PasswordSecurityPage(
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.billingInformation: (_) => SettingsContentPage(
      type: SettingsContentType.billing,
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.changePlan: (context) => OnboardingPage(
      repository: onboardingRepository,
      pricingOnly: true,
      initialPlanId: ModalRoute.of(context)?.settings.arguments as String?,
    ),
    AppRoutes.preferences: (_) => SettingsContentPage(
      type: SettingsContentType.preferences,
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.faqs: (_) => SettingsContentPage(
      type: SettingsContentType.faqs,
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.troubleshooting: (_) => SettingsContentPage(
      type: SettingsContentType.troubleshooting,
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.userGuide: (_) => SettingsContentPage(
      type: SettingsContentType.userGuide,
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.reportIssue: (_) => SettingsContentPage(
      type: SettingsContentType.reportIssue,
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.aboutUs: (_) => SettingsContentPage(
      type: SettingsContentType.aboutUs,
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.deviceSearch: (_) => DeviceSearchPage(
      authRepository: authRepository,
      deviceRepository: deviceRepository,
    ),
    AppRoutes.addDevice: (_) =>
        OnboardingPage(repository: onboardingRepository, deviceOnly: true),
    AppRoutes.deviceDetails: (context) => DeviceDetailPage(
      device: ModalRoute.of(context)!.settings.arguments! as DeviceData,
      authRepository: authRepository,
      deviceRepository: deviceRepository,
      liveTelemetry: liveTelemetry,
    ),
  };
}
