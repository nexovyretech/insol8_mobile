import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/manager_auth_args.dart';
import 'package:insol8_mobile/models/manager_data.dart';
import 'package:insol8_mobile/pages/analytics/analytics_page.dart';
import 'package:insol8_mobile/pages/branches/branches_page.dart';
import 'package:insol8_mobile/pages/auth/forgot_password/forgot_password_page.dart';
import 'package:insol8_mobile/pages/auth/get_started_page.dart';
import 'package:insol8_mobile/pages/auth/login_page.dart';
import 'package:insol8_mobile/pages/auth/manager_auth_page.dart';
import 'package:insol8_mobile/pages/auth/signup/sign_up_screen.dart';
import 'package:insol8_mobile/pages/devices/device_detail_page.dart';
import 'package:insol8_mobile/pages/devices/device_search_page.dart';
import 'package:insol8_mobile/pages/devices/devices_page.dart';
import 'package:insol8_mobile/pages/home/home_page.dart';
import 'package:insol8_mobile/pages/settings/settings_page.dart';
import 'package:insol8_mobile/pages/settings/account_profile_page.dart';
import 'package:insol8_mobile/pages/settings/billing/add_on_pages.dart';
import 'package:insol8_mobile/pages/settings/billing/payment_history_page.dart';
import 'package:insol8_mobile/pages/settings/billing/subscription_locked_page.dart';
import 'package:insol8_mobile/pages/settings/billing/subscription_usage_page.dart';
import 'package:insol8_mobile/pages/settings/managers/add_manager_page.dart';
import 'package:insol8_mobile/pages/settings/managers/manager_access_page.dart';
import 'package:insol8_mobile/pages/settings/managers/manager_management_page.dart';
import 'package:insol8_mobile/pages/settings/password_security_page.dart';
import 'package:insol8_mobile/pages/settings/settings_content_page.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/analytics_repository.dart';
import 'package:insol8_mobile/services/app_update_service.dart';
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

    /// About Us > Check for updates; a real [AppUpdateService] when null (it
    /// does nothing off Android or in debug builds, including widget tests).
    AppUpdateService? appUpdateService,
  }) => {
    AppRoutes.getStarted: (_) => const GetStartedPage(),
    AppRoutes.login: (_) => LoginPage(authRepository: authRepository),
    AppRoutes.signUp: (_) => SignUpScreen(authRepository: authRepository),
    AppRoutes.managerAuth: (context) => ManagerAuthPage(
      args: ManagerAuthArgs.from(ModalRoute.of(context)?.settings.arguments),
    ),
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
    AppRoutes.managerManagement: (_) =>
        ManagerManagementPage(branchRepository: branchRepository),
    AppRoutes.managerAccess: (context) => ManagerAccessPage(
      manager: ModalRoute.of(context)?.settings.arguments as ManagerData?,
      branchRepository: branchRepository,
    ),
    AppRoutes.addManager: (_) =>
        AddManagerPage(branchRepository: branchRepository),
    AppRoutes.passwordSecurity: (_) => PasswordSecurityPage(
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.billingInformation: (_) => SettingsContentPage(
      type: SettingsContentType.billing,
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.subscriptionUsage: (context) => SubscriptionUsagePage(
      planId: ModalRoute.of(context)?.settings.arguments as String?,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.additionalBranch: (context) {
      final args = AddOnFlowArgs.from(
        ModalRoute.of(context)?.settings.arguments,
      );
      return AddOnPurchasePage(
        kind: args.kind,
        planId: args.planId,
        branchRepository: branchRepository,
      );
    },
    AppRoutes.additionalDevice: (context) {
      final args = AddOnFlowArgs.from(
        ModalRoute.of(context)?.settings.arguments,
      );
      return AddOnPurchasePage(
        kind: args.kind,
        planId: args.planId,
        branchRepository: branchRepository,
      );
    },
    AppRoutes.additionalBranchSuccess: (context) {
      final args = AddOnFlowArgs.from(
        ModalRoute.of(context)?.settings.arguments,
      );
      return AddOnSuccessPage(
        kind: args.kind,
        planId: args.planId,
        branchName: args.branchName,
      );
    },
    AppRoutes.additionalDeviceSuccess: (context) {
      final args = AddOnFlowArgs.from(
        ModalRoute.of(context)?.settings.arguments,
      );
      return AddOnSuccessPage(
        kind: args.kind,
        planId: args.planId,
        branchName: args.branchName,
      );
    },
    AppRoutes.subscriptionLocked: (_) => SubscriptionLockedPage(
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.paymentHistory: (_) => PaymentHistoryPage(
      authRepository: authRepository,
      subscriptionRepository: subscriptionRepository,
    ),
    AppRoutes.changePlan: (context) => OnboardingPage(
      repository: onboardingRepository,
      pricingOnly: true,
      subscriptionRepository: subscriptionRepository,
      branchRepository: branchRepository,
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
      appUpdateService: appUpdateService,
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
