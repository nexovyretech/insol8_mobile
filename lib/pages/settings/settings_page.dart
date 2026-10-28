import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/home/dashboard_bottom_navigation.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.authRepository,
    required this.branchRepository,
    required this.deviceRepository,
    required this.subscriptionRepository,
  });

  final AuthRepository authRepository;
  final BranchRepository branchRepository;
  final DeviceRepository deviceRepository;
  final SubscriptionRepository subscriptionRepository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  UserProfile? _profile;
  bool _organizationPlan = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.authRepository.loadProfile();
      final plan = await widget.subscriptionRepository.fetchActivePlanId();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _organizationPlan = plan == SubscriptionPlanIds.organization;
        _loading = false;
      });
    } on Exception {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _signOut() async {
    try {
      await widget.authRepository.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.getStarted, (_) => false);
      }
    } on Exception {
      _message('Could not sign out. Please try again.');
    }
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldSignOut == true) await _signOut();
  }

  void _onNavigationSelected(int index) {
    if (index == 3) return;
    if (index == 0) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRoutes.home);
    } else if (index == 1) {
      Navigator.of(
        context,
      ).pushNamed(_organizationPlan ? AppRoutes.branches : AppRoutes.devices);
    } else if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.analytics);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
        ),
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.pageHeaderTop,
            bottom: 24,
          ),
          children: [
            const AppPageHeader(title: 'Settings'),
            const SizedBox(height: AppSpacing.sectionGap),
            _SettingsCard(
              children: [
                InkWell(
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.accountProfile),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 22,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.dashboardIconBackground,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium_outlined,
                            color: AppColors.primary,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _loading
                                    ? 'Loading profile…'
                                    : _profile?.fullName ?? 'Account',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontSize: 16, height: 1.2),
                              ),
                              Text(
                                _profile?.email ?? _profile?.mobileNumber ?? '',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.fieldHint,
                                      fontSize: 12,
                                      height: 1.2,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: AppColors.sectionLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _MenuRow(
                  icon: Icons.lock_outline,
                  label: 'Password & Security',
                  onTap: () =>
                      Navigator.of(context)
                          .pushNamed(AppRoutes.passwordSecurity),
                ),
                _MenuRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Billing Information',
                  onTap: () =>
                      Navigator.of(context)
                          .pushNamed(AppRoutes.billingInformation),
                ),
                _MenuRow(
                  icon: Icons.tune,
                  label: 'Preferences',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.preferences),
                  last: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _MenuRow(
                  icon: Icons.help_outline,
                  label: 'FAQs',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.faqs),
                ),
                _MenuRow(
                  icon: Icons.support_agent_outlined,
                  label: 'Troubleshooting',
                  onTap: () =>
                      Navigator.of(context)
                          .pushNamed(AppRoutes.troubleshooting),
                ),
                _MenuRow(
                  icon: Icons.menu_book_outlined,
                  label: 'User Guide',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.userGuide),
                ),
                _MenuRow(
                  icon: Icons.flag_outlined,
                  label: 'Report Issue',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.reportIssue),
                ),
                _MenuRow(
                  icon: Icons.info_outline,
                  label: 'About Us',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.aboutUs),
                  last: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _confirmSignOut,
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: DashboardBottomNavigation(
      selectedIndex: 3,
      organizationPlan: _organizationPlan,
      onSelect: _onNavigationSelected,
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

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
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.last = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.dashboardIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 13, color: AppColors.sectionLabel),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 14, height: 1.2),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.sectionLabel,
                ),
              ],
            ),
          ),
        ),
      ),
      if (!last) const Divider(height: 1, indent: 40),
    ],
  );
}
