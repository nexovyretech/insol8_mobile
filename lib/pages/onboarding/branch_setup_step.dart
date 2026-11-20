import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/manager_account_data.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_style.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_text_field.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

class OnboardingBranchSetupStep extends StatelessWidget {
  const OnboardingBranchSetupStep({
    super.key,
    required this.onBack,
    required this.formKey,
    required this.branchNameController,
    required this.branchAddressController,
    required this.managerOption,
    required this.isSaving,
    required this.onManagerOptionChanged,
    required this.onFieldChanged,
    required this.onAddManager,
    required this.onFinish,
    this.managerAccount,
    this.heading = 'Name your first branch',
    this.finishLabel = 'Finish Setup',
    this.canAssignManagers = true,
  });

  final VoidCallback onBack;
  final GlobalKey<FormState> formKey;
  final TextEditingController branchNameController;
  final TextEditingController branchAddressController;
  final BranchManagerOption? managerOption;
  final bool isSaving;
  final ValueChanged<BranchManagerOption> onManagerOptionChanged;
  final VoidCallback onFieldChanged;

  /// Opens the "Create manager account" screen.
  final VoidCallback onAddManager;

  /// Set once the manager's account details have been entered. Finish stays
  /// disabled until this exists when "Add a new manager" is selected.
  final ManagerAccountData? managerAccount;
  final VoidCallback onFinish;
  final String heading;
  final String finishLabel;

  /// False on plans where the owner must manage the branch (Basic).
  final bool canAssignManagers;

  @override
  Widget build(BuildContext context) {
    final canFinish =
        branchNameController.text.trim().isNotEmpty &&
        branchAddressController.text.trim().isNotEmpty &&
        managerOption != null &&
        (managerOption == BranchManagerOption.myself || managerAccount != null);

    return OnboardingScaffold(
      showBack: false,
      showGradient: false,
      topPadding: AppSpacing.pageHeaderTop,
      bottomPadding: AppSpacing.branchSetupBottom,
      // This step renders its own header in the content below. Don't reserve
      // the scaffold's separate back-button slot above it.
      headerSlotHeight: 0,
      // Header and Finish Setup stay pinned; everything between scrolls, so
      // the button stays visible above the keyboard.
      child: OnboardingStickyLayout(
        header: AppInnerPageHeader(
          title: 'Branch Setup',
          onBack: onBack,
          titleColor: BranchSetupPalette.ink,
          iconColor: BranchSetupPalette.ink,
        ),
        content: [
          const SizedBox(height: 8),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BranchSetupPalette.ink,
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Set up your primary laundry shop location so you can assign '
                  'managers and link your InSOL8 dryers.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: BranchSetupPalette.body, fontSize: 12),
                ),
                const SizedBox(height: 22),
                const OnboardingSectionLabel(
                  'Branch Details',
                  color: BranchSetupPalette.sectionLabel,
                ),
                const SizedBox(height: 12),
                BranchSetupTextField(
                  controller: branchNameController,
                  hint: 'Branch name',
                  onChanged: onFieldChanged,
                ),
                const SizedBox(height: 12),
                BranchSetupTextField(
                  controller: branchAddressController,
                  hint: 'Store address',
                  capitalization: TextCapitalization.words,
                  onChanged: onFieldChanged,
                ),
                const SizedBox(height: 12),
                Text(
                  'A branch represents a physical shop location. It helps you '
                  'group drying units, view store-level analytics, and assign '
                  'on-site managers.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: BranchSetupPalette.body, fontSize: 12),
                ),
                const SizedBox(height: 20),
                const OnboardingSectionLabel(
                  'Store Manager',
                  color: BranchSetupPalette.sectionLabel,
                ),
                const SizedBox(height: 12),
                _ManagerOptionTile(
                  title: 'Assign myself as manager',
                  selected: managerOption == BranchManagerOption.myself,
                  onTap: () =>
                      onManagerOptionChanged(BranchManagerOption.myself),
                ),
                const SizedBox(height: 10),
                _ManagerOptionTile(
                  title: 'Add a new manager',
                  selected: managerOption == BranchManagerOption.newManager,
                  onTap: canAssignManagers
                      ? () => onManagerOptionChanged(
                          BranchManagerOption.newManager,
                        )
                      : null,
                ),
                if (!canAssignManagers) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Assigning a separate manager is available on the '
                    'Organization plan.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BranchSetupPalette.body,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Managers can start cycles, monitor chamber temperatures, '
                  'and report branch issues.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: BranchSetupPalette.body, fontSize: 12),
                ),
                if (managerOption == BranchManagerOption.newManager) ...[
                  const SizedBox(height: 14),
                  const OnboardingSectionLabel(
                    'Assign Manager',
                    color: BranchSetupPalette.sectionLabel,
                  ),
                  const SizedBox(height: 10),
                  if (managerAccount == null)
                    _AddManagerButton(onTap: onAddManager)
                  else
                    _ManagerAccountCard(account: managerAccount!),
                ],
                const SizedBox(height: 16),
                Text(
                  'You can add more branches, change addresses, or reassign '
                  'store managers anytime in your Account Settings.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: BranchSetupPalette.body, fontSize: 12),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
        actions: [
          OnboardingGradientButton(
            label: isSaving ? 'Saving…' : finishLabel,
            onPressed: canFinish && !isSaving ? onFinish : null,
            gradientColors: const [
              BranchSetupPalette.orange,
              BranchSetupPalette.orange,
            ],
            disabledColor: BranchSetupPalette.disabled,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ManagerOptionTile extends StatelessWidget {
  const _ManagerOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;

  /// Null disables the option.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap != null ? 1 : 0.45,
      child: Material(
        color: selected
            ? BranchSetupPalette.field
            : BranchSetupPalette.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? BranchSetupPalette.orange
                          : BranchSetupPalette.ink,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: BranchSetupPalette.orange,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action under "Assign Manager". The screenshot uses a chevron
/// button here, not the radio options used under "Store Manager".
class _AddManagerButton extends StatelessWidget {
  const _AddManagerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BranchSetupPalette.field,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Add a new manager',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BranchSetupPalette.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: BranchSetupPalette.orange,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerAccountCard extends StatelessWidget {
  const _ManagerAccountCard({required this.account});

  final ManagerAccountData account;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: BranchSetupPalette.field,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          account.fullName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: BranchSetupPalette.orange,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          account.displayContact,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: BranchSetupPalette.body, fontSize: 12),
        ),
      ],
    ),
  );
}
