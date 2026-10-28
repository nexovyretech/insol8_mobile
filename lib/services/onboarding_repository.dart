import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/device_setup_data.dart';
import 'package:insol8_mobile/models/onboarding_status.dart';

/// Backend boundary for onboarding: plans, checkout, branch and device setup.
/// [ApiOnboardingRepository] calls the InSOL8 API. Failures surface as
/// `ApiException`.
abstract interface class OnboardingRepository {
  Future<List<SubscriptionPlan>> fetchSubscriptionPlans();

  /// Current progress, including whether the subscription has been paid.
  Future<OnboardingStatus> fetchOnboardingStatus();

  Future<CheckoutSession> createCheckoutSession({
    required String planId,
    required SubscriptionPaymentMethod paymentMethod,
  });

  /// Asks the backend to check checkout [reference] with the payment provider
  /// and record it if paid. True once the payment is recorded.
  Future<bool> confirmPayment(String reference);

  /// Creates the branch and returns its `branchId`.
  Future<String> createBranch(BranchSetupData data);

  /// Checks the device code exists and can be linked, without claiming it.
  Future<void> pairDevice(DevicePairingRequest request);

  Future<void> verifyDevice(DeviceVerificationRequest request);

  /// Links the device to the account with its nickname and branch.
  Future<void> configureDevice(DeviceSetupData data);
}
