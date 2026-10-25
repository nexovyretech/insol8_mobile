import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/device_setup_data.dart';

/// Backend boundary for onboarding plans and subscription checkout.
/// Replace [MockOnboardingRepository] with an API implementation when the
/// team's endpoints and payment gateway credentials are available.
abstract interface class OnboardingRepository {
  Future<List<SubscriptionPlan>> fetchSubscriptionPlans();

  Future<CheckoutSession> createCheckoutSession({
    required String planId,
    required SubscriptionPaymentMethod paymentMethod,
  });

  Future<void> createBranch(BranchSetupData data);

  Future<void> pairDevice(DevicePairingRequest request);

  Future<void> verifyDevice(DeviceVerificationRequest request);

  Future<void> configureDevice(DeviceSetupData data);
}

/// Local fixture data for UI development. It never initiates or confirms a
/// payment; the returned session has no checkout URL until a backend is wired.
class MockOnboardingRepository implements OnboardingRepository {
  const MockOnboardingRepository();

  static const _plans = [
    SubscriptionPlan(
      id: 'monthly-basic',
      name: 'MONTHLY BASIC',
      price: 200,
      description: 'For single laundry shops.',
      features: [
        'Multiple device registration',
        'Device monitoring',
        'Energy analytics',
        'Profit analytics',
      ],
    ),
    SubscriptionPlan(
      id: 'monthly-org',
      name: 'MONTHLY ORG',
      price: 500,
      description: 'For multi-branch businesses.',
      features: [
        'Multiple device registration',
        'Multiple branch registration',
        'Device monitoring',
        'Energy analytics',
        'Profit analytics',
      ],
    ),
  ];

  @override
  Future<List<SubscriptionPlan>> fetchSubscriptionPlans() async => _plans;

  @override
  Future<CheckoutSession> createCheckoutSession({
    required String planId,
    required SubscriptionPaymentMethod paymentMethod,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const CheckoutSession();
  }

  @override
  Future<void> createBranch(BranchSetupData data) async {
    // Branch data remains local until a branch API is connected.
    await Future<void>.delayed(const Duration(milliseconds: 350));
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
