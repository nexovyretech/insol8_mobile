import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/models/manager_data.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_style.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';
import 'package:insol8_mobile/pages/settings/managers/branch_assignment_list.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

/// Settings > Manager Management > Manager Access.
class ManagerAccessPage extends StatefulWidget {
  const ManagerAccessPage({
    super.key,
    required this.manager,
    required this.branchRepository,
  });

  final ManagerData? manager;
  final BranchRepository branchRepository;

  @override
  State<ManagerAccessPage> createState() => _ManagerAccessPageState();
}

class _ManagerAccessPageState extends State<ManagerAccessPage> {
  final Set<String> _selectedIds = <String>{};
  List<BranchData> _branches = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.manager?.branchIds ?? const <String>[]);
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await widget.branchRepository.fetchBranches();
      if (!mounted) return;
      setState(() {
        _branches = branches;
        _loading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load branches. Please try again.'),
        ),
      );
    }
  }

  Future<void> _save() async {
    final manager = widget.manager;
    if (manager == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updates = <Future<void>>[];
      for (final branch in _branches) {
        final shouldAssign = _selectedIds.contains(branch.id);
        final alreadyAssigned = manager.branchIds.contains(branch.id);
        if (shouldAssign == alreadyAssigned) continue;
        updates.add(
          widget.branchRepository.updateBranchManager(
            branchId: branch.id,
            firstName: shouldAssign ? manager.firstName : null,
            lastName: shouldAssign ? manager.lastName : null,
          ),
        );
      }
      await Future.wait(updates);
      if (mounted) Navigator.of(context).pop(true);
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save manager access.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = widget.manager;
    if (manager == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AppInnerPageHeader(
            title: 'Manager Access',
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          8,
          AppSpacing.pageHorizontal,
          16,
        ),
        child: OnboardingGradientButton(
          label: 'Save Changes',
          gradientColors: const [
            BranchSetupPalette.orange,
            BranchSetupPalette.orange,
          ],
          onPressed: _loading || _saving ? null : _save,
        ),
      ),
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
              AppInnerPageHeader(
                title: 'Manager Access',
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBE9DA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: BranchSetupPalette.orange,
                        size: 22,
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const OnboardingSectionLabel(
                'Account Status',
                color: BranchSetupPalette.sectionLabel,
              ),
              const SizedBox(height: 8),
              _SettingsCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Text(
                  manager.statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BranchSetupPalette.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const OnboardingSectionLabel(
                'Branch Assignments',
                color: BranchSetupPalette.sectionLabel,
              ),
              const SizedBox(height: 8),
              Text(
                'Assign this manager to one or more branches. Each branch can '
                'have only one assigned manager.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BranchSetupPalette.body,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _SettingsCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: BranchAssignmentList(
                    branches: _branches,
                    selectedIds: _selectedIds,
                    onChanged: (id) => setState(() {
                      if (_selectedIds.contains(id)) {
                        _selectedIds.remove(id);
                      } else {
                        _selectedIds.add(id);
                      }
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shared Settings first-page frame: white surface, 16px radius, and the
/// same soft shadow used by Billing Information and Account Profile.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
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
    child: child,
  );
}
