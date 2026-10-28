import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/device_setup_data.dart';
import 'package:insol8_mobile/models/onboarding_status.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';

/// Test-only backend for widget tests that pass through onboarding. It never
/// contacts a payment provider: checkout returns no URL and the "payment" is
/// reported as paid at once.
class FakeOnboardingRepository implements OnboardingRepository {
  const FakeOnboardingRepository();

  static const _reference = 'FAKE-REFERENCE';

  // Starts unpaid; starting checkout "pays" at once.
  static bool _paid = false;

  static const _plans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'Basic tier',
      price: 250,
      description: 'For single laundry shops.',
      features: [
        'Multiple device registration',
        'Device monitoring',
        'Energy analytics',
        'Profit analytics',
      ],
    ),
    SubscriptionPlan(
      id: 'organization',
      name: 'Organization tier',
      price: 500,
      description: 'For multi-branch businesses.',
      features: [
        'Multiple device registration',
        'Multiple branch registration',
        'Device monitoring',
        'Energy analytics',
        'Profit analytics',
      ],
      maxBranches: null,
      canAssignManagers: true,
    ),
  ];

  @override
  Future<List<SubscriptionPlan>> fetchSubscriptionPlans() async => _plans;

  @override
  Future<OnboardingStatus> fetchOnboardingStatus() async => _paid
      ? OnboardingStatus(
          subscriptionStatus: 'active',
          activePlanId: 'basic',
          lastPaidReference: _reference,
          currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
        )
      : const OnboardingStatus();

  @override
  Future<CheckoutSession> createCheckoutSession({
    required String planId,
    required SubscriptionPaymentMethod paymentMethod,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _paid = true;
    return const CheckoutSession(reference: _reference);
  }

  @override
  Future<bool> confirmPayment(String reference) async => _paid;

  @override
  Future<String> createBranch(BranchSetupData data) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return 'fake-branch';
  }

  @override
  Future<void> pairDevice(DevicePairingRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<void> verifyDevice(DeviceVerificationRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<void> configureDevice(DeviceSetupData data) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }
}
