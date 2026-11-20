import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/pages/settings/billing/add_on_pages.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_theme.dart';

Future<void> _pumpPurchase(
  WidgetTester tester, {
  required AddOnKind kind,
  required String planId,
  Map<String, WidgetBuilder> routes = const {},
}) async {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: AddOnPurchasePage(kind: kind, planId: planId),
      routes: routes,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('flow args accept string-typed route arguments', () {
    final args = AddOnFlowArgs.from(const {
      'kind': 'branch',
      'planId': SubscriptionPlanIds.organization,
    });

    expect(args.kind, AddOnKind.branch);
    expect(args.planId, SubscriptionPlanIds.organization);
  });

  testWidgets('organization additional branch frame and payment flow', (
    tester,
  ) async {
    await _pumpPurchase(
      tester,
      kind: AddOnKind.branch,
      planId: SubscriptionPlanIds.organization,
      routes: {
        AppRoutes.additionalBranchSuccess: (context) => Text(
          'Success ${(ModalRoute.of(context)?.settings.arguments as Map)['kind']}',
        ),
      },
    );

    expect(find.text('Expand your organization'), findsOneWidget);
    expect(find.text('ADDITIONAL BRANCH'), findsOneWidget);
    expect(find.text('₱250.00'), findsOneWidget);
    expect(find.text('Pay ₱265.00 via GCash'), findsOneWidget);
    expect(find.text('Cancel anytime. No commitments.'), findsOneWidget);

    // Orange check/bullet icons before every included feature.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                const Color(0xFFD97247) &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
      findsNWidgets(4),
    );

    // The light-orange frame from the screenshot.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                const Color(0xFFFDF6F1),
      ),
      findsOneWidget,
    );

    // The missing ">" chevrons are present and tappable.
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(find.text('Caloocan Branch'), findsOneWidget);
    await tester.tap(find.text('Caloocan Branch'));
    await tester.pumpAndSettle();
    expect(find.text('Caloocan Branch'), findsOneWidget);

    await tester.tap(find.text('Maya'));
    await tester.pumpAndSettle();
    expect(find.text('Pay ₱265.00 via Maya'), findsOneWidget);

    await tester.tap(find.text('Pay ₱265.00 via Maya'));
    await tester.pumpAndSettle();
    expect(find.text('Success branch'), findsOneWidget);
  });

  testWidgets('basic additional device uses the Basic price', (tester) async {
    await _pumpPurchase(
      tester,
      kind: AddOnKind.device,
      planId: SubscriptionPlanIds.basic,
    );

    expect(find.text('Add Additional Devices'), findsOneWidget);
    expect(find.text('ADDITIONAL DEVICE'), findsOneWidget);
    expect(find.text('₱35.00'), findsOneWidget);
    expect(find.text('Pay ₱55.00 via GCash'), findsOneWidget);
    expect(find.text('Select Branch'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
  });

  testWidgets('success page buttons redirect to branches and dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AddOnSuccessPage(
          kind: AddOnKind.device,
          planId: SubscriptionPlanIds.basic,
        ),
        routes: {
          AppRoutes.branches: (_) => const Text('Branches page'),
          AppRoutes.home: (_) => const Text('Dashboard page'),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your payment has been\nsuccessful!'), findsOneWidget);
    expect(find.text('You paid ₱35.00 to'), findsOneWidget);
    expect(find.text('InSOL8 Additional Devices'), findsOneWidget);
    expect(find.text('TXN-10012026'), findsOneWidget);

    await tester.tap(find.text('Set Up Branch'));
    await tester.pumpAndSettle();
    expect(find.text('Branches page'), findsOneWidget);

    Navigator.of(tester.element(find.text('Branches page'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip to Dashboard for now'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard page'), findsOneWidget);
  });
}
