import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/utils/display_format.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';
import 'package:insol8_mobile/widgets/auth/primary_button.dart';
import 'package:insol8_mobile/widgets/error_banner.dart';

/// Going from Organization to Basic (one branch): choose the branch that
/// stays. The other branches are archived (their job history is kept) and
/// their devices are removed from the account, so they can be registered
/// again in the branch that stays.
///
/// [onConfirm] carries out the change with the chosen branch (scheduling the
/// switch, or remembering the branch for a Basic payment) and returns an
/// error message, or null when it worked; the page then pops with the
/// branch ID.
class SwitchToBasicPage extends StatefulWidget {
  const SwitchToBasicPage({
    super.key,
    required this.branches,
    required this.onConfirm,
    this.primaryBranchId,
    this.effectiveAt,
    this.confirmLabel = 'Switch to Basic',
  });

  /// The account's active branches.
  final List<BranchData> branches;
  final String? primaryBranchId;

  /// When the switch happens (the end of the paid Organization period);
  /// null when it happens with the next payment.
  final DateTime? effectiveAt;
  final String confirmLabel;
  final Future<String?> Function(String? keepBranchId) onConfirm;

  @override
  State<SwitchToBasicPage> createState() => _SwitchToBasicPageState();
}

class _SwitchToBasicPageState extends State<SwitchToBasicPage> {
  late String? _keepId = _defaultBranchId();
  bool _saving = false;
  String? _error;

  String? _defaultBranchId() {
    final branches = widget.branches;
    if (branches.isEmpty) return null;
    final primary = widget.primaryBranchId;
    return branches.any((branch) => branch.id == primary)
        ? primary
        : branches.first.id;
  }

  List<BranchData> get _archived =>
      widget.branches.where((branch) => branch.id != _keepId).toList();

  BranchData? get _kept {
    for (final branch in widget.branches) {
      if (branch.id == _keepId) return branch;
    }
    return null;
  }

  int get _removedDevices =>
      _archived.fold(0, (sum, branch) => sum + branch.deviceIds.length);

  Future<void> _confirm() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => _WhatHappensDialog(
        kept: _kept,
        archived: _archived,
        removedDevices: _removedDevices,
        effectiveAt: widget.effectiveAt,
        confirmLabel: widget.confirmLabel,
      ),
    );
    if (proceed != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onConfirm(_keepId);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(_keepId ?? '');
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAt = widget.effectiveAt;
    final choose = widget.branches.length > 1;
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
                title: 'Switch to Basic',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      effectiveAt == null
                          ? 'Basic includes one branch. Choose the branch your '
                                'business keeps using.'
                          : 'Your Organization plan stays active until '
                                '${formatDate(effectiveAt)}. After that, your '
                                'account switches to Basic, which includes one '
                                'branch.',
                      style: const TextStyle(
                        color: AppColors.body,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    if (choose) ...[
                      const SizedBox(height: 20),
                      const _SectionLabel('Choose the branch to keep'),
                      const SizedBox(height: 8),
                      for (final branch in widget.branches) ...[
                        _BranchOption(
                          branch: branch,
                          primary: branch.id == widget.primaryBranchId,
                          selected: branch.id == _keepId,
                          onTap: _saving
                              ? null
                              : () => setState(() => _keepId = branch.id),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                    const SizedBox(height: 10),
                    _Consequences(
                      archived: _archived,
                      removedDevices: _removedDevices,
                    ),
                    if (_error case final error?) ...[
                      const SizedBox(height: 12),
                      ErrorBanner(error),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: effectiveAt == null
                    ? widget.confirmLabel
                    : '${widget.confirmLabel} on ${formatDate(effectiveAt)}',
                isLoading: _saving,
                onPressed: _confirm,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.sectionLabel,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _BranchOption extends StatelessWidget {
  const _BranchOption({
    required this.branch,
    required this.primary,
    required this.selected,
    required this.onTap,
  });

  final BranchData branch;
  final bool primary;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final devices = branch.deviceIds.length;
    return Material(
      color: selected ? AppColors.dashboardCard : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.dashboardBorder,
              width: selected ? 1.6 : 1,
            ),
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
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            branch.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (primary) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dashboardIconBackground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Primary',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${branch.address} · $devices '
                      '${devices == 1 ? 'device' : 'devices'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.fieldHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primary : AppColors.fieldHint,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the switch does, in a soft card under the choice.
class _Consequences extends StatelessWidget {
  const _Consequences({required this.archived, required this.removedDevices});

  final List<BranchData> archived;
  final int removedDevices;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.dashboardCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.dashboardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('What changes on Basic'),
        const SizedBox(height: 10),
        if (archived.isEmpty)
          const _Point(
            icon: Icons.check_circle_outline_rounded,
            text: 'Your branch and its devices stay as they are.',
          )
        else ...[
          _Point(
            icon: Icons.inventory_2_outlined,
            text:
                '${archived.length} ${archived.length == 1 ? 'branch is' : 'branches are'} '
                'archived: ${archived.map((b) => b.name).join(', ')}.',
          ),
          _Point(
            icon: Icons.link_off_rounded,
            text: removedDevices == 0
                ? 'They have no devices to remove.'
                : '$removedDevices '
                      '${removedDevices == 1 ? 'device is' : 'devices are'} '
                      'removed from your account. You can register them '
                      'again in the branch you keep.',
          ),
          const _Point(
            icon: Icons.history_rounded,
            text:
                'Job history and reports from archived branches stay '
                'saved, and come back if you return to Organization.',
          ),
        ],
        const _Point(
          icon: Icons.manage_accounts_outlined,
          text: 'Branch managers lose access; Basic is run by the owner.',
        ),
      ],
    ),
  );
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.body,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The info dialog before switching: what happens to branches, devices, and
/// history. A confirmation, so no icon badge (the dialog rule).
class _WhatHappensDialog extends StatelessWidget {
  const _WhatHappensDialog({
    required this.kept,
    required this.archived,
    required this.removedDevices,
    required this.effectiveAt,
    required this.confirmLabel,
  });

  final BranchData? kept;
  final List<BranchData> archived;
  final int removedDevices;
  final DateTime? effectiveAt;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final when = effectiveAt == null
        ? 'When your Basic plan starts'
        : 'On ${formatDate(effectiveAt!)}';
    return Dialog(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Before you switch',
              style: TextStyle(
                color: AppColors.sectionLabel,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              archived.isEmpty
                  ? '$when, your account moves to Basic. '
                        'Your branch and devices stay as they are.'
                  : '$when, ${kept?.name ?? 'your chosen branch'} stays on '
                        'Basic and ${archived.length} '
                        '${archived.length == 1 ? 'branch is' : 'branches are'} '
                        'archived. '
                        '${removedDevices == 0 ? '' : '$removedDevices ${removedDevices == 1 ? 'device' : 'devices'} '
                                  'in ${archived.length == 1 ? 'it' : 'them'} '
                                  '${removedDevices == 1 ? 'is' : 'are'} removed from your account. '}'
                        'Their job history stays saved.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.fieldHint,
                        backgroundColor: AppColors.dashboardCard,
                        side: const BorderSide(
                          color: AppColors.dashboardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
