import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/settings/billing/subscription_usage_page.dart';
import 'package:insol8_mobile/pages/settings/settings_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_theme.dart';

import 'support/fake_repositories.dart';

class _TestAuthRepository extends UnconfiguredAuthRepository {
  const _TestAuthRepository();

  @override
  Future<UserProfile> loadProfile() async => const UserProfile(
    username: 'jane.doe',
    firstName: 'Jane',
    lastName: 'Doe',
    role: AccountRole.owner,
  );
}

Future<void> _pumpUsagePage(
  WidgetTester tester, {
  required String planId,
  Map<String, WidgetBuilder> routes = const {},
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: SubscriptionUsagePage(planId: planId),
      routes: routes,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('organization frame shows Branch Usage and Device Usage', (
    tester,
  ) async {
    await _pumpUsagePage(tester, planId: SubscriptionPlanIds.organization);

    expect(find.text('Subscription & Usage'), findsOneWidget);
    expect(find.text('Branch Usage'), findsOneWidget);
    expect(find.text('Branches'), findsOneWidget);
    expect(find.text('3 total'), findsOneWidget);
    expect(find.text('2 included - 1 additional'), findsOneWidget);
    expect(find.text('Add Additional Branch'), findsOneWidget);
    expect(find.text('₱250.00/month'), findsOneWidget);

    expect(find.text('Device Usage'), findsOneWidget);
    expect(find.text('Caloocan Branch'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('2 slots left'), findsOneWidget);
    expect(find.text('Manila Branch'), findsOneWidget);
    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('Limit reached'), findsOneWidget);
    expect(find.text('Quezon City Branch'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('4 slots left'), findsOneWidget);
    expect(find.text('Add Additional Device'), findsOneWidget);
    expect(find.text('₱55.00/month'), findsOneWidget);

    expect(find.text('₱35.00/month'), findsNothing);

    // First-page frames now use the shared Settings card: white + soft shadow.
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final decoration = widget.decoration! as BoxDecoration;
        return decoration.color == AppColors.surface &&
            decoration.borderRadius == BorderRadius.circular(16) &&
            decoration.boxShadow?.isNotEmpty == true;
      }),
      findsNWidgets(2),
    );
    expect(find.byType(Divider), findsWidgets);
  });

  testWidgets('basic frame shows Device Usage only', (tester) async {
    await _pumpUsagePage(tester, planId: SubscriptionPlanIds.basic);

    expect(find.text('Subscription & Usage'), findsOneWidget);
    expect(find.text('Device Usage'), findsOneWidget);
    expect(find.text('Caloocan Branch'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('2 slots left'), findsOneWidget);
    expect(find.text('Manila Branch'), findsOneWidget);
    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('Limit reached'), findsOneWidget);
    expect(find.text('Quezon City Branch'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('4 slots left'), findsOneWidget);
    expect(find.text('Add Additional Device'), findsOneWidget);
    expect(find.text('₱35.00/month'), findsOneWidget);

    expect(find.text('Branch Usage'), findsNothing);
    expect(find.text('Branches'), findsNothing);
    expect(find.text('Add Additional Branch'), findsNothing);
    expect(find.text('₱250.00/month'), findsNothing);
    expect(find.text('₱55.00/month'), findsNothing);

    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final decoration = widget.decoration! as BoxDecoration;
        return decoration.color == AppColors.surface &&
            decoration.borderRadius == BorderRadius.circular(16) &&
            decoration.boxShadow?.isNotEmpty == true;
      }),
      findsOneWidget,
    );
    expect(find.byType(Divider), findsWidgets);
  });

  testWidgets('progress fills match the screenshot', (tester) async {
    await _pumpUsagePage(tester, planId: SubscriptionPlanIds.organization);

    final fills = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((widget) => widget.widthFactor)
        .toList();
    // Branch bar, then 3/5, 5/5, and 1/5 from the design.
    expect(fills, [1.0, 0.68, 1.0, 0.2]);
  });

  testWidgets('add-on rows are tappable', (tester) async {
    await _pumpUsagePage(
      tester,
      planId: SubscriptionPlanIds.organization,
      routes: {
        AppRoutes.additionalBranch: (context) => Text(
          'Additional branch: ${(ModalRoute.of(context)?.settings.arguments as Map)['kind']}',
        ),
        AppRoutes.additionalDevice: (context) => Text(
          'Additional device: ${(ModalRoute.of(context)?.settings.arguments as Map)['planId']}',
        ),
      },
    );

    await tester.tap(find.text('Add Additional Branch'));
    await tester.pumpAndSettle();
    expect(find.text('Additional branch: branch'), findsOneWidget);

    Navigator.of(tester.element(find.text('Additional branch: branch'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Additional Device'));
    await tester.pumpAndSettle();
    expect(
      find.text('Additional device: ${SubscriptionPlanIds.organization}'),
      findsOneWidget,
    );
  });

  testWidgets('Settings opens Subscription & Usage with the active plan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SettingsPage(
          authRepository: const _TestAuthRepository(),
          branchRepository: const UnusedBranchRepository(),
          deviceRepository: const UnusedDeviceRepository(),
          subscriptionRepository: const FakeSubscriptionRepository(
            SubscriptionPlanIds.organization,
          ),
        ),
        routes: {
          AppRoutes.subscriptionUsage: (context) => Text(
            ModalRoute.of(context)?.settings.arguments as String? ?? 'none',
          ),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subscription & Usage'));
    await tester.pumpAndSettle();

    expect(find.text(SubscriptionPlanIds.organization), findsOneWidget);
  });
}
