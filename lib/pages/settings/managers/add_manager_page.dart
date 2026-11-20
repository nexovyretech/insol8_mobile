import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_style.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_text_field.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';
import 'package:insol8_mobile/pages/settings/managers/branch_assignment_list.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/utils/profile_rules.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

/// Manager Management > Add Manager. The backend stores a manager by name on
/// each selected branch through `PUT /branches/{id}`; there is no separate
/// manager-account endpoint yet.
class AddManagerPage extends StatefulWidget {
  const AddManagerPage({super.key, required this.branchRepository});

  final BranchRepository branchRepository;

  @override
  State<AddManagerPage> createState() => _AddManagerPageState();
}

class _AddManagerPageState extends State<AddManagerPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _selectedBranchIds = <String>{};

  List<BranchData> _branches = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await widget.branchRepository.fetchBranches();
      if (!mounted) return;
      setState(() {
        _branches = branches;
        // The Figma frame shows the first branch already checked, so the form
        // is usable immediately instead of silently blocking Create Account.
        final defaultBranch = _defaultBranch(branches);
        if (defaultBranch != null) _selectedBranchIds.add(defaultBranch.id);
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(
        error.message.isEmpty
            ? 'Could not load branches. Please try again.'
            : error.message,
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Could not load branches. Please try again.');
    }
  }

  /// Prefer an unassigned branch so the default choice does not overwrite an
  /// existing manager; fall back to the first branch when all are assigned.
  BranchData? _defaultBranch(List<BranchData> branches) {
    for (final branch in branches) {
      if (!branch.hasNamedManager) return branch;
    }
    return branches.isEmpty ? null : branches.first;
  }

  Future<void> _create() async {
    if (_branches.isEmpty) {
      _message('Add a branch first before adding a manager.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranchIds.isEmpty) {
      _message('Select at least one branch for this manager.');
      return;
    }
    setState(() => _saving = true);
    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      await Future.wait([
        for (final id in _selectedBranchIds)
          widget.branchRepository.updateBranchManager(
            branchId: id,
            firstName: firstName,
            lastName: lastName,
          ),
      ]);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message(
        error.message.isEmpty
            ? 'Could not add manager. Please try again.'
            : error.message,
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      _message('Could not add manager. Please try again.');
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BranchSetupPalette.background,
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        8,
        AppSpacing.pageHorizontal,
        16,
      ),
      child: OnboardingGradientButton(
        label: 'Create Account',
        gradientColors: const [
          BranchSetupPalette.orange,
          BranchSetupPalette.orange,
        ],
        onPressed: _loading || _saving || _branches.isEmpty ? null : _create,
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
              title: 'Branch Setup',
              onBack: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 16),
            Text(
              'Create manager account',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontSize: 20, height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              'Create an account your branch manager can sign in with. They '
              'will set their own password from the invitation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BranchSetupPalette.body,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OnboardingSectionLabel(
                    'Manager Details',
                    color: BranchSetupPalette.sectionLabel,
                  ),
                  const SizedBox(height: 10),
                  BranchSetupTextField(
                    controller: _firstNameController,
                    hint: 'First name',
                    capitalization: TextCapitalization.words,
                    onChanged: () {},
                    validator: (value) =>
                        nameProblem(value ?? '', 'first name'),
                  ),
                  const SizedBox(height: 12),
                  BranchSetupTextField(
                    controller: _lastNameController,
                    hint: 'Last name',
                    capitalization: TextCapitalization.words,
                    onChanged: () {},
                    validator: (value) => nameProblem(value ?? '', 'last name'),
                  ),
                  const SizedBox(height: 12),
                  BranchSetupTextField(
                    controller: _emailController,
                    hint: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: () {},
                    validator: (value) => emailProblem(value ?? ''),
                  ),
                  const SizedBox(height: 24),
                  const OnboardingSectionLabel(
                    'Account Access',
                    color: BranchSetupPalette.sectionLabel,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The manager uses this account to access only the branches '
                    'you assign. Each branch can have one manager.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BranchSetupPalette.body,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_branches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Add a branch first before assigning a manager.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BranchSetupPalette.body,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: BranchSetupPalette.field,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFBE9DA)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: BranchAssignmentList(
                        branches: _branches,
                        selectedIds: _selectedBranchIds,
                        onChanged: (id) => setState(() {
                          if (_selectedBranchIds.contains(id)) {
                            _selectedBranchIds.remove(id);
                          } else {
                            _selectedBranchIds.add(id);
                          }
                        }),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const OnboardingSectionLabel(
                    'Account Credentials',
                    color: BranchSetupPalette.sectionLabel,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The manager will receive an invitation to set up their '
                    'password.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BranchSetupPalette.body,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'You can add more branches, change addresses, or reassign '
                    'store managers anytime in your Account Settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BranchSetupPalette.body,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
