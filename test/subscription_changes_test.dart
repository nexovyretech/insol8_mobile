import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/billing.dart';
import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/home/home_page.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_page.dart';
import 'package:insol8_mobile/pages/settings/billing/switch_to_basic_page.dart';
import 'package:insol8_mobile/pages/settings/settings_content_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/fake_repositories.dart';

const _organization = BillingPlan(
  id: 'organization',
  name: 'Organization tier',
  amountCentavos: 49999,
);

/// Records subscription changes and answers with [subscription] / [quote].
class _Subscriptions extends FakeSubscriptionRepository {
  _Subscriptions(this.subscription, {this.quote}) : super('organization');

  SubscriptionDetails subscription;
  PlanQuote? quote;
  final calls = <String>[];

  @override
  Future<String?> fetchActivePlanId() async =>
      subscription.hasAccess ? subscription.plan?.id : null;

  @override
  Future<SubscriptionDetails> fetchSubscription() async => subscription;

  @override
  Future<PlanQuote> fetchQuote(String planId) async {
    calls.add('quote:$planId');
    return quote!;
  }

  @override
  Future<SubscriptionDetails> cancelSubscription() async {
    calls.add('cancel');
    return subscription = SubscriptionDetails(
      status: 'active',
      hasAccess: true,
      plan: subscription.plan,
      currentPeriodEnd: subscription.currentPeriodEnd,
      cancelAtPeriodEnd: true,
    );
  }

  @override
  Future<SubscriptionDetails> resumeSubscription() async {
    calls.add('resume');
    return subscription = SubscriptionDetails(
      status: 'active',
      hasAccess: true,
      plan: subscription.plan,
      currentPeriodEnd: subscription.currentPeriodEnd,
    );
  }

  @override
  Future<SubscriptionDetails> scheduleDowngrade({
    required String planId,
    String? keepBranchId,
  }) async {
    calls.add('downgrade:$planId:$keepBranchId');
    return subscription;
  }
}

class _Branches extends UnusedBranchRepository {
  const _Branches(this.branches);

  final List<BranchData> branches;

  @override
  Future<List<BranchData>> fetchBranches() async => branches;
}

class _SignedIn extends UnconfiguredAuthRepository {
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

BranchData _branch(String id, String name, int devices) => BranchData(
  id: id,
  name: name,
  address: '$name Street',
  managerName: 'Juan',
  dryerCount: devices,
  activeCycles: 0,
  isOpen: true,
  deviceIds: [for (var i = 0; i < devices; i++) '$id-dryer-$i'],
);

/// Scrolls [text] fully into view (clear of the bottom navigation) and taps it.
Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Widget _billing(SubscriptionRepository repository) => MaterialApp(
  routes: {AppRoutes.changePlan: (_) => const Text('Change plan')},
  home: SettingsContentPage(
    type: SettingsContentType.billing,
    authRepository: _SignedIn(),
    subscriptionRepository: repository,
  ),
);

void main() {
  final end = DateTime(2026, 12, 1);

  testWidgets('cancelling keeps access to the end date and can be undone', (
    tester,
  ) async {
    final repository = _Subscriptions(
      SubscriptionDetails(
        status: 'active',
        hasAccess: true,
        plan: _organization,
        currentPeriodEnd: end,
      ),
    );
    await tester.pumpWidget(_billing(repository));
    await tester.pumpAndSettle();

    await _tapText(tester, 'Cancel subscription');
    expect(
      find.textContaining('dashboard stays locked', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel plan'));
    await tester.pumpAndSettle();
    expect(repository.calls, ['cancel']);

    // The page now says so, and offers Resume.
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Ends on'), findsOneWidget);
    await _tapText(tester, 'Resume subscription');
    expect(repository.calls, ['cancel', 'resume']);
    expect(find.text('Cancel subscription'), findsOneWidget);
  });

  testWidgets('a plan in its grace period asks to renew by the last day', (
    tester,
  ) async {
    await tester.pumpWidget(
      _billing(
        _Subscriptions(
          SubscriptionDetails(
            status: 'grace',
            hasAccess: true,
            plan: _organization,
            currentPeriodEnd: end,
            graceEndsAt: DateTime(2026, 12, 6),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your plan has ended'), findsOneWidget);
    expect(find.text('Renew now'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Renew by'), 200);
    expect(find.text('Renewal due'), findsOneWidget);
    expect(find.text('Dec 6, 2026'), findsOneWidget);
    // No cancel button once the paid period is over.
    expect(find.text('Cancel subscription'), findsNothing);
  });

  testWidgets('a scheduled switch to Basic shows and can be kept', (
    tester,
  ) async {
    final repository = _Subscriptions(
      SubscriptionDetails(
        status: 'active',
        hasAccess: true,
        plan: _organization,
        currentPeriodEnd: end,
        scheduledChange: ScheduledPlanChange(planId: 'basic', effectiveAt: end),
      ),
    );
    await tester.pumpWidget(_billing(repository));
    await tester.pumpAndSettle();
    expect(find.text('Switching to Basic'), findsOneWidget);
    await _tapText(tester, 'Keep Organization plan');
    expect(repository.calls, ['resume']);
  });

  group('home', () {
    Future<void> openHome(
      WidgetTester tester,
      SubscriptionDetails subscription,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.subscriptionLocked: (_) => const Text('Locked screen'),
            AppRoutes.onboarding: (_) => const Text('Onboarding screen'),
          },
          home: HomePage(
            authRepository: _SignedIn(),
            dashboardRepository: const FakeDashboardRepository(),
            deviceRepository: const UnusedDeviceRepository(),
            onboardingRepository: const FakeOnboardingRepository(),
            subscriptionRepository: _Subscriptions(subscription),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an ended plan goes to the locked screen', (tester) async {
      await openHome(
        tester,
        SubscriptionDetails(
          status: 'expired',
          plan: _organization,
          currentPeriodEnd: end,
        ),
      );
      expect(find.text('Locked screen'), findsOneWidget);
    });

    testWidgets('an account that never paid goes to onboarding', (
      tester,
    ) async {
      await openHome(tester, const SubscriptionDetails(status: 'none'));
      expect(find.text('Onboarding screen'), findsOneWidget);
    });

    testWidgets('the grace period keeps the dashboard with a reminder', (
      tester,
    ) async {
      await openHome(
        tester,
        SubscriptionDetails(
          status: 'grace',
          hasAccess: true,
          plan: _organization,
          currentPeriodEnd: end,
          graceEndsAt: DateTime(2026, 12, 6),
        ),
      );
      expect(find.textContaining('Renew by Dec 6, 2026'), findsOneWidget);
    });
  });

  group('change plan', () {
    Future<_Subscriptions> openChangePlan(
      WidgetTester tester, {
      required PlanQuote quote,
      required String chosenPlanId,
      List<BranchData> branches = const [],
    }) async {
      final repository = _Subscriptions(
        SubscriptionDetails(
          status: 'active',
          hasAccess: true,
          plan: _organization,
          currentPeriodEnd: end,
        ),
        quote: quote,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OnboardingPage(
                    repository: const FakeOnboardingRepository(),
                    pricingOnly: true,
                    initialPlanId: chosenPlanId,
                    subscriptionRepository: repository,
                    branchRepository: _Branches(branches),
                  ),
                ),
              ),
              child: const Text('Billing'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Subscription'));
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('an upgrade pays the prorated difference', (tester) async {
      final repository = await openChangePlan(
        tester,
        chosenPlanId: 'organization',
        quote: PlanQuote(
          kind: 'upgrade',
          planId: 'organization',
          amountCentavos: 12500,
          fullAmountCentavos: 50000,
          periodStart: DateTime(2026, 11, 16),
          periodEnd: end,
        ),
      );
      expect(repository.calls, ['quote:organization']);
      expect(find.text('₱ 125.00'), findsOneWidget);
      expect(find.text('prorated'), findsOneWidget);
      expect(find.textContaining('Pay ₱ 125.00'), findsOneWidget);
    });

    testWidgets('paying for the current plan again reads as an early renewal', (
      tester,
    ) async {
      await openChangePlan(
        tester,
        chosenPlanId: 'organization',
        quote: PlanQuote(
          kind: 'renewal',
          planId: 'organization',
          amountCentavos: 49999,
          fullAmountCentavos: 49999,
          periodStart: end,
          periodEnd: DateTime(2027, 1, 1),
        ),
      );
      expect(find.text('Renew your plan\nearly'), findsOneWidget);
      expect(find.textContaining('adds a month after'), findsOneWidget);
      expect(find.text('/ month'), findsOneWidget);
    });

    testWidgets('a downgrade keeps the chosen branch and is scheduled', (
      tester,
    ) async {
      final repository = await openChangePlan(
        tester,
        chosenPlanId: 'basic',
        branches: [_branch('main', 'Main', 2), _branch('north', 'North', 3)],
        quote: PlanQuote(
          kind: 'downgrade',
          planId: 'basic',
          amountCentavos: 0,
          fullAmountCentavos: 25000,
          periodStart: end,
          periodEnd: DateTime(2027, 1, 1),
        ),
      );
      expect(find.byType(SwitchToBasicPage), findsOneWidget);
      expect(find.text('Choose the branch to keep'), findsOneWidget);
      // Keep North: Main and its 2 devices go.
      await tester.tap(find.text('North'));
      await tester.pumpAndSettle();
      expect(find.textContaining('archived: Main'), findsOneWidget);
      expect(find.textContaining('2 devices are removed'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Switch to Basic on Dec 1, 2026'),
        200,
      );
      await tester.tap(find.text('Switch to Basic on Dec 1, 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Before you switch'), findsOneWidget);
      expect(find.textContaining('job history stays saved'), findsOneWidget);
      await tester.tap(find.text('Switch to Basic').last);
      await tester.pumpAndSettle();

      expect(repository.calls, ['quote:basic', 'downgrade:basic:north']);
      // Back where Change plan was opened.
      expect(find.text('Billing'), findsOneWidget);
    });
  });
}
