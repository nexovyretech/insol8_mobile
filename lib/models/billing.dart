/// Billing data from `GET /billing/subscription` and `GET /billing/payments`.
library;

/// The plan an account is on, with its monthly price.
class BillingPlan {
  const BillingPlan({
    required this.id,
    required this.name,
    this.amountCentavos,
    this.currency = 'PHP',
  });

  factory BillingPlan.fromJson(Map<String, dynamic> json) => BillingPlan(
    id: json['id'] as String,
    name: json['name'] as String? ?? json['id'] as String,
    amountCentavos: (json['amount'] as num?)?.toInt(),
    currency: json['currency'] as String? ?? 'PHP',
  );

  final String id;

  /// The name the backend's price list gives it (for example
  /// "Organization tier").
  final String name;
  final int? amountCentavos;
  final String currency;

  /// "Organization" or "Basic": what the app calls each plan type.
  String get typeLabel => planTypeLabel(id);
}

/// What the app calls each plan type. Never abbreviated.
String planTypeLabel(String? planId) => switch (planId) {
  'organization' => 'Organization',
  'basic' => 'Basic',
  null => 'No plan yet',
  final other => other,
};

/// One paid payment, with everything its receipt shows.
class PaymentRecord {
  const PaymentRecord({
    required this.referenceNumber,
    required this.planId,
    required this.planName,
    required this.amountCentavos,
    required this.currency,
    required this.paymentMethod,
    required this.paymentMethodName,
    this.kind,
    this.paymentId,
    this.paidAt,
    this.periodStart,
    this.periodEnd,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    referenceNumber: json['referenceNumber'] as String,
    planId: json['planId'] as String,
    planName: json['planName'] as String? ?? json['planId'] as String,
    amountCentavos: (json['amount'] as num).toInt(),
    currency: json['currency'] as String? ?? 'PHP',
    paymentMethod: json['paymentMethod'] as String? ?? '',
    paymentMethodName:
        json['paymentMethodName'] as String? ??
        json['paymentMethod'] as String? ??
        '',
    kind: json['kind'] as String?,
    paymentId: json['paymentId'] as String?,
    paidAt: _date(json['paidAt']),
    periodStart: _date(json['periodStart']),
    periodEnd: _date(json['periodEnd']),
  );

  final String referenceNumber;
  final String planId;
  final String planName;
  final int amountCentavos;
  final String currency;

  /// PayMongo's method id: `gcash` or `paymaya`.
  final String paymentMethod;

  /// "GCash" or "Maya".
  final String paymentMethodName;

  /// new, renewal, or upgrade; null for payments made before this was kept.
  final String? kind;
  final String? paymentId;
  final DateTime? paidAt;

  /// The month this payment bought; null for payments made before billing
  /// periods were recorded on each payment.
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// A prorated charge for the rest of a period when moving to a bigger plan.
  bool get isUpgrade => kind == 'upgrade';

  /// The short title in lists: "Organization plan" or "Upgrade to
  /// Organization".
  String get title => isUpgrade
      ? 'Upgrade to ${planTypeLabel(planId)}'
      : '${planTypeLabel(planId)} plan';

  /// The line on the receipt.
  String get description => isUpgrade
      ? 'Upgrade to ${planTypeLabel(planId)} (prorated)'
      : '${planTypeLabel(planId)} plan, monthly subscription';

  /// A short receipt number for people: the last 8 characters of the
  /// checkout reference, uppercase. Not an official (BIR-registered) receipt
  /// number.
  String get receiptNumber {
    final id = referenceNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return 'RCPT-${id.substring(id.length > 8 ? id.length - 8 : 0).toUpperCase()}';
  }
}

/// A plan change waiting for the end of the paid period (a downgrade).
class ScheduledPlanChange {
  const ScheduledPlanChange({
    required this.planId,
    required this.effectiveAt,
    this.keepBranchId,
  });

  factory ScheduledPlanChange.fromJson(Map<String, dynamic> json) =>
      ScheduledPlanChange(
        planId: json['planId'] as String,
        effectiveAt: DateTime.parse(json['effectiveAt'] as String),
        keepBranchId: json['keepBranchId'] as String?,
      );

  final String planId;
  final DateTime effectiveAt;

  /// The branch that stays on the smaller plan.
  final String? keepBranchId;
}

/// What choosing a plan would mean right now, priced by the backend
/// (`GET /billing/quote`).
class PlanQuote {
  const PlanQuote({
    required this.kind,
    required this.planId,
    required this.amountCentavos,
    required this.fullAmountCentavos,
    required this.periodStart,
    required this.periodEnd,
  });

  factory PlanQuote.fromJson(Map<String, dynamic> json) => PlanQuote(
    kind: json['kind'] as String,
    planId: json['planId'] as String,
    amountCentavos: (json['amount'] as num).toInt(),
    fullAmountCentavos: (json['fullAmount'] as num? ?? json['amount'] as num)
        .toInt(),
    periodStart: DateTime.parse(json['periodStart'] as String),
    periodEnd: DateTime.parse(json['periodEnd'] as String),
  );

  /// new (full price, a month from now), renewal (full price, after the
  /// current period), upgrade (the prorated difference; the end date stays),
  /// or downgrade (nothing now; starts when the current period ends).
  final String kind;
  final String planId;
  final int amountCentavos;
  final int fullAmountCentavos;
  final DateTime periodStart;

  /// When the plan would next need paying.
  final DateTime periodEnd;

  bool get isUpgrade => kind == 'upgrade';
  bool get isDowngrade => kind == 'downgrade';
}

/// The account's subscription as Billing Information shows it.
class SubscriptionDetails {
  const SubscriptionDetails({
    required this.status,
    this.hasAccess = false,
    this.plan,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.graceEndsAt,
    this.scheduledChange,
    this.lastPayment,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) =>
      SubscriptionDetails(
        status: json['status'] as String? ?? 'none',
        hasAccess: json['hasAccess'] == true,
        cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
        graceEndsAt: _date(json['graceEndsAt']),
        scheduledChange: switch (json['scheduledChange']) {
          final Map<String, dynamic> change => ScheduledPlanChange.fromJson(
            change,
          ),
          _ => null,
        },
        plan: switch (json['plan']) {
          final Map<String, dynamic> plan => BillingPlan.fromJson(plan),
          _ => null,
        },
        currentPeriodStart: _date(json['currentPeriodStart']),
        currentPeriodEnd: _date(json['currentPeriodEnd']),
        lastPayment: switch (json['lastPayment']) {
          final Map<String, dynamic> payment => PaymentRecord.fromJson(payment),
          _ => null,
        },
      );

  /// none, selected, pending_payment, active, grace, or expired.
  final String status;

  /// True while active or in the 5-day grace period after the period ended.
  final bool hasAccess;
  final BillingPlan? plan;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;

  /// Cancelled: the plan ends on [currentPeriodEnd], with no grace period.
  final bool cancelAtPeriodEnd;

  /// The last day of access if the plan is not renewed (none once cancelled).
  final DateTime? graceEndsAt;
  final ScheduledPlanChange? scheduledChange;
  final PaymentRecord? lastPayment;

  bool get isActive => status == 'active';
  bool get isInGracePeriod => status == 'grace';
  bool get isExpired => status == 'expired';

  /// Never paid: the account is still onboarding.
  bool get isNew =>
      status == 'none' || status == 'selected' || status == 'pending_payment';

  String get statusLabel => switch (status) {
    'active' when cancelAtPeriodEnd => 'Cancelled',
    'active' => 'Active',
    'grace' => 'Renewal due',
    'expired' => 'Expired',
    'pending_payment' => 'Pending payment',
    'selected' => 'Not paid yet',
    _ => 'No plan yet',
  };
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// 49999 centavos → shown in the app as `₱499.99`.
String formatPeso(int centavos) {
  final whole = (centavos ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '₱$whole.${(centavos % 100).toString().padLeft(2, '0')}';
}
