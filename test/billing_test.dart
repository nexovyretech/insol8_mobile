import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/billing.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/settings/billing/receipt_page.dart';
import 'package:insol8_mobile/pages/settings/billing/payment_history_page.dart';
import 'package:insol8_mobile/pages/settings/settings_content_page.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/receipt_pdf.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';

final _maya = PaymentRecord.fromJson({
  'referenceNumber': 'INSOL8-0f3a9c2e-1b7d-4e5f-9a10-ab12cd34ef56',
  'planId': 'organization',
  'planName': 'Organization tier',
  'amount': 50000,
  'currency': 'PHP',
  'paymentMethod': 'paymaya',
  'paymentMethodName': 'Maya',
  'paymentId': 'pay_123',
  'paidAt': '2026-11-01T02:00:00.000Z',
  'periodStart': '2026-11-01T02:00:00.000Z',
  'periodEnd': '2026-12-01T02:00:00.000Z',
});

final _gcash = PaymentRecord.fromJson({
  'referenceNumber': 'INSOL8-older',
  'planId': 'basic',
  'planName': 'Basic tier',
  'amount': 25000,
  'currency': 'PHP',
  'paymentMethod': 'gcash',
  'paymentMethodName': 'GCash',
  'paidAt': '2026-10-01T02:00:00.000Z',
});

class _Billing implements SubscriptionRepository {
  _Billing(this.subscription, [this.payments = const []]);

  SubscriptionDetails subscription;
  final List<PaymentRecord> payments;
  final calls = <String>[];
  PlanQuote? quote;

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

  @override
  Future<String?> fetchActivePlanId() async =>
      subscription.isActive ? subscription.plan?.id : null;

  @override
  Future<SubscriptionDetails> fetchSubscription() async => subscription;

  @override
  Future<List<PaymentRecord>> fetchPayments() async => payments;
}

class _Auth extends UnconfiguredAuthRepository {
  @override
  Future<UserProfile> loadProfile() async => const UserProfile(
    username: 'juan',
    firstName: 'Juan',
    lastName: 'Dela Cruz',
    email: 'juan@example.com',
  );
}

Future<void> _scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200);
  await tester.pumpAndSettle();
}

void main() {
  test('billing models read the API and format pesos and plan types', () {
    final details = SubscriptionDetails.fromJson({
      'status': 'active',
      'plan': {
        'id': 'organization',
        'name': 'Organization tier',
        'amount': 50000,
      },
      'currentPeriodStart': '2026-11-01T02:00:00.000Z',
      'currentPeriodEnd': '2026-12-01T02:00:00.000Z',
      'lastPayment': null,
    });
    expect(details.plan!.typeLabel, 'Organization');
    expect(details.statusLabel, 'Active');
    expect(formatPeso(49999), '₱499.99');
    expect(formatPeso(123456789), '₱1,234,567.89');
    expect(planTypeLabel('basic'), 'Basic');
    expect(planTypeLabel(null), 'No plan yet');
    // The last 8 letters and digits of the checkout reference.
    expect(_maya.receiptNumber, 'RCPT-CD34EF56');
  });

  testWidgets(
    'Billing Information shows the real plan, price, dates, and wallet',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsContentPage(
            type: SettingsContentType.billing,
            authRepository: _Auth(),
            subscriptionRepository: _Billing(
              SubscriptionDetails(
                status: 'active',
                plan: const BillingPlan(
                  id: 'organization',
                  name: 'Organization tier',
                  amountCentavos: 49999,
                ),
                currentPeriodStart: DateTime(2026, 11, 1),
                currentPeriodEnd: DateTime(2026, 12, 1),
                lastPayment: _maya,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plan type'), findsOneWidget);
      expect(find.text('Organization'), findsOneWidget);
      expect(find.text('₱499.99 / month'), findsOneWidget);
      expect(find.textContaining('Org Tier'), findsNothing);
      await _scrollTo(tester, 'Payment method');
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Dec 1, 2026'), findsOneWidget);
      expect(find.text('Nov 1, 2026'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
    },
  );

  testWidgets('an expired plan says when it expired', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsContentPage(
          type: SettingsContentType.billing,
          authRepository: _Auth(),
          subscriptionRepository: _Billing(
            SubscriptionDetails(
              status: 'expired',
              plan: const BillingPlan(
                id: 'basic',
                name: 'Basic tier',
                amountCentavos: 25000,
              ),
              currentPeriodEnd: DateTime(2026, 10, 1),
              lastPayment: _gcash,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Basic'), findsOneWidget);
    await _scrollTo(tester, 'Payment method');
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Expired on'), findsOneWidget);
    expect(find.text('GCash'), findsOneWidget);
  });

  testWidgets('payment history lists payments and opens a receipt', (
    tester,
  ) async {
    final billing = _Billing(const SubscriptionDetails(status: 'active'), [
      _maya,
      _gcash,
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentHistoryPage(
          authRepository: _Auth(),
          subscriptionRepository: billing,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('₱750.00'), findsOneWidget); // total paid
    expect(find.text('2 payments'), findsOneWidget);
    expect(find.text('Organization plan'), findsOneWidget);
    expect(find.text('Basic plan'), findsOneWidget);
    expect(find.text('Nov 1, 2026 · Maya'), findsOneWidget);

    await tester.tap(find.text('Organization plan'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptPage), findsOneWidget);
    expect(find.text(_maya.receiptNumber), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);
  });

  testWidgets('an account without payments sees a friendly empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentHistoryPage(
          authRepository: _Auth(),
          subscriptionRepository: _Billing(
            const SubscriptionDetails(status: 'none'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No payments yet'), findsOneWidget);
  });

  test('the receipt PDF builds without fonts or the logo', () async {
    final bytes = await buildReceiptPdf(
      payment: _maya,
      customer: const ReceiptCustomer(
        name: 'Juan Dela Cruz',
        email: 'juan@example.com',
      ),
      generatedAt: DateTime(2026, 11, 18, 9, 30),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('an upgrade is labelled as a prorated charge, not a month', () {
    final upgrade = PaymentRecord.fromJson({
      'referenceNumber': 'INSOL8-up',
      'planId': 'organization',
      'planName': 'Organization tier',
      'kind': 'upgrade',
      'amount': 12500,
      'paymentMethod': 'gcash',
      'paymentMethodName': 'GCash',
    });
    expect(upgrade.title, 'Upgrade to Organization');
    expect(upgrade.description, 'Upgrade to Organization (prorated)');
    expect(_maya.title, 'Organization plan');
    expect(_maya.description, 'Organization plan, monthly subscription');
  });
}
