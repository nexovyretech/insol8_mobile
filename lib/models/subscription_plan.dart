class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.features,
    this.maxBranches = 1,
    this.canAssignManagers = false,
  });

  /// Reads a plan from `GET /billing/plans`; the API sends amounts in centavos.
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final entitlements =
        (json['entitlements'] as Map<String, dynamic>?) ?? const {};
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['amount'] as num) / 100,
      description: json['description'] as String? ?? '',
      features: [
        for (final feature in (json['features'] as List<dynamic>? ?? const []))
          feature as String,
      ],
      maxBranches: entitlements['maxBranches'] as int?,
      canAssignManagers: entitlements['assignManagers'] == true,
    );
  }

  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> features;

  /// Branches the plan allows; null means no limit.
  final int? maxBranches;

  /// Whether a branch can be run by a named manager instead of the owner.
  final bool canAssignManagers;
}

enum SubscriptionPaymentMethod {
  gcash('GCash', 'gcash'),
  maya('Maya', 'maya');

  const SubscriptionPaymentMethod(this.label, this.apiValue);

  final String label;

  /// Value sent to `POST /billing/checkout`.
  final String apiValue;
}

class CheckoutSession {
  const CheckoutSession({this.checkoutUrl, this.reference});

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    final url = Uri.tryParse(json['checkoutUrl'] as String? ?? '');
    return CheckoutSession(
      // Only a real https page counts; a missing or relative URL is no checkout.
      checkoutUrl: url != null && url.scheme == 'https' ? url : null,
      reference: json['referenceNumber'] as String?,
    );
  }

  /// Set by the real payment API when it creates a provider checkout session.
  final Uri? checkoutUrl;
  final String? reference;
}
