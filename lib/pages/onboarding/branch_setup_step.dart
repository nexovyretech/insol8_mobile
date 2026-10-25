import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';

class OnboardingBranchSetupStep extends StatelessWidget {
  const OnboardingBranchSetupStep({
    super.key,
    required this.onBack,
    required this.formKey,
    required this.branchNameController,
    required this.branchAddressController,
    required this.managerFirstNameController,
    required this.managerLastNameController,
    required this.managerOption,
    required this.isSaving,
    required this.onManagerOptionChanged,
    required this.onFieldChanged,
    required this.onSkip,
    required this.onFinish,
  });

  final VoidCallback onBack;
  final GlobalKey<FormState> formKey;
  final TextEditingController branchNameController;
  final TextEditingController branchAddressController;
  final TextEditingController managerFirstNameController;
  final TextEditingController managerLastNameController;
  final BranchManagerOption? managerOption;
  final bool isSaving;
  final ValueChanged<BranchManagerOption> onManagerOptionChanged;
  final VoidCallback onFieldChanged;
  final VoidCallback onSkip;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final canFinish =
        branchNameController.text.trim().isNotEmpty &&
        branchAddressController.text.trim().isNotEmpty &&
        managerOption != null &&
        (managerOption == BranchManagerOption.myself ||
            (managerFirstNameController.text.trim().isNotEmpty &&
                managerLastNameController.text.trim().isNotEmpty));

    return OnboardingScaffold(
      showBack: false,
      showGradient: false,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 42,
                child: IconButton(
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  color: AppColors.ink,
                  tooltip: 'Back',
                ),
              ),
              Expanded(
                child: Text(
                  'Branch Setup',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.ink,
                ),
                child: const Text('Skip'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Name your first branch',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 22, height: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Set your primary laundry shop location so you can assign managers and link your inSOL8 dryers.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12, color: AppColors.body),
                    ),
                    const SizedBox(height: 22),
                    const OnboardingSectionLabel('Branch Details'),
                    const SizedBox(height: 12),
                    _BranchTextField(
                      controller: branchNameController,
                      hint: 'Branch name',
                      onChanged: onFieldChanged,
                    ),
                    const SizedBox(height: 12),
                    _BranchTextField(
                      controller: branchAddressController,
                      hint: 'Store address',
                      capitalization: TextCapitalization.words,
                      onChanged: onFieldChanged,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A branch represents a physical shop location. It helps you group drying units, view store-level analytics, and assign on-site managers.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12, color: AppColors.fieldHint),
                    ),
                    const SizedBox(height: 20),
                    const OnboardingSectionLabel('Store Manager'),
                    const SizedBox(height: 12),
                    _ManagerOptionTile(
                      title: 'Assign myself as manager',
                      value: BranchManagerOption.myself,
                      selected: managerOption == BranchManagerOption.myself,
                      onTap: () =>
                          onManagerOptionChanged(BranchManagerOption.myself),
                    ),
                    const SizedBox(height: 10),
                    _ManagerOptionTile(
                      title: 'Add a new manager',
                      value: BranchManagerOption.newManager,
                      selected: managerOption == BranchManagerOption.newManager,
                      onTap: () => onManagerOptionChanged(
                        BranchManagerOption.newManager,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Managers can start cycles, monitor chamber temperatures, and report branch issues.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12, color: AppColors.fieldHint),
                    ),
                    if (managerOption == BranchManagerOption.newManager) ...[
                      const SizedBox(height: 14),
                      const OnboardingSectionLabel('Assign Manager'),
                      const SizedBox(height: 10),
                      _BranchTextField(
                        controller: managerFirstNameController,
                        hint: 'First name',
                        capitalization: TextCapitalization.words,
                        onChanged: onFieldChanged,
                      ),
                      const SizedBox(height: 12),
                      _BranchTextField(
                        controller: managerLastNameController,
                        hint: 'Last name',
                        capitalization: TextCapitalization.words,
                        onChanged: onFieldChanged,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OnboardingGradientButton(
            label: isSaving ? 'Saving…' : 'Finish Setup',
            onPressed: canFinish && !isSaving ? onFinish : null,
          ),
          const SizedBox(height: 8),
          Text(
            'You can add more branches, change addresses, or reassign store managers anytime in your Account Settings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 12, color: AppColors.fieldHint),
          ),
        ],
      ),
    );
  }
}

class _BranchTextField extends StatelessWidget {
  const _BranchTextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: capitalization,
      onChanged: (_) => onChanged(),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'This field is required.'
          : null,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
      ),
    );
  }
}

class _ManagerOptionTile extends StatelessWidget {
  const _ManagerOptionTile({
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final BranchManagerOption value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF5EF) : Colors.transparent,
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
                    color: selected ? AppColors.primary : AppColors.body,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
