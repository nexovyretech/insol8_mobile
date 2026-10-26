import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:insol8_mobile/constants/legal_documents.dart';
import 'package:insol8_mobile/models/legal_document.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/pages/legal/legal_document_page.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';

class OnboardingSubscriptionStep extends StatelessWidget {
  const OnboardingSubscriptionStep({
    super.key,
    required this.plans,
    required this.selectedPlan,
    required this.onPlanSelected,
    required this.onBack,
    required this.onContinue,
  });

  final int selectedPlan;
  final List<SubscriptionPlan> plans;
  final ValueChanged<int> onPlanSelected;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: true,
      onBack: onBack,
      child: OnboardingStickyLayout(
        content: [
          const SizedBox(height: 16),
          Text(
            'Turning sunlight into\nsavings',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'Scale your shops with multi-branch management, smart solar-thermal drying, and real-time fleet analytics.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.body, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 22),
          const _FeaturesCard(),
          const SizedBox(height: 16),
          _PlanSelectionCard(
            plans: plans,
            selectedPlan: selectedPlan,
            onPlanSelected: onPlanSelected,
          ),
          const SizedBox(height: 12),
          Text(
            'Auto-renews unless canceled at least 24 hours before your billing cycle ends. Cancel anytime in Account Settings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.fieldHint,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
        actions: [
          OnboardingGradientButton(
            label: 'Get Subscription',
            onPressed: onContinue,
          ),
          const SizedBox(height: 12),
          const Center(child: _OnboardingLegalLinks()),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _OnboardingLegalLinks extends StatefulWidget {
  const _OnboardingLegalLinks();

  @override
  State<_OnboardingLegalLinks> createState() => _OnboardingLegalLinksState();
}

class _OnboardingLegalLinksState extends State<_OnboardingLegalLinks> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openDocument(LegalDocuments.terms);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openDocument(LegalDocuments.privacy);
  }

  void _openDocument(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentPage(document: document),
      ),
    );
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.primary, fontSize: 12);
    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
        children: [
          TextSpan(
            text: 'Terms of Service',
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' & '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class OnboardingSubscriptionPlanLoading extends StatelessWidget {
  const OnboardingSubscriptionPlanLoading({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: true,
      onBack: onBack,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator(color: AppColors.primary)
            else ...[
              Text(
                error ?? 'No subscription plans are available.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard();

  static const _features = [
    (
      'Multiple Device Registration',
      'Connect and pair all your drying units',
      Icons.hub_outlined,
    ),
    (
      'Device Monitoring',
      'Real-time status, temps, and battery tracking',
      Icons.monitor_heart_outlined,
    ),
    (
      'Energy Analytics',
      'Measure solar heat efficiency and power usage',
      Icons.bolt_outlined,
    ),
    (
      'Profit Analytics',
      'Track operating costs, runs, and revenue trends',
      Icons.trending_up,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: onboardingCardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < _features.length; i++) ...[
            Row(
              children: [
                Icon(_features[i].$3, size: 17, color: AppColors.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _features[i].$1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _features[i].$2,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 17,
                ),
              ],
            ),
            if (i != _features.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _PlanSelectionCard extends StatelessWidget {
  const _PlanSelectionCard({
    required this.plans,
    required this.selectedPlan,
    required this.onPlanSelected,
  });

  final List<SubscriptionPlan> plans;
  final int selectedPlan;
  final ValueChanged<int> onPlanSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 144,
      child: Row(
        children: [
          for (var index = 0; index < plans.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: _PlanOption(
                plan: plans[index],
                selected: selectedPlan == index,
                onTap: () => onPlanSelected(index),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.primary;
    return Material(
      color: selected ? AppColors.primaryDark : const Color(0xFFFFF7F2),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? AppColors.primaryDark : const Color(0xFFFFE6D8),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                plan.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: foreground, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '₱ ${plan.price.toStringAsFixed(2)}',
                maxLines: 1,
                style: TextStyle(
                  color: foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                plan.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground.withValues(alpha: selected ? 1 : 0.72),
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
