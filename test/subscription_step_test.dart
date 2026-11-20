import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/pages/onboarding/subscription_steps.dart';

const _plans = [
  SubscriptionPlan(
    id: 'basic',
    name: 'Basic tier',
    price: 249.99,
    description: 'For a single shop',
    features: ['One branch'],
  ),
  SubscriptionPlan(
    id: 'organization',
    name: 'Organization tier',
    price: 499.99,
    description: 'For growing businesses',
    features: ['Multiple branches'],
  ),
];

Future<bool> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  var continued = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: OnboardingSubscriptionStep(
          plans: _plans,
          selectedPlan: 0,
          onPlanSelected: (_) {},
          onBack: () {},
          onContinue: () => continued = true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // A RenderFlex overflow is reported as an exception during layout.
  expect(tester.takeException(), isNull);

  final button = find.text('Get Subscription');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  return continued;
}

void main() {
  testWidgets('shows the Basic/Org comparison and Figma prices', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 740);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingSubscriptionStep(
            plans: _plans,
            selectedPlan: 0,
            onPlanSelected: (_) {},
            onBack: () {},
            onContinue: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BASIC'), findsOneWidget);
    expect(find.text('ORG'), findsOneWidget);
    // Basic has 4 checks + 2 X marks; Org has 6 checks.
    expect(find.byIcon(Icons.check_circle), findsNWidgets(10));
    expect(find.byIcon(Icons.cancel), findsNWidgets(2));
    expect(find.text('₱ 299.00'), findsOneWidget);
    expect(find.text('₱ 499.00'), findsOneWidget);
    expect(find.text('/ month'), findsNWidgets(2));
  });

  testWidgets('Get Subscription does not overflow on a small phone', (
    tester,
  ) async {
    expect(await _pumpAt(tester, const Size(360, 740)), isTrue);
  });

  testWidgets('Get Subscription stays pinned to the bottom on a tall screen', (
    tester,
  ) async {
    expect(await _pumpAt(tester, const Size(430, 1400)), isTrue);
    final buttonBottom = tester.getBottomLeft(find.text('Get Subscription')).dy;
    expect(buttonBottom, greaterThan(1400 * 0.8));
  });
}
