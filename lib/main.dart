import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insol8_mobile/amplifyconfiguration.dart';
import 'package:insol8_mobile/routes/app_route_registry.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/analytics_repository.dart';
import 'package:insol8_mobile/services/api_branch_repository.dart';
import 'package:insol8_mobile/services/api_device_repository.dart';
import 'package:insol8_mobile/services/api_insights_repository.dart';
import 'package:insol8_mobile/services/api_onboarding_repository.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/services/cognito_auth_repository.dart';
import 'package:insol8_mobile/services/dashboard_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/live_telemetry.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authConfigured = await _configureAuth();
  final AuthRepository authRepository = authConfigured
      ? CognitoAuthRepository()
      : UnconfiguredAuthRepository();
  // Onboarding always talks to the API; without Cognito its calls fail with
  // a sign-in error instead of falling back to sample data.
  final OnboardingRepository onboardingRepository = ApiOnboardingRepository();
  final initialRoute = await authRepository.hasActiveSession()
      ? AppRoutes.home
      : AppRoutes.getStarted;

  // Like onboarding, these always use the API (no sample-data fallback).
  runApp(
    ProviderScope(
      child: Insol8App(
        authRepository: authRepository,
        initialRoute: initialRoute,
        onboardingRepository: onboardingRepository,
        dashboardRepository: ApiDashboardRepository(),
        deviceRepository: ApiDeviceRepository(),
        analyticsRepository: ApiAnalyticsRepository(),
        branchRepository: ApiBranchRepository(),
        subscriptionRepository: ApiSubscriptionRepository(),
        liveTelemetry: WebSocketLiveTelemetry(),
      ),
    ),
  );
}

Future<bool> _configureAuth() async {
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(jsonEncode(amplifyConfig.toJson()));
    safePrint('Amplify initialized successfully.');
    return true;
  } on AmplifyAlreadyConfiguredException {
    return true;
  } on Exception catch (error) {
    safePrint('Could not initialize Amplify: $error');
    return false;
  }
}

class Insol8App extends StatelessWidget {
  const Insol8App({
    super.key,
    required this.authRepository,
    required this.initialRoute,
    required this.onboardingRepository,
    required this.dashboardRepository,
    required this.deviceRepository,
    required this.analyticsRepository,
    required this.branchRepository,
    required this.subscriptionRepository,
    this.liveTelemetry,
  });

  final AuthRepository authRepository;
  final String initialRoute;

  /// [ApiOnboardingRepository] in the app; a fake in widget tests.
  final OnboardingRepository onboardingRepository;

  final DashboardRepository dashboardRepository;
  final DeviceRepository deviceRepository;
  final AnalyticsRepository analyticsRepository;
  final BranchRepository branchRepository;

  /// The account's paid plan, which decides the Basic or Organization screens.
  final SubscriptionRepository subscriptionRepository;

  /// Live dryer readings on the device page; null in widget tests.
  final LiveTelemetrySource? liveTelemetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'inSOL8',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      routes: AppRouteRegistry.build(
        authRepository,
        onboardingRepository,
        dashboardRepository: dashboardRepository,
        deviceRepository: deviceRepository,
        analyticsRepository: analyticsRepository,
        branchRepository: branchRepository,
        subscriptionRepository: subscriptionRepository,
        liveTelemetry: liveTelemetry,
      ),
    );
  }
}
