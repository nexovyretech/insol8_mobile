import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/device_setup_data.dart';
import 'package:insol8_mobile/models/onboarding_status.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';

/// Onboarding backed by the InSOL8 API. Every call carries the signed-in
/// user's Cognito token; the backend takes ownership from it, never from the
/// request body.
class ApiOnboardingRepository implements OnboardingRepository {
  ApiOnboardingRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  @override
  Future<List<SubscriptionPlan>> fetchSubscriptionPlans() async {
    final data = await _api.get('/billing/plans');
    return [
      for (final plan in (data['plans'] as List<dynamic>? ?? const []))
        SubscriptionPlan.fromJson(plan as Map<String, dynamic>),
    ];
  }

  @override
  Future<OnboardingStatus> fetchOnboardingStatus() async =>
      OnboardingStatus.fromJson(await _api.get('/onboarding'));

  @override
  Future<CheckoutSession> createCheckoutSession({
    required String planId,
    required SubscriptionPaymentMethod paymentMethod,
  }) async {
    final session = CheckoutSession.fromJson(
      await _api.post('/billing/checkout', {
        'subscriptionPlanId': planId,
        'paymentMethod': paymentMethod.apiValue,
      }),
    );
    if (session.checkoutUrl == null || session.reference == null) {
      throw const ApiException(
        502,
        'BAD_RESPONSE',
        'The payment page could not be opened.',
      );
    }
    return session;
  }

  @override
  Future<bool> confirmPayment(String reference) async {
    final result = await _api.post(
      '/billing/checkout/${Uri.encodeComponent(reference)}/confirm',
      const {},
    );
    return result['paymentStatus'] == 'paid';
  }

  @override
  Future<String> createBranch(BranchSetupData data) async {
    final branch = await _api.post('/branches', data.toJson());
    return branch['branchId'] as String;
  }

  @override
  Future<void> pairDevice(DevicePairingRequest request) =>
      _verify(request.deviceCode);

  @override
  Future<void> verifyDevice(DeviceVerificationRequest request) =>
      _verify(request.deviceCode);

  // 404 (unknown code) and 409 (linked to another account) arrive as
  // ApiException; an available code or one already on this account passes.
  Future<void> _verify(String deviceCode) async {
    await _api.post('/devices/verify', {'deviceCode': deviceCode});
  }

  @override
  Future<void> configureDevice(DeviceSetupData data) async {
    await _api.post('/devices', {
      'deviceCode': data.deviceCode,
      'deviceName': data.deviceName,
      if (data.branchId != null) 'branchId': data.branchId,
    });
  }
}
