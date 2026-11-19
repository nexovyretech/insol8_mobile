import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/billing.dart';
import 'package:insol8_mobile/pages/home/dashboard_bottom_navigation.dart';
import 'package:insol8_mobile/pages/settings/billing/receipt_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/utils/display_format.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';
import 'package:insol8_mobile/widgets/error_banner.dart';

/// Billing Information → See history: every paid payment, newest first.
/// Tapping one opens its receipt.
class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({
    super.key,
    required this.authRepository,
    required this.subscriptionRepository,
  });

  final AuthRepository authRepository;
  final SubscriptionRepository subscriptionRepository;

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<PaymentRecord>? _payments;
  bool _organizationPlan = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait<Object?>([
        widget.subscriptionRepository.fetchPayments(),
        widget.subscriptionRepository.fetchActivePlanId(),
      ]);
      if (!mounted) return;
      setState(() {
        _payments = results[0] as List<PaymentRecord>;
        _organizationPlan = results[1] == SubscriptionPlanIds.organization;
      });
    } on Exception {
      if (mounted) {
        setState(
          () =>
              _error = 'Couldn’t load your payment history. Pull to try again.',
        );
      }
    }
  }

  void _navigate(int index) {
    final navigator = Navigator.of(context);
    switch (index) {
      case 0:
        navigator.popUntil((route) => route.settings.name == AppRoutes.home);
      case 1:
        navigator.pushNamed(
          _organizationPlan ? AppRoutes.branches : AppRoutes.devices,
        );
      case 2:
        navigator.pushNamed(AppRoutes.analytics);
      case 3:
        navigator.popUntil(
          (route) => route.settings.name == AppRoutes.settings,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final payments = _payments;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.pageHeaderTop),
              AppInnerPageHeader(
                title: 'Payment History',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (_error case final error?)
                        ErrorBanner(error)
                      else if (payments == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (payments.isEmpty)
                        const _EmptyHistory()
                      else ...[
                        _TotalsCard(payments: payments),
                        const SizedBox(height: 18),
                        Text(
                          'Payments',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.sectionLabel,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        for (final payment in payments) ...[
                          _PaymentTile(
                            payment: payment,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ReceiptPage(
                                  payment: payment,
                                  authRepository: widget.authRepository,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavigation(
        selectedIndex: 3,
        organizationPlan: _organizationPlan,
        onSelect: _navigate,
      ),
    );
  }
}

/// The summary at the top: how many payments and how much in total.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.payments});

  final List<PaymentRecord> payments;

  @override
  Widget build(BuildContext context) {
    final total = payments.fold<int>(0, (sum, p) => sum + p.amountCentavos);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total paid',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  formatPeso(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${payments.length} ${payments.length == 1 ? 'payment' : 'payments'}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.onTap});

  final PaymentRecord payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paidAt = payment.paidAt;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dashboardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.dashboardIconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  payment.isUpgrade
                      ? Icons.trending_up_rounded
                      : payment.planId == SubscriptionPlanIds.organization
                      ? Icons.store_mall_directory_outlined
                      : Icons.storefront_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (paidAt != null) formatDate(paidAt),
                        payment.paymentMethodName,
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.fieldHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPeso(payment.amountCentavos),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const PaidChip(),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.sectionLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small green "Paid" pill.
class PaidChip extends StatelessWidget {
  const PaidChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.success.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 11, color: AppColors.success),
        SizedBox(width: 3),
        Text(
          'Paid',
          style: TextStyle(
            color: AppColors.success,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 56),
    child: Column(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: AppColors.dashboardIconBackground,
          child: Icon(
            Icons.receipt_long_outlined,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'No payments yet',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Your subscription payments and their receipts will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.fieldHint, fontSize: 13),
        ),
      ],
    ),
  );
}
