import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/settings/account_profile_page.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/utils/phone_number.dart';
import 'package:insol8_mobile/utils/profile_rules.dart';
import 'package:insol8_mobile/widgets/auth/phone_number_field.dart';

import 'support/code_entry.dart';
import 'support/fake_repositories.dart';

class _NoDevices extends UnusedDeviceRepository {
  const _NoDevices();

  @override
  Future<List<DeviceData>> fetchDevices() async => const [];
}

class _BrokenDevices extends UnusedDeviceRepository {
  const _BrokenDevices();

  @override
  Future<List<DeviceData>> fetchDevices() async =>
      throw Exception('devices are down');
}

class _NoBranches extends UnusedBranchRepository {
  const _NoBranches();

  @override
  Future<List<BranchData>> fetchBranches() async => const [];
}

/// An email sign-up without a mobile number; records contact changes.
class _ProfileAuth extends UnconfiguredAuthRepository {
  _ProfileAuth(this.profile);

  UserProfile profile;
  final calls = <String>[];

  @override
  Future<UserProfile> loadProfile() async => profile;

  @override
  Future<void> requestMobileNumberChange(String mobileNumber) async =>
      calls.add('request:$mobileNumber');

  @override
  Future<UserProfile> confirmMobileNumberChange({
    required String mobileNumber,
    required String code,
  }) async {
    calls.add('confirm:$mobileNumber:$code');
    return profile = UserProfile(
      username: profile.username,
      firstName: profile.firstName,
      lastName: profile.lastName,
      email: profile.email,
      mobileNumber: mobileNumber,
    );
  }
}

Widget _page(AuthRepository auth) => MaterialApp(
  home: AccountProfilePage(
    authRepository: auth,
    branchRepository: const _NoBranches(),
    deviceRepository: const _NoDevices(),
    subscriptionRepository: const FakeSubscriptionRepository(
      SubscriptionPlanIds.basic,
    ),
  ),
);

void main() {
  test('Philippine mobile helpers normalize, format, and spot Smart/TNT', () {
    expect(normalizePhilippineMobile('0917 123 4567'), '+639171234567');
    expect(normalizePhilippineMobile('917-123-4567'), '+639171234567');
    expect(normalizePhilippineMobile('+1 415 555 0123'), isNull);
    expect(formatPhilippineMobile('+639171234567'), '+63 917 123 4567');
    expect(isSmartNetworkNumber('+639181234567'), isTrue); // Smart
    expect(isSmartNetworkNumber('+639981234567'), isTrue); // TNT
    expect(isSmartNetworkNumber('+639171234567'), isFalse); // Globe
    expect(isSmartNetworkNumber('+639911234567'), isFalse); // DITO
  });

  testWidgets('an empty mobile number can be added with a texted code', (
    tester,
  ) async {
    final auth = _ProfileAuth(
      const UserProfile(
        username: 'jane',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
      ),
    );
    await tester.pumpWidget(_page(auth));
    await tester.pumpAndSettle();

    expect(find.text('jane@example.com'), findsOneWidget);
    await tester.tap(find.text('Add mobile number'));
    await tester.pumpAndSettle();
    expect(find.text('Add Mobile Number'), findsOneWidget);
    expect(find.text('🇵🇭'), findsOneWidget);

    // Smart and TNT numbers are refused before any code is sent.
    final field = find.descendant(
      of: find.byType(PhoneNumberField),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(field, '918');
    await tester.pump();
    expect(find.text(smartNetworkUnsupportedMessage), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(auth.calls, isEmpty);

    await tester.enterText(field, '9171234567');
    await tester.pump();
    expect(find.text(smartNetworkUnsupportedMessage), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('+63 917 123 4567', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(auth.calls, ['request:+639171234567']);

    expect(find.text('Verify Mobile Number'), findsOneWidget);
    // Six boxes like sign-up; the last digit verifies on its own.
    await enterCode(tester, '123456');
    expect(auth.calls.last, 'confirm:+639171234567:123456');
    expect(find.text('Mobile Number Added!'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('+63 917 123 4567'), findsOneWidget);
    expect(find.text('Add mobile number'), findsNothing);
  });

  testWidgets('a mobile sign-up is offered to add an email', (tester) async {
    final auth = _ProfileAuth(
      const UserProfile(
        username: 'juan',
        firstName: 'Juan',
        lastName: 'Cruz',
        mobileNumber: '+639171234567',
      ),
    );
    await tester.pumpWidget(_page(auth));
    await tester.pumpAndSettle();

    expect(find.text('+63 917 123 4567'), findsOneWidget);
    await tester.tap(find.text('Add email address'));
    await tester.pumpAndSettle();
    expect(find.text('Add Email Address'), findsOneWidget);
  });

  testWidgets('a name with numbers or symbols is refused and Save greys out', (
    tester,
  ) async {
    final auth = _ProfileAuth(
      const UserProfile(
        username: 'jane',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
      ),
    );
    await tester.pumpWidget(_page(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jane'));
    await tester.pumpAndSettle();
    FilledButton save() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));

    await tester.enterText(find.byType(TextField).last, 'Jane2');
    await tester.pump();
    expect(find.textContaining('Use letters only'), findsOneWidget);
    expect(save().onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'Ma. Theresa');
    await tester.pump();
    expect(find.textContaining('Use letters only'), findsNothing);
    expect(save().onPressed, isNotNull);
  });

  test('name rule: letters with spaces, hyphens, apostrophes, periods', () {
    for (final name in ['De La Cruz', "O'Neil", 'Ma. Theresa', 'Peña']) {
      expect(nameProblem(name, 'first name'), isNull, reason: name);
    }
    for (final name in ['Juan2', r'J@ne', 'Juan_Cruz', '-Juan']) {
      expect(nameProblem(name, 'first name'), isNotNull, reason: name);
    }
  });

  testWidgets('one failed request leaves the rest of the profile showing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountProfilePage(
          authRepository: _ProfileAuth(
            const UserProfile(
              username: 'jane',
              firstName: 'Jane',
              lastName: 'Doe',
              email: 'jane@example.com',
            ),
          ),
          branchRepository: const _NoBranches(),
          deviceRepository: const _BrokenDevices(),
          // An account that hasn't picked a plan yet.
          subscriptionRepository: const FakeSubscriptionRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('jane@example.com'), findsOneWidget);
    // Business Info sits below the first screen.
    await tester.scrollUntilVisible(find.text('Registered Branches'), 200);
    await tester.pumpAndSettle();
    expect(find.text('No plan yet'), findsOneWidget);
    expect(find.text('0 Branches'), findsOneWidget);
    expect(find.text('—'), findsWidgets); // devices couldn't load
  });
}
