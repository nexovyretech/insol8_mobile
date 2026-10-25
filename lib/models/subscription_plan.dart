class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.features,
  });

  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> features;
}

enum SubscriptionPaymentMethod {
  gcash('GCash'),
  maya('Maya');

  const SubscriptionPaymentMethod(this.label);

  final String label;
}

class CheckoutSession {
  const CheckoutSession({this.checkoutUrl, this.reference});

  /// Set by the real payment API when it creates a provider checkout session.
  final Uri? checkoutUrl;
  final String? reference;
}
