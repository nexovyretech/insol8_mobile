import 'package:insol8_mobile/models/onboarding_status.dart';
import 'package:insol8_mobile/services/api_client.dart';

/// Plan IDs from the backend's plan catalog (`GET /billing/plans`).
abstract final class SubscriptionPlanIds {
  static const basic = 'basic';
  static const organization = 'organization';
}

/// Reads the signed-in account's paid subscription plan.
abstract interface class SubscriptionRepository {
  /// The plan that was paid for and has not expired; null without one.
  Future<String?> fetchActivePlanId();
}

/// Reads the plan from `GET /onboarding`. The backend records it when the
/// payment is confirmed, so the app never stores a plan itself.
class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  @override
  Future<String?> fetchActivePlanId() async =>
      OnboardingStatus.fromJson(await _api.get('/onboarding')).activePlanId;
}
