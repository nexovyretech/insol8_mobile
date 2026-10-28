import 'package:insol8_mobile/services/api_client.dart';

/// Reads and saves the signed-in account's active subscription plan.
abstract interface class SubscriptionRepository {
  Future<String> fetchPlanId(String accountId);

  Future<void> savePlanId({required String accountId, required String planId});
}

/// Mock entitlement store for UI development. The default demo account uses
/// Organization; choosing a plan during onboarding replaces that value.
class MockSubscriptionRepository implements SubscriptionRepository {
  const MockSubscriptionRepository({this.defaultPlanId = 'monthly-org'});

  final String defaultPlanId;
  static final Map<String, String> _plansByAccount = {};

  @override
  Future<String> fetchPlanId(String accountId) async =>
      _plansByAccount[accountId] ?? defaultPlanId;

  @override
  Future<void> savePlanId({
    required String accountId,
    required String planId,
  }) async {
    _plansByAccount[accountId] = planId;
  }
}

/// API adapter contract for the account subscription endpoints. The backend
/// should expose GET and POST /me/subscription with `planId` in the response.
class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  @override
  Future<String> fetchPlanId(String accountId) async {
    final result = await _api.get('/me/subscription');
    return result['planId'] as String? ?? 'monthly-basic';
  }

  @override
  Future<void> savePlanId({
    required String accountId,
    required String planId,
  }) async {
    await _api.post('/me/subscription', {'planId': planId});
  }
}
