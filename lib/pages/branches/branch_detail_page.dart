import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/pages/devices/bulk_cycle_control_sheet.dart';
import 'package:insol8_mobile/pages/devices/device_management_page.dart';
import 'package:insol8_mobile/pages/home/dashboard_bottom_navigation.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/onboarding_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

class BranchDetailPage extends StatelessWidget {
  const BranchDetailPage({
    super.key,
    required this.branch,
    required this.deviceRepository,
    required this.onboardingRepository,
  });

  final BranchData branch;
  final DeviceRepository deviceRepository;
  final OnboardingRepository onboardingRepository;

  Future<void> _addDeviceToBranch(BuildContext context) async {
    final devices = await openDeviceRegistrationFlow(
      context,
      repository: onboardingRepository,
      initialBranchName: branch.name,
    );
    if (!context.mounted || devices == null || devices.isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            devices.length == 1
                ? 'Device added to ${branch.name}.'
                : '${devices.length} devices added to ${branch.name}.',
          ),
        ),
      );
  }

  Future<void> _openBulkCycleControls(BuildContext context) async {
    try {
      final allDevices = await deviceRepository.fetchDevices();
      final branchDeviceIds = branch.deviceIds.toSet();
      final devices = allDevices
          .where((device) => branchDeviceIds.contains(device.id))
          .toList(growable: false);
      if (!context.mounted) return;
      final result = await showBulkCycleControlSheet(
        context: context,
        devices: devices,
        repository: deviceRepository,
      );
      if (!context.mounted || result == null) return;
      final message = [
        if (result.started > 0)
          '${result.started} job${result.started == 1 ? '' : 's'} started',
        if (result.stopped > 0)
          '${result.stopped} job${result.stopped == 1 ? '' : 's'} stopped',
        if (result.failed > 0) '${result.failed} failed',
      ].join(' · ');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load this branch’s devices.'),
          ),
        );
      }
    }
  }

  Future<void> _openDeviceManagement(
    BuildContext context,
    String deviceId,
  ) async {
    try {
      final devices = await deviceRepository.fetchDevices();
      final matches = devices.where((device) => device.id == deviceId);
      if (matches.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This device is not available.')),
          );
        }
        return;
      }
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => DeviceManagementPage(
            device: matches.first,
            deviceRepository: deviceRepository,
          ),
        ),
      );
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open device management.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.pageHorizontal,
              right: AppSpacing.pageHorizontal,
              top: AppSpacing.pageHeaderTop,
            ),
            child: AppInnerPageHeader(
              title: branch.name,
              onBack: () => Navigator.of(context).pop(),
              leadingTooltip: 'Back to branches',
              trailing: IconButton(
                tooltip: 'Manage branch',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BranchManagementPage(branch: branch),
                  ),
                ),
                padding: EdgeInsets.zero,
                icon: SvgPicture.asset(
                  'assets/icons/device_management_tune.svg',
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.contentGap,
                AppSpacing.pageHorizontal,
                12,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.dashboardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _StatusPill(isOpen: branch.isOpen),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Branch Manager',
                                style: _hintStyle(context),
                              ),
                              Text(branch.managerName),
                            ],
                          ),
                        ],
                      ),
                      const Divider(
                        height: 28,
                        color: AppColors.dashboardBorder,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _BranchMetric(
                              label: 'Chamber Temperature',
                              value: '68°C',
                              progress: .68,
                            ),
                          ),
                          Expanded(
                            child: _BranchMetric(
                              label: 'Thermal Load Reserved',
                              value: '84%',
                              progress: .84,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _BranchMetric(
                              label: 'Daily Solar Share',
                              value: '91%',
                              progress: .91,
                            ),
                          ),
                          Expanded(
                            child: _BranchMetric(
                              label: 'Active Dryers',
                              value:
                                  '${branch.dryerCount} / ${branch.dryerCount}',
                              progress: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const DashboardSectionTitle('Quick Buttons'),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        label: 'Add Device to Branch',
                        icon: Icons.add,
                        onTap: () => _addDeviceToBranch(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        label: 'View Branch Analytics',
                        icon: Icons.monitor_heart_outlined,
                        onTap: () =>
                            Navigator.of(context)
                                .pushNamed(AppRoutes.analytics),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const DashboardSectionTitle('Devices'),
                for (var i = 0; i < branch.deviceIds.length; i++)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          _openDeviceManagement(context, branch.deviceIds[i]),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.dashboardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'DRYER UNIT ${branch.deviceIds[i].split('-').last}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            Text(
                              '62°C  |  91%  |  18mins',
                              style: _hintStyle(context),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.circle,
                              color: AppColors.primary,
                              size: 9,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: DashboardBottomNavigation(
      selectedIndex: 1,
      organizationPlan: true,
      onSelect: (index) {
        if (index == 1) return;
        if (index == 0) {
          Navigator.of(context)
              .popUntil((route) => route.settings.name == AppRoutes.home);
        } else if (index == 2) {
          Navigator.of(context).pushNamed(AppRoutes.analytics);
        } else if (index == 3) {
          Navigator.of(context).pushNamed(AppRoutes.settings);
        }
      },
    ),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Manage drying jobs',
      onPressed: () => _openBulkCycleControls(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    ),
  );

  static TextStyle? _hintStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppColors.fieldHint, fontSize: 11);
}

class BranchManagementPage extends StatelessWidget {
  const BranchManagementPage({super.key, required this.branch});

  final BranchData branch;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.pageHorizontal,
              right: AppSpacing.pageHorizontal,
              top: AppSpacing.pageHeaderTop,
            ),
            child: AppInnerPageHeader(
              title: 'Branch Management',
              onBack: () => Navigator.of(context).pop(),
              leadingTooltip: 'Back to branch',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.contentGap,
                AppSpacing.pageHorizontal,
                16,
              ),
              children: [
                const DashboardSectionTitle('Branch Details'),
                _ManagementCard(
                  rows: [
                    _ManagementRow(
                      label: 'Branch Name',
                      value: '${branch.name} BRANCH',
                      editable: true,
                    ),
                    _ManagementRow(
                      label: 'Branch Location',
                      value: branch.address,
                      editable: true,
                    ),
                    _ManagementRow(
                      label: 'Branch Manager',
                      value: branch.managerName,
                      editable: true,
                    ),
                    const _ManagementRow(
                      label: 'Operating Hours',
                      value: '7:00 AM – 9:00 PM',
                      editable: true,
                    ),
                    _ManagementRow(
                      label: 'Status',
                      value: branch.isOpen ? 'Active' : 'Closed',
                    ),
                    _ManagementRow(
                      label: 'Registered Devices',
                      value: '${branch.dryerCount} Devices',
                      editable: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const DashboardSectionTitle('Danger Zone'),
                FilledButton(
                  onPressed: branch.isOpen
                      ? () => _confirmClose(context)
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Close Branch'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Disconnects this branch from your business. Active cycles will stop, and branch logs will be archived.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.fieldHint, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _confirmClose(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close branch?'),
        content: Text(
          'This will mark ${branch.name} as closed. You can reopen it later in branch settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Branch updates will sync when the backend is connected.',
                  ),
                ),
              );
            },
            child: const Text('Close Branch'),
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({required this.rows});

  final List<_ManagementRow> rows;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D35170F),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _ManagementInfoRow(row: rows[i]),
          if (i != rows.length - 1)
            const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ],
    ),
  );
}

class _ManagementRow {
  const _ManagementRow({
    required this.label,
    required this.value,
    this.editable = false,
  });

  final String label;
  final String value;
  final bool editable;
}

class _ManagementInfoRow extends StatelessWidget {
  const _ManagementInfoRow({required this.row});

  final _ManagementRow row;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        Expanded(
          child: Text(row.label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  row.value,
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.fieldHint, fontSize: 11),
                ),
              ),
              if (row.editable) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.sectionLabel,
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.dashboardIconBackground,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      isOpen ? '●  OPEN' : '●  CLOSED',
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
    ),
  );
}

class _BranchMetric extends StatelessWidget {
  const _BranchMetric({
    required this.label,
    required this.value,
    required this.progress,
  });

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.fieldHint, fontSize: 10),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 9,
                backgroundColor: AppColors.dashboardBorder,
                color: AppColors.primary,
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
          ],
        ),
      ),
    ),
  );
}
