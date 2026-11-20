import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/manager_account_data.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_step.dart';
import 'package:insol8_mobile/pages/onboarding/manager_account_step.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

/// Add-branch flow reusing the branch setup form from onboarding, including
/// the "Create manager account" step for an added manager.
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
  final _managerFormKey = GlobalKey<FormState>();
  final _managerEmailController = TextEditingController();
  final _managerMobileController = TextEditingController();

  BranchManagerOption? _managerOption;
  ManagerAccountData? _managerAccount;
  bool _managerIsEmail = true;
  bool _showManagerAccount = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _branchNameController.dispose();
    _branchAddressController.dispose();
    _managerFirstNameController.dispose();
    _managerLastNameController.dispose();
    _managerEmailController.dispose();
    _managerMobileController.dispose();
    super.dispose();
  }

  void _changeManagerOption(BranchManagerOption option) {
    setState(() {
      _managerOption = option;
      if (option != BranchManagerOption.newManager) _managerAccount = null;
    });
  }

  void _createManagerAccount() {
    if (!(_managerFormKey.currentState?.validate() ?? false)) return;
    final account = ManagerAccountData(
      firstName: _managerFirstNameController.text.trim(),
      lastName: _managerLastNameController.text.trim(),
      contactMethod: _managerIsEmail
          ? ManagerContactMethod.email
          : ManagerContactMethod.mobile,
      contact:
          (_managerIsEmail
                  ? _managerEmailController.text
                  : _managerMobileController.text)
              .trim(),
    );
    setState(() {
      _managerAccount = account;
      _managerOption = BranchManagerOption.newManager;
      _showManagerAccount = false;
    });
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
        BranchManagerOption.newManager => _managerAccount?.fullName ?? '',
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
          setup: BranchSetupData(
            name: name,
            address: _branchAddressController.text.trim(),
            managerOption: _managerOption!,
            managerFirstName: _managerAccount?.firstName,
            managerLastName: _managerAccount?.lastName,
            managerEmail: _managerAccount?.email,
            managerMobileNumber: _managerAccount?.mobileNumber,
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Exception catch (error) {
      if (!mounted) return;
      // Show the server's reason, e.g. the Basic plan's one-branch limit.
      final message = switch (error) {
        ApiException(:final message) => message,
        AuthFailure(:final message) => message,
        _ => 'Could not add this branch. Try again.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: _showManagerAccount
          ? OnboardingManagerAccountStep(
              onBack: () => setState(() => _showManagerAccount = false),
              formKey: _managerFormKey,
              firstNameController: _managerFirstNameController,
              lastNameController: _managerLastNameController,
              emailController: _managerEmailController,
              mobileController: _managerMobileController,
              isEmail: _managerIsEmail,
              onContactMethodChanged: (isEmail) => setState(() {
                _managerIsEmail = isEmail;
                _managerFormKey.currentState?.reset();
              }),
              onFieldChanged: () => setState(() {}),
              onCreateAccount: _createManagerAccount,
            )
          : OnboardingBranchSetupStep(
              onBack: () => Navigator.of(context).pop(),
              formKey: _formKey,
              branchNameController: _branchNameController,
              branchAddressController: _branchAddressController,
              managerOption: _managerOption,
              managerAccount: _managerAccount,
              isSaving: _isSaving,
              onManagerOptionChanged: _changeManagerOption,
              onFieldChanged: () => setState(() {}),
              onAddManager: () => setState(() => _showManagerAccount = true),
              onFinish: _saveBranch,
              heading: 'Create another branch',
            ),
    ),
  );
}
