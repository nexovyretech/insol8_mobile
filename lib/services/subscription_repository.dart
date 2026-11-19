import 'package:insol8_mobile/models/billing.dart';
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

  /// The plan, price, status, period, and payment method for Billing
  /// Information.
  Future<SubscriptionDetails> fetchSubscription();

  /// Paid payments, newest first, for the payment history and receipts.
  Future<List<PaymentRecord>> fetchPayments();

  /// What choosing [planId] would cost and when it would run.
  Future<PlanQuote> fetchQuote(String planId);

  /// Ends the plan on its end date; access continues until then.
  Future<SubscriptionDetails> cancelSubscription();

  /// Undoes a cancellation or a scheduled downgrade.
  Future<SubscriptionDetails> resumeSubscription();

  /// Switches to the smaller [planId] when the current period ends, keeping
  /// [keepBranchId] (the others are archived and their devices removed).
  Future<SubscriptionDetails> scheduleDowngrade({
    required String planId,
    String? keepBranchId,
  });
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

  @override
  Future<SubscriptionDetails> fetchSubscription() async =>
      SubscriptionDetails.fromJson(await _api.get('/billing/subscription'));

  @override
  Future<PlanQuote> fetchQuote(String planId) async => PlanQuote.fromJson(
    await _api.get('/billing/quote?planId=${Uri.encodeQueryComponent(planId)}'),
  );

  @override
  Future<SubscriptionDetails> cancelSubscription() async =>
      SubscriptionDetails.fromJson(
        await _api.post('/billing/subscription/cancel', const {}),
      );

  @override
  Future<SubscriptionDetails> resumeSubscription() async =>
      SubscriptionDetails.fromJson(
        await _api.post('/billing/subscription/resume', const {}),
      );

  @override
  Future<SubscriptionDetails> scheduleDowngrade({
    required String planId,
    String? keepBranchId,
  }) async => SubscriptionDetails.fromJson(
    await _api.post('/billing/subscription/downgrade', {
      'planId': planId,
      'keepBranchId': ?keepBranchId,
    }),
  );

  @override
  Future<List<PaymentRecord>> fetchPayments() async {
    final data = await _api.get('/billing/payments');
    return [
      for (final payment in data['payments'] as List<dynamic>? ?? const [])
        PaymentRecord.fromJson(payment as Map<String, dynamic>),
    ];
  }
}
