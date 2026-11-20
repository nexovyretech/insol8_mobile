import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

/// The Settings > Subscription & Usage screen from the Figma frames.
///
/// The two plans are intentionally different: Organization shows both Branch
/// Usage and Device Usage; Basic shows Device Usage only. The add-on prices,
/// slot counts, and progress fills are the exact display values from the
/// design — the backend has no add-on purchase or usage-quota endpoint yet.
class SubscriptionUsagePage extends StatefulWidget {
  const SubscriptionUsagePage({
    super.key,
    this.planId,
    this.subscriptionRepository,
  });

  /// The active plan id. Settings passes this so the frame opens immediately;
  /// the route can omit it and let [subscriptionRepository] resolve the plan.
  final String? planId;
  final SubscriptionRepository? subscriptionRepository;

  @override
  State<SubscriptionUsagePage> createState() => _SubscriptionUsagePageState();
}

class _SubscriptionUsagePageState extends State<SubscriptionUsagePage> {
  late String _planId;
  late bool _loading;

  @override
  void initState() {
    super.initState();
    _planId = widget.planId ?? SubscriptionPlanIds.basic;
    _loading = widget.planId == null && widget.subscriptionRepository != null;
    if (_loading) _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final planId = await widget.subscriptionRepository!.fetchActivePlanId();
      if (!mounted) return;
      setState(() {
        _planId = planId ?? SubscriptionPlanIds.basic;
        _loading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _isOrganization => _planId == SubscriptionPlanIds.organization;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ListView(
          padding: const EdgeInsets.only(top: 18, bottom: 24),
          children: [
            AppInnerPageHeader(
              title: 'Subscription & Usage',
              onBack: () => Navigator.of(context).pop(),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 160),
                child: Center(child: CircularProgressIndicator(color: _orange)),
              )
            else ...[
              SizedBox(height: _isOrganization ? 36 : 30),
              if (_isOrganization) ...[
                _sectionTitle('Branch Usage'),
                const SizedBox(height: 12),
                _UsageFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Text(
                              'Branches',
                              style: TextStyle(
                                fontFamily: 'Sora',
                                color: _ink,
                                fontSize: 13,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Spacer(),
                            Text(
                              '3 total',
                              style: TextStyle(
                                fontFamily: 'Sora',
                                color: _muted,
                                fontSize: 10,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '2 included - 1 additional',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            color: _orange,
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: _UsageBar(fill: 1),
                      ),
                      const SizedBox(height: 16),
                      const _DividerLine(),
                      const SizedBox(height: 14),
                      _AddOnRow(
                        label: 'Add Additional Branch',
                        price: '₱250.00/month',
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.additionalBranch,
                          arguments: {'kind': 'branch', 'planId': _planId},
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _sectionTitle('Device Usage'),
              const SizedBox(height: 12),
              _UsageFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DeviceUsageRow(
                      branch: 'Caloocan Branch',
                      count: '3/5',
                      slots: '2 slots left',
                      fill: 0.68,
                    ),
                    const SizedBox(height: 12),
                    const _DividerLine(),
                    const SizedBox(height: 12),
                    const _DeviceUsageRow(
                      branch: 'Manila Branch',
                      count: '5/5',
                      slots: 'Limit reached',
                      fill: 1,
                    ),
                    const SizedBox(height: 12),
                    const _DividerLine(),
                    const SizedBox(height: 12),
                    const _DeviceUsageRow(
                      branch: 'Quezon City Branch',
                      count: '1/5',
                      slots: '4 slots left',
                      fill: 0.2,
                    ),
                    const SizedBox(height: 12),
                    const _DividerLine(),
                    const SizedBox(height: 14),
                    _AddOnRow(
                      label: 'Add Additional Device',
                      price: _isOrganization ? '₱55.00/month' : '₱35.00/month',
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.additionalDevice,
                        arguments: {'kind': 'device', 'planId': _planId},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0),
    child: Text(
      title,
      style: GoogleFonts.sora(
        color: _section,
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Matches the shared Settings first-page card: white surface, soft shadow,
/// and the same 16px radius used by Billing Information and Account Profile.
class _UsageFrame extends StatelessWidget {
  const _UsageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A35170F),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    child: child,
  );
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 12, endIndent: 12);
}

class _DeviceUsageRow extends StatelessWidget {
  const _DeviceUsageRow({
    required this.branch,
    required this.count,
    required this.slots,
    required this.fill,
  });

  final String branch;
  final String count;
  final String slots;
  final double fill;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              branch,
              style: GoogleFonts.sora(
                color: _ink,
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              count,
              style: GoogleFonts.sora(
                color: _ink,
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _UsageBar(fill: fill),
        const SizedBox(height: 6),
        Text(
          slots,
          style: GoogleFonts.sora(
            color: _muted,
            fontSize: 10,
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _AddOnRow extends StatelessWidget {
  const _AddOnRow({
    required this.label,
    required this.price,
    required this.onTap,
  });

  final String label;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                  color: _ink,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: _muted, size: 18),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            price,
            style: GoogleFonts.sora(
              color: _orange,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      height: 9,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: _track)),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fill.clamp(0.0, 1.0),
              child: const ColoredBox(color: _orange),
            ),
          ),
        ],
      ),
    ),
  );
}

const Color _section = Color(0xFFEEB490);
const Color _orange = Color(0xFFD97247);
const Color _ink = Color(0xFF161310);
const Color _muted = Color(0xFF8C7F78);
const Color _track = Color(0xFFE0E0E0);
