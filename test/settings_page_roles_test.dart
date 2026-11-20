import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/settings/settings_page.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';

import 'support/fake_repositories.dart';

class _RoleAuthRepository extends UnconfiguredAuthRepository {
  const _RoleAuthRepository(this.profile);

  final UserProfile profile;

  @override
  Future<UserProfile> loadProfile() async => profile;
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required AccountRole role,
  required String? planId,
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final name = switch (role) {
    AccountRole.owner => 'Jane',
    AccountRole.manager => 'Jhon',
  };
  await tester.pumpWidget(
    MaterialApp(
      home: SettingsPage(
        authRepository: _RoleAuthRepository(
          UserProfile(
            username: '${name.toLowerCase()}.doe',
            firstName: name,
            lastName: 'Doe',
            email: '${name.toLowerCase()}doe@email.com',
            role: role,
          ),
        ),
        branchRepository: const UnusedBranchRepository(),
        deviceRepository: const UnusedDeviceRepository(),
        subscriptionRepository: FakeSubscriptionRepository(planId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('organization owner shows Manager Management', (tester) async {
    await _pumpSettings(
      tester,
      role: AccountRole.owner,
      planId: SubscriptionPlanIds.organization,
    );

    expect(find.text('Password & security'), findsOneWidget);
    expect(find.text('Password & Security'), findsNothing);
    expect(find.text('Billing Information'), findsOneWidget);
    expect(find.text('Subscription & Usage'), findsOneWidget);
    expect(find.text('Manager Management'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('FAQS'), findsOneWidget);
    expect(find.text('Troubleshooting'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('basic owner has no Manager Management', (tester) async {
    await _pumpSettings(
      tester,
      role: AccountRole.owner,
      planId: SubscriptionPlanIds.basic,
    );

    expect(find.text('Password & Security'), findsOneWidget);
    expect(find.text('Password & security'), findsNothing);
    expect(find.text('Billing Information'), findsOneWidget);
    expect(find.text('Subscription & Usage'), findsOneWidget);
    expect(find.text('Manager Management'), findsNothing);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('FAQS'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('manager hides billing, subscription and manager rows', (
    tester,
  ) async {
    // The manager screenshot is on an Org-tier account, so role must win over
    // the plan tier.
    await _pumpSettings(
      tester,
      role: AccountRole.manager,
      planId: SubscriptionPlanIds.organization,
    );

    expect(find.text('Password & Security'), findsOneWidget);
    expect(find.text('Password & security'), findsNothing);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Billing Information'), findsNothing);
    expect(find.text('Subscription & Usage'), findsNothing);
    expect(find.text('Manager Management'), findsNothing);
    expect(find.text('FAQS'), findsOneWidget);
    expect(find.text('Troubleshooting'), findsOneWidget);
    expect(find.text('User Guide'), findsOneWidget);
    expect(find.text('Report Issue'), findsOneWidget);
    expect(find.text('About Us'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  test('profile API role is parsed with owner fallback', () {
    UserProfile profileFromRole(String role) => UserProfile.fromJson({
      'username': 'jane.doe',
      'firstName': 'Jane',
      'lastName': 'Doe',
      'role': role,
    });

    expect(profileFromRole('manager').role, AccountRole.manager);
    expect(profileFromRole('branch_manager').role, AccountRole.manager);
    expect(profileFromRole('OWNER').role, AccountRole.owner);
    expect(
      UserProfile.fromJson({
        'username': 'jane.doe',
        'firstName': 'Jane',
        'lastName': 'Doe',
      }).role,
      AccountRole.owner,
    );
  });
}
