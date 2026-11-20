import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:insol8_mobile/constants/legal_documents.dart';
import 'package:insol8_mobile/models/legal_document.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/pages/legal/legal_document_page.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';

/// Muted label colour used above the feature comparison in the design.
const _comparisonLabelColor = Color(0xFF9E8D81);

/// Near-black used for the comparison column headers and feature titles.
const _comparisonInkColor = Color(0xFF1A1613);

/// Warm grey used for the feature descriptions and billing note.
const _comparisonBodyColor = Color(0xFF4A4541);

class OnboardingSubscriptionStep extends StatelessWidget {
  const OnboardingSubscriptionStep({
    super.key,
    required this.plans,
    required this.selectedPlan,
    required this.onPlanSelected,
    required this.onBack,
    required this.onContinue,
    this.currentPlanId,
  });

  final int selectedPlan;
  final List<SubscriptionPlan> plans;

  /// Change plan: the plan the account is on, marked "Current plan".
  final String? currentPlanId;
  final ValueChanged<int> onPlanSelected;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: false,
      topPadding: AppSpacing.pageHeaderTop,
      headerSlotHeight: 0,
      child: OnboardingStickyLayout(
        header: AppInnerPageHeader(
          title: '',
          onBack: onBack,
          leadingIcon: Icons.arrow_back_ios_new,
        ),
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
          const SizedBox(height: 16),
          const _FeatureComparison(),
          const SizedBox(height: 16),
          _PlanSelectionCard(
            plans: plans,
            selectedPlan: selectedPlan,
            currentPlanId: currentPlanId,
            onPlanSelected: onPlanSelected,
          ),
          const SizedBox(height: 12),
          Text(
            'Auto-renews unless canceled at least 24 hours before your billing cycle ends. Cancel anytime in Account Settings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _comparisonLabelColor,
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
      showBack: false,
      topPadding: AppSpacing.pageHeaderTop,
      headerSlotHeight: 0,
      child: Column(
        children: [
          AppInnerPageHeader(
            title: '',
            onBack: onBack,
            leadingIcon: Icons.arrow_back_ios_new,
          ),
          Expanded(
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
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Figma screen is a comparison: BASIC includes the first four features,
/// ORG includes all six. Both columns are shown at the same time.
class _FeatureComparison extends StatelessWidget {
  const _FeatureComparison();

  static const _columnWidth = 44.0;

  // title, description, included in Basic
  static const _features = [
    ('Multiple Device Registration', 'Register up to 5 drying devices', true),
    (
      'Device Monitoring',
      'Real-time status, temps, and battery tracking',
      true,
    ),
    ('Energy Analytics', 'Measure solar heat efficiency and power usage', true),
    (
      'Profit Analytics',
      'Track operating costs, runs, and revenue trends',
      true,
    ),
    ('Multi-Branch Management', 'Manage branches and assign devices', false),
    ('Manager Access', 'Assign managers and manage access', false),
  ];

  static const _check = Icon(
    Icons.check_circle,
    color: Color(0xFFD87040),
    size: 18,
  );

  static const _notIncluded = Icon(
    Icons.cancel,
    color: Color(0xFFE8B090),
    size: 18,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: onboardingCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choose the right plan for you',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _comparisonLabelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(
                width: _columnWidth,
                child: Center(
                  child: Text(
                    'BASIC',
                    style: TextStyle(
                      color: _comparisonInkColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: _columnWidth,
                child: Center(
                  child: Text(
                    'ORG',
                    style: TextStyle(
                      color: _comparisonInkColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _features.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _features[i].$1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _comparisonInkColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _features[i].$2,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _comparisonBodyColor,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: _columnWidth,
                  child: _features[i].$3 ? _check : _notIncluded,
                ),
                const SizedBox(width: _columnWidth, child: _check),
              ],
            ),
            if (i != _features.length - 1) const SizedBox(height: 12),
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
    this.currentPlanId,
  });

  final List<SubscriptionPlan> plans;
  final int selectedPlan;
  final ValueChanged<int> onPlanSelected;
  final String? currentPlanId;

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
                current: plans[index].id == currentPlanId,
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
    this.current = false,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  /// The plan the account is on now.
  final bool current;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFFEEB48E);
    final priceForeground = selected ? Colors.white : const Color(0xFFD87040);
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
              if (current) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppColors.dashboardIconBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Current plan',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                plan.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: foreground, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '₱ ${plan.advertisedPrice.toStringAsFixed(2)}',
                maxLines: 1,
                style: TextStyle(
                  color: priceForeground,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '/ month',
                style: TextStyle(
                  color: foreground.withValues(alpha: selected ? 0.9 : 0.7),
                  fontSize: 10,
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
