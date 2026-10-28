import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/device_setup_data.dart';
import 'package:insol8_mobile/models/onboarding_status.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_page.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';

const _plans = [
  SubscriptionPlan(
    id: 'basic',
    name: 'Basic tier',
    price: 250,
    description: 'For single laundry shops.',
    features: ['Device monitoring'],
  ),
  SubscriptionPlan(
    id: 'organization',
    name: 'Organization tier',
    price: 500,
    description: 'For multi-branch businesses.',
    features: ['Multiple branch registration'],
    maxBranches: null,
    canAssignManagers: true,
  ),
];

/// Scripted backend: payment is confirmed only after [markPaid] (the webhook)
/// or once the app's confirm call finds it paid at the provider.
class _FakeRepository implements OnboardingRepository {
  OnboardingStatus status = const OnboardingStatus();

  /// Reference PayMongo reports as paid; the webhook may not have arrived.
  String? paidAtProvider;
  final confirmed = <String>[];
  final opened = <Uri>[];
  BranchSetupData? branch;
  DeviceSetupData? device;
  int statusChecks = 0;
  Object? deviceError;

  void markPaid(String reference) => status = OnboardingStatus(
    subscriptionStatus: 'active',
    activePlanId: 'basic',
    lastPaidReference: reference,
    currentPeriodEnd: DateTime.utc(2026, 11, 28),
  );

  @override
  Future<List<SubscriptionPlan>> fetchSubscriptionPlans() async => _plans;

  @override
  Future<OnboardingStatus> fetchOnboardingStatus() async {
    statusChecks++;
    return status;
  }

  @override
  Future<CheckoutSession> createCheckoutSession({
    required String planId,
    required SubscriptionPaymentMethod paymentMethod,
  }) async => CheckoutSession(
    checkoutUrl: Uri.parse('https://checkout.paymongo.test/cs_1'),
    reference: 'INSOL8-ref-1',
  );

  @override
  Future<bool> confirmPayment(String reference) async {
    confirmed.add(reference);
    if (paidAtProvider == reference) markPaid(reference);
    return paidAtProvider == reference;
  }

  @override
  Future<String> createBranch(BranchSetupData data) async {
    branch = data;
    return 'branch-1';
  }

  @override
  Future<void> pairDevice(DevicePairingRequest request) async {
    if (deviceError != null) throw deviceError!;
  }

  @override
  Future<void> verifyDevice(DeviceVerificationRequest request) async {}

  @override
  Future<void> configureDevice(DeviceSetupData data) async => device = data;
}

Future<void> _pump(WidgetTester tester, _FakeRepository repo) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      routes: {'/home': (_) => const Text('HOME')},
      home: OnboardingPage(
        repository: repo,
        openCheckout: (url) async {
          repo.opened.add(url);
          return true;
        },
        paymentPollInterval: const Duration(seconds: 1),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The payment-waiting screen's spinner never settles, so on that screen time
// is advanced instead of waiting for animations to finish.
Future<void> _tap(
  WidgetTester tester,
  String text, {
  bool fromSpinner = false,
  bool toSpinner = false,
}) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  fromSpinner ? await _advance(tester) : await tester.pumpAndSettle();
  await tester.tap(target);
  toSpinner ? await _advance(tester) : await tester.pumpAndSettle();
}

Future<void> _advance(WidgetTester tester, [int seconds = 1]) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _toPaymentWaiting(WidgetTester tester) async {
  await _tap(tester, 'Continue');
  await _tap(tester, 'Get Started');
  await _tap(tester, 'Get Subscription');
  await _tap(tester, 'Pay ₱ 250.00 via GCash', toSpinner: true);
}

void main() {
  testWidgets('waits for the backend to confirm this checkout before success', (
    tester,
  ) async {
    final repo = _FakeRepository();
    await _pump(tester, repo);
    await _toPaymentWaiting(tester);

    expect(
      repo.opened.single.toString(),
      'https://checkout.paymongo.test/cs_1',
    );
    expect(find.text('Waiting for your payment'), findsOneWidget);

    // An earlier, unrelated payment must not count as this one.
    repo.markPaid('INSOL8-older');
    await _advance(tester, 2);
    expect(find.text('Waiting for your payment'), findsOneWidget);

    repo.markPaid('INSOL8-ref-1');
    await _advance(tester, 2);
    await tester.pumpAndSettle();
    expect(find.text('Your payment has been successful!'), findsOneWidget);
    expect(find.text('INSOL8-ref-1'), findsOneWidget);
    expect(find.text('November 28, 2026'), findsOneWidget);
  });

  testWidgets(
    'shows success by itself once PayMongo reports the payment, webhook or not',
    (tester) async {
      final repo = _FakeRepository();
      await _pump(tester, repo);
      await _toPaymentWaiting(tester);
      expect(repo.confirmed, contains('INSOL8-ref-1'));

      // Paid at PayMongo, no webhook: coming back from the browser is enough.
      repo.paidAtProvider = 'INSOL8-ref-1';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _advance(tester);
      await tester.pumpAndSettle();
      expect(find.text('Your payment has been successful!'), findsOneWidget);
      expect(find.text('INSOL8-ref-1'), findsOneWidget);
    },
  );

  testWidgets('cancelling stops waiting and returns to payment', (
    tester,
  ) async {
    final repo = _FakeRepository();
    await _pump(tester, repo);
    await _toPaymentWaiting(tester);
    await _tap(tester, 'Cancel payment', fromSpinner: true);
    final checks = repo.statusChecks;
    await _advance(tester, 5);
    expect(repo.statusChecks, checks);
    expect(find.text('Pay ₱ 250.00 via GCash'), findsOneWidget);
  });

  testWidgets(
    'Basic users set up a self-managed branch, then link devices to it',
    (tester) async {
      final repo = _FakeRepository();
      await _pump(tester, repo);
      await _toPaymentWaiting(tester);
      repo.markPaid('INSOL8-ref-1');
      await _advance(tester, 2);
      await tester.pumpAndSettle();
      await _tap(tester, 'Set Up Branch');

      expect(
        find.text(
          'Assigning a separate manager is available on the Organization plan.',
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Main Branch');
      await tester.enterText(find.byType(TextFormField).at(1), '12 Rizal St');
      // The new-manager option is disabled on Basic.
      await _tap(tester, 'Add a new manager');
      expect(find.text('First name'), findsNothing);
      await _tap(tester, 'Assign myself as manager');
      await _tap(tester, 'Finish Setup');
      expect(repo.branch?.managerOption, BranchManagerOption.myself);

      await tester.enterText(find.byType(TextField).first, 'DRYER-0001');
      await tester.pumpAndSettle();
      await _tap(tester, 'Verify Device');
      await _tap(tester, 'Verify Device');
      await _tap(tester, 'OK');
      await tester.enterText(find.byType(TextField).first, 'Front dryer');
      await tester.pumpAndSettle();
      await _tap(tester, 'Complete Registration');

      expect(repo.device?.deviceCode, 'DRYER-0001');
      expect(repo.device?.deviceName, 'Front dryer');
      expect(repo.device?.branchId, 'branch-1');
      expect(find.text('HOME'), findsOneWidget);
    },
  );

  testWidgets('shows why a device code was rejected', (tester) async {
    final repo = _FakeRepository()
      ..deviceError = const ApiException(409, 'DEVICE_UNAVAILABLE', 'Taken.');
    repo.markPaid('INSOL8-ref-1');
    repo.status = OnboardingStatus(
      subscriptionStatus: 'active',
      activePlanId: 'basic',
      lastPaidReference: 'INSOL8-ref-1',
      primaryBranchId: 'branch-1',
    );
    // Already paid with a branch: opening onboarding resumes at device setup.
    await _pump(tester, repo);
    await tester.enterText(find.byType(TextField).first, 'DRYER-0001');
    await tester.pumpAndSettle();
    await _tap(tester, 'Verify Device');
    expect(
      find.text('This device is already linked to another account.'),
      findsOneWidget,
    );
  });
}
