/// Progress reported by `GET /onboarding`. The subscription counts as paid
/// only when the backend says so; a payment redirect alone is not proof.
class OnboardingStatus {
  const OnboardingStatus({
    this.complete = false,
    this.missingSteps = const [],
    this.subscriptionStatus = 'none',
    this.selectedPlanId,
    this.activePlanId,
    this.currentPeriodEnd,
    this.lastPaidReference,
    this.primaryBranchId,
    this.deviceId,
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    final onboarding =
        (json['onboarding'] as Map<String, dynamic>?) ?? const {};
    final status = (json['status'] as Map<String, dynamic>?) ?? const {};
    final subscription =
        (status['subscription'] as Map<String, dynamic>?) ?? const {};
    return OnboardingStatus(
      complete: status['complete'] == true,
      missingSteps: [
        for (final step
            in (status['missingSteps'] as List<dynamic>? ?? const []))
          step as String,
      ],
      subscriptionStatus: subscription['status'] as String? ?? 'none',
      selectedPlanId: subscription['selectedPlanId'] as String?,
      activePlanId: subscription['activePlanId'] as String?,
      currentPeriodEnd: DateTime.tryParse(
        subscription['currentPeriodEnd'] as String? ?? '',
      ),
      lastPaidReference: subscription['lastPaidReference'] as String?,
      primaryBranchId: onboarding['primaryBranchId'] as String?,
      deviceId: onboarding['deviceId'] as String?,
    );
  }

  final bool complete;
  final List<String> missingSteps;

  /// none, selected, pending_payment, active or expired.
  final String subscriptionStatus;
  final String? selectedPlanId;
  final String? activePlanId;
  final DateTime? currentPeriodEnd;
  final String? lastPaidReference;
  final String? primaryBranchId;
  final String? deviceId;

  bool get isSubscriptionActive => subscriptionStatus == 'active';

  /// True once the payment for checkout [reference] has been confirmed.
  bool isPaid(String reference) =>
      isSubscriptionActive && lastPaidReference == reference;

  /// When the next payment would fall due if [planId] were paid at [now].
  /// Mirrors the backend webhook: paying again for the plan that is still
  /// active extends it from its current end; otherwise a month starts now.
  DateTime nextBillingDateFor(String planId, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final end = currentPeriodEnd?.toLocal();
    final extend = activePlanId == planId && end != null && end.isAfter(today);
    return addOneMonth(extend ? end : today);
  }
}

/// Same day next month, clamped to that month's last day (Jan 31 -> Feb 28),
/// matching the backend's `addOneMonth`.
DateTime addOneMonth(DateTime start) {
  final lastDay = DateTime(start.year, start.month + 2, 0).day;
  return DateTime(
    start.year,
    start.month + 1,
    start.day < lastDay ? start.day : lastDay,
  );
}
