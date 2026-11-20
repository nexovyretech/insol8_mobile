import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/home/home_page.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/fake_repositories.dart';

class _SignedIn extends UnconfiguredAuthRepository {
  const _SignedIn();

  @override
  bool get isConfigured => true;

  @override
  Future<bool> hasActiveSession() async => true;

  @override
  Future<UserProfile> loadProfile() async => const UserProfile(
    username: 'juan',
    firstName: 'Juan',
    lastName: 'Cruz',
    email: 'juan@example.com',
  );
}

class _FetchingDeviceRepository implements DeviceRepository {
  const _FetchingDeviceRepository();

  @override
  Future<List<DeviceData>> fetchDevices() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  testWidgets('New drying job opens the shared Drying Jobs sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          authRepository: const _SignedIn(),
          dashboardRepository: const FakeDashboardRepository(),
          deviceRepository: const _FetchingDeviceRepository(),
          onboardingRepository: const FakeOnboardingRepository(),
          subscriptionRepository: const FakeSubscriptionRepository('basic'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New drying job'), findsOneWidget);
    await tester.tap(find.text('New drying job'));
    await tester.pumpAndSettle();

    expect(find.text('Drying Jobs'), findsOneWidget);
  });
}
