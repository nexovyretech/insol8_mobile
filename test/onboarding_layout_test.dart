import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_step.dart';
import 'package:insol8_mobile/pages/onboarding/device_setup_steps.dart';
import 'package:insol8_mobile/pages/onboarding/payment_steps.dart';
import 'package:insol8_mobile/pages/onboarding/subscription_steps.dart';
import 'package:insol8_mobile/pages/onboarding/welcome_step.dart';

// Every onboarding screen with a main button, on a small phone: the content
// may scroll, but nothing overflows and the button stays fully on screen
// (sticky) without scrolling.

const _small = Size(360, 640);
const _tall = Size(430, 1400);

const _plan = SubscriptionPlan(
  id: 'basic',
  name: 'Basic tier',
  price: 250,
  description: 'For a single shop',
  features: ['One branch'],
);

void _noop() {}

final Map<String, (Widget Function(), String)> _screens = {
  'welcome': (
    () => const OnboardingWelcomeStep(
      title: 'Welcome to inSOL8',
      description: 'Manage your solar-thermal dryers, branches and devices in one place.',
      pageIndex: 0,
      buttonLabel: 'Get Started',
      onContinue: _noop,
    ),
    'Get Started',
  ),
  'subscription': (
    () => OnboardingSubscriptionStep(
      plans: const [_plan, _plan],
      selectedPlan: 0,
      onPlanSelected: (_) {},
      onBack: _noop,
      onContinue: _noop,
    ),
    'Get Subscription',
  ),
  'payment': (
    () => OnboardingPaymentStep(
      plan: _plan,
      nextBillingDate: DateTime(2026, 11, 28),
      paymentMethod: SubscriptionPaymentMethod.gcash,
      onPaymentMethodChanged: (_) {},
      onBack: _noop,
      onContinue: _noop,
    ),
    'Pay ₱ 250.00 via GCash',
  ),
  'payment success': (
    () => const OnboardingPaymentSuccessStep(
      plan: _plan,
      buttonLabel: 'Continue',
      onContinue: _noop,
      onSkip: _noop,
    ),
    'Continue',
  ),
  'connect device': (
    () => OnboardingConnectDeviceStep(
      deviceCodeController: TextEditingController(),
      error: 'That device code was not found. Check it and try again.',
      onChanged: _noop,
      onBack: _noop,
      onSkip: _noop,
      onConnect: _noop,
      onScan: _noop,
    ),
    'Verify Device',
  ),
  'verify device': (
    () => const OnboardingVerifyDeviceStep(
      deviceCode: 'DEMO-INSOL8-001',
      error: 'We couldn’t verify this device. Please try again.',
      onBack: _noop,
      onSkip: _noop,
      onVerify: _noop,
    ),
    'Verify Device',
  ),
  'device setup': (
    () => OnboardingDeviceSetupStep(
      deviceNameController: TextEditingController(),
      deviceCode: 'DEMO-INSOL8-001',
      error: 'Enter a device name.',
      onChanged: _noop,
      onBack: _noop,
      onSkip: _noop,
      onFinish: _noop,
      onAddAnother: _noop,
    ),
    'Complete Registration',
  ),
  'branch setup (new manager)': (
    () => OnboardingBranchSetupStep(
      onBack: _noop,
      formKey: GlobalKey<FormState>(),
      branchNameController: TextEditingController(),
      branchAddressController: TextEditingController(),
      managerFirstNameController: TextEditingController(),
      managerLastNameController: TextEditingController(),
      managerOption: BranchManagerOption.newManager,
      isSaving: false,
      onManagerOptionChanged: (_) {},
      onFieldChanged: _noop,
      onSkip: _noop,
      onFinish: _noop,
    ),
    'Finish Setup',
  ),
};

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  Size size, {
  double keyboard = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
  // Some screens animate continuously, so pump frames instead of settling.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final MapEntry(key: name, value: (build, label)) in _screens.entries) {
    testWidgets('$name: no overflow and a sticky button on a small phone', (
      tester,
    ) async {
      await _pump(tester, build(), _small);
      // A RenderFlex overflow is reported as an exception during layout.
      expect(tester.takeException(), isNull, reason: 'layout overflowed');

      final button = find.text(label);
      expect(button, findsOneWidget);
      final rect = tester.getRect(button);
      expect(rect.top, greaterThanOrEqualTo(0), reason: 'button above screen');
      expect(
        rect.bottom,
        lessThanOrEqualTo(_small.height),
        reason: 'button is below the screen (not sticky)',
      );
      await tester.tap(button);
    });

    testWidgets('$name: button stays above an open keyboard', (tester) async {
      const keyboard = 300.0;
      await _pump(tester, build(), _small, keyboard: keyboard);
      expect(tester.takeException(), isNull, reason: 'layout overflowed');
      expect(
        tester.getRect(find.text(label)).bottom,
        lessThanOrEqualTo(_small.height - keyboard),
        reason: 'button is hidden behind the keyboard',
      );
    });

    testWidgets('$name: button sits at the bottom on a tall screen', (
      tester,
    ) async {
      await _pump(tester, build(), _tall);
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text(label)).bottom,
        greaterThan(_tall.height * 0.75),
      );
    });
  }
}
