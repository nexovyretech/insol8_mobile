import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';

class OnboardingPaymentStep extends StatelessWidget {
  const OnboardingPaymentStep({
    super.key,
    required this.plan,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.onBack,
    required this.onContinue,
  });

  final SubscriptionPlan plan;
  final SubscriptionPaymentMethod paymentMethod;
  final ValueChanged<SubscriptionPaymentMethod> onPaymentMethodChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: true,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'Complete your\nsubscription',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            "You're one step away from unlocking your inSOL8 subscription access.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 18),
          const OnboardingSectionLabel('Subscription Summary'),
          const SizedBox(height: 8),
          _SubscriptionSummary(plan: plan),
          const SizedBox(height: 14),
          const OnboardingSectionLabel('Payment Method'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: onboardingCardDecoration(),
            child: Column(
              children: [
                _PaymentMethodRow(
                  method: SubscriptionPaymentMethod.gcash,
                  selected: paymentMethod == SubscriptionPaymentMethod.gcash,
                  onTap: () =>
                      onPaymentMethodChanged(SubscriptionPaymentMethod.gcash),
                ),
                _PaymentMethodRow(
                  method: SubscriptionPaymentMethod.maya,
                  selected: paymentMethod == SubscriptionPaymentMethod.maya,
                  onTap: () =>
                      onPaymentMethodChanged(SubscriptionPaymentMethod.maya),
                ),
              ],
            ),
          ),
          const Spacer(),
          OnboardingGradientButton(
            label:
                'Pay ₱ ${plan.price.toStringAsFixed(2)} via ${paymentMethod.label}',
            onPressed: onContinue,
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OnboardingTrustNote(
                icon: Icons.shield_outlined,
                title: 'Secure payment',
                subtitle: 'Your data is encrypted',
              ),
              SizedBox(width: 18),
              OnboardingTrustNote(
                icon: Icons.lock_outline,
                title: 'Privacy first',
                subtitle: 'We respect your data',
              ),
            ],
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _SubscriptionSummary extends StatelessWidget {
  const _SubscriptionSummary({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: onboardingCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      plan.description,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '₱ ${plan.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '/ month',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 13),
            ),
          ),
          const Divider(height: 18, color: Color(0xFFFFD7C2)),
          Text(
            'Features included:',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 5),
          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 16, color: Color(0xFFFFD7C2)),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Next Billing Date:',
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
              Text(
                'November 01, 2026',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 15, color: Color(0xFFFFD7C2)),
          Center(
            child: Text(
              'Cancel anytime. No commitments.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.fieldHint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            SizedBox(
              width: 82,
              height: 30,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  method == SubscriptionPaymentMethod.gcash
                      ? 'assets/icons/gcash_logo.svg'
                      : 'assets/icons/maya_logo.svg',
                  width: method == SubscriptionPaymentMethod.gcash ? 78 : 50,
                  height: method == SubscriptionPaymentMethod.gcash ? 28 : 19,
                  fit: BoxFit.contain,
                  semanticsLabel: method.label,
                ),
              ),
            ),
            const SizedBox(width: 9),
            const Spacer(),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.primary,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPaymentLoadingStep extends StatelessWidget {
  const OnboardingPaymentLoadingStep({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OnboardingLoadingMark(),
            const SizedBox(height: 22),
            Text(
              "We're almost there",
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait while we securely connect you to the payment gateway to complete your transaction.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 13, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPaymentSuccessStep extends StatelessWidget {
  const OnboardingPaymentSuccessStep({
    super.key,
    required this.plan,
    required this.buttonLabel,
    required this.onContinue,
    required this.onSkip,
  });

  final SubscriptionPlan plan;
  final String buttonLabel;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: false,
      child: Column(
        children: [
          const Spacer(),
          Text(
            'Your payment has been successful!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 22),
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration_outlined,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'You paid ₱ ${plan.price.toStringAsFixed(2)} to',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            _subscriptionDisplayName(plan),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: OnboardingSectionLabel('Transaction Details'),
          ),
          const SizedBox(height: 8),
          _MockTransactionCard(plan: plan),
          const SizedBox(height: 8),
          Text(
            'Preview only — no real payment has been processed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.fieldHint, fontSize: 14),
          ),
          const Spacer(),
          OnboardingGradientButton(
            label: buttonLabel,
            onPressed: onContinue,
            gradientColors: const [AppColors.primary, Color(0xFFB94220)],
            borderRadius: 16,
            fontSize: 14,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            child: const Text(
              'Skip to Dashboard for now',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MockTransactionCard extends StatelessWidget {
  const _MockTransactionCard({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: onboardingCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              plan.id == 'monthly-org'
                  ? 'MONTHLY ORGANIZATION TIER'
                  : 'MONTHLY BASIC TIER',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 18, color: Color(0xFFFFD7C2)),
          const SizedBox(height: 10),
          const _SummaryRow(label: 'Transaction ID:', value: 'TXN-10012026'),
          const SizedBox(height: 8),
          const _SummaryRow(
            label: 'Next Billing Date:',
            value: 'October 01, 2026',
          ),
          const Divider(height: 18, color: Color(0xFFFFD7C2)),
          Text(
            'Your plan is now active. Official receipt sent to your email.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.body, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 12),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String _subscriptionDisplayName(SubscriptionPlan plan) =>
    plan.id == 'monthly-org'
    ? 'InSOL8 Monthly Organization Tier'
    : 'InSOL8 Monthly Basic Tier';
