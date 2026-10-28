import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/onboarding_status.dart';

void main() {
  final now = DateTime(2026, 10, 28, 9, 48);

  test('a first payment is due again one month from today', () {
    expect(
      const OnboardingStatus().nextBillingDateFor('basic', now: now),
      DateTime(2026, 11, 28),
    );
  });

  test('renewing the active plan extends from its current end', () {
    final status = OnboardingStatus(
      subscriptionStatus: 'active',
      activePlanId: 'basic',
      currentPeriodEnd: DateTime(2026, 11, 15),
    );
    expect(
      status.nextBillingDateFor('basic', now: now),
      DateTime(2026, 12, 15),
    );
    // A different plan starts its own month now, as the webhook does.
    expect(
      status.nextBillingDateFor('organization', now: now),
      DateTime(2026, 11, 28),
    );
  });

  test('an expired period starts a new month from today', () {
    final status = OnboardingStatus(
      activePlanId: 'basic',
      currentPeriodEnd: DateTime(2026, 9, 1),
    );
    expect(
      status.nextBillingDateFor('basic', now: now),
      DateTime(2026, 11, 28),
    );
  });

  test('month ends clamp to the shorter month', () {
    expect(addOneMonth(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
    expect(addOneMonth(DateTime(2028, 1, 31)), DateTime(2028, 2, 29));
    expect(addOneMonth(DateTime(2026, 12, 31)), DateTime(2027, 1, 31));
  });
}
