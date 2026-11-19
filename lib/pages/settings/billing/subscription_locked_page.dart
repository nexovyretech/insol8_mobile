import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/billing.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/utils/display_format.dart';
import 'package:insol8_mobile/widgets/auth/primary_button.dart';

/// Where a signed-in account lands once its plan has ended (past the 5-day
/// grace period, or a cancelled plan past its end date). The dashboard stays
/// locked until a new payment; the data is kept. Renew opens the plan and
/// payment flow, and the page lets the user back in as soon as it's paid.
class SubscriptionLockedPage extends StatefulWidget {
  const SubscriptionLockedPage({
    super.key,
    required this.authRepository,
    required this.subscriptionRepository,
  });

  final AuthRepository authRepository;
  final SubscriptionRepository subscriptionRepository;

  @override
  State<SubscriptionLockedPage> createState() => _SubscriptionLockedPageState();
}

class _SubscriptionLockedPageState extends State<SubscriptionLockedPage> {
  SubscriptionDetails? _subscription;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  /// Back to the dashboard once the subscription has access again.
  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final subscription = await widget.subscriptionRepository
          .fetchSubscription();
      if (!mounted) return;
      if (subscription.hasAccess) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
        return;
      }
      setState(() => _subscription = subscription);
    } on Exception {
      // Stays on this page; Renew still works.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _renew() async {
    await Navigator.of(context)
        .pushNamed(AppRoutes.changePlan, arguments: _subscription?.plan?.id);
    if (mounted) await _check();
  }

  Future<void> _signOut() async {
    await widget.authRepository.signOut();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.getStarted, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _subscription;
    final plan = subscription?.plan;
    final ended = subscription?.currentPeriodEnd;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
          ),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.dashboardIconBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_clock_outlined,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Your plan has ended',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 10),
              Text(
                [
                  if (plan != null && ended != null)
                    'Your ${plan.typeLabel} plan ended on ${formatDate(ended)}.',
                  'Renew to unlock your dashboard, devices, and analytics. '
                      'Your branches, devices, and job history are all saved.',
                ].join(' '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.body,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Renew subscription',
                isLoading: _checking,
                onPressed: _renew,
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamed(AppRoutes.billingInformation),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Billing information'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              TextButton(
                onPressed: _signOut,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.fieldHint,
                ),
                child: const Text('Sign out'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
