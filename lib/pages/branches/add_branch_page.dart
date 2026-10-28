import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_step.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

/// Add-branch flow reusing the branch setup form from onboarding.
class AddBranchPage extends StatefulWidget {
  const AddBranchPage({
    super.key,
    required this.authRepository,
    required this.branchRepository,
  });

  final AuthRepository authRepository;
  final BranchRepository branchRepository;

  @override
  State<AddBranchPage> createState() => _AddBranchPageState();
}

class _AddBranchPageState extends State<AddBranchPage> {
  final _formKey = GlobalKey<FormState>();
  final _branchNameController = TextEditingController();
  final _branchAddressController = TextEditingController();
  final _managerFirstNameController = TextEditingController();
  final _managerLastNameController = TextEditingController();

  BranchManagerOption? _managerOption;
  bool _isSaving = false;

  @override
  void dispose() {
    _branchNameController.dispose();
    _branchAddressController.dispose();
    _managerFirstNameController.dispose();
    _managerLastNameController.dispose();
    super.dispose();
  }

  Future<void> _saveBranch() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _managerOption == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final managerName = switch (_managerOption!) {
        BranchManagerOption.myself =>
          (await widget.authRepository.loadProfile()).fullName,
        BranchManagerOption.newManager =>
          '${_managerFirstNameController.text.trim()} '
              '${_managerLastNameController.text.trim()}',
      };
      final name = _branchNameController.text.trim();
      await widget.branchRepository.createBranch(
        BranchData(
          id: 'branch-${DateTime.now().microsecondsSinceEpoch}',
          name: name.toUpperCase(),
          address: _branchAddressController.text.trim(),
          managerName: managerName,
          dryerCount: 0,
          activeCycles: 0,
          isOpen: true,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add this branch. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: OnboardingBranchSetupStep(
        onBack: () => Navigator.of(context).pop(),
        formKey: _formKey,
        branchNameController: _branchNameController,
        branchAddressController: _branchAddressController,
        managerFirstNameController: _managerFirstNameController,
        managerLastNameController: _managerLastNameController,
        managerOption: _managerOption,
        isSaving: _isSaving,
        onManagerOptionChanged: (option) =>
            setState(() => _managerOption = option),
        onFieldChanged: () => setState(() {}),
        onSkip: () {},
        onFinish: _saveBranch,
        showSkip: false,
        heading: 'Create another branch',
      ),
    ),
  );
}
