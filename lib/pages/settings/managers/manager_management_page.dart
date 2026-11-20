import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/manager_data.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_style.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

/// Settings > Manager Management: managers are grouped from the branches the
/// backend returns, because a manager is stored on each branch record.
class ManagerManagementPage extends StatefulWidget {
  const ManagerManagementPage({super.key, required this.branchRepository});

  final BranchRepository branchRepository;

  @override
  State<ManagerManagementPage> createState() => _ManagerManagementPageState();
}

class _ManagerManagementPageState extends State<ManagerManagementPage> {
  List<ManagerData> _managers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final branches = await widget.branchRepository.fetchBranches();
      if (!mounted) return;
      setState(() {
        _managers = ManagerData.fromBranches(branches);
        _loading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Could not load managers. Please try again.');
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _openManager(ManagerData manager) async {
    // Named routes are registered as Route<dynamic>; requesting Route<bool>
    // here makes Flutter throw a cast error and swallow the tap.
    final changed = await Navigator.of(context)
        .pushNamed(AppRoutes.managerAccess, arguments: manager);
    if (!mounted) return;
    if (changed == true) {
      _message('Manager access saved.');
      await _load();
    }
  }

  Future<void> _addManager() async {
    final added = await Navigator.of(context).pushNamed(AppRoutes.addManager);
    if (!mounted) return;
    await _load();
    if (added == true) _message('Manager added.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        8,
        AppSpacing.pageHorizontal,
        16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnboardingGradientButton(
            label: 'Add Manager',
            height: 48,
            gradientColors: const [
              BranchSetupPalette.orange,
              BranchSetupPalette.orange,
            ],
            onPressed: _addManager,
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your branch and their access permissions.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: BranchSetupPalette.body,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
        ),
        child: Column(
          children: [
            AppInnerPageHeader(
              title: 'Manager Management',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_managers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'No managers assigned yet.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: BranchSetupPalette.body,
                                fontSize: 13,
                              ),
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < _managers.length; i++) ...[
                      if (i > 0) ...[
                        const Divider(height: 1, indent: 12, endIndent: 12),
                        const SizedBox(height: 12),
                      ],
                      _ManagerCard(
                        manager: _managers[i],
                        onTap: () => _openManager(_managers[i]),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ManagerCard extends StatelessWidget {
  const _ManagerCard({required this.manager, required this.onTap});

  final ManagerData manager;
  final VoidCallback onTap;

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
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBE9DA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: BranchSetupPalette.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          manager.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontSize: 16, height: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          manager.email.isEmpty
                              ? 'No email on file'
                              : manager.email,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: BranchSetupPalette.body,
                                fontSize: 12,
                                height: 1.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit ${manager.name}',
                    onPressed: onTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: BranchSetupPalette.orange,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: manager.status == ManagerStatus.active
                          ? BranchSetupPalette.orange
                          : BranchSetupPalette.sectionLabel,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    manager.statusLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: manager.status == ManagerStatus.active
                          ? BranchSetupPalette.orange
                          : BranchSetupPalette.sectionLabel,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Assigned Branches',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BranchSetupPalette.sectionLabel,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              for (final branch in manager.branchNames) ...[
                Text(
                  branch,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BranchSetupPalette.ink,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
