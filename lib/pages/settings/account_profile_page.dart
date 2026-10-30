import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/home/dashboard_bottom_navigation.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/utils/display_format.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({
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
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  UserProfile? _profile;
  String? _plan;
  int? _deviceCount;
  int? _branchCount;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await widget.authRepository.loadProfile();
      final results = await Future.wait<Object?>([
        widget.subscriptionRepository.fetchActivePlanId(),
        widget.deviceRepository.fetchDevices(),
        widget.branchRepository.fetchBranches(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _plan = results[0] as String? ?? SubscriptionPlanIds.basic;
        _deviceCount = (results[1] as List<DeviceData>).length;
        _branchCount = (results[2] as List<BranchData>).length;
        _loading = false;
      });
    } on Exception {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editUsername() async {
    final profile = _profile;
    if (profile == null) return;

    final username = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _ChangeUsernameDialog(initialUsername: profile.username),
    );

    if (username == null || username == profile.username || !mounted) return;

    try {
      if (!await widget.authRepository.isUsernameAvailable(username)) {
        _message('That username is already taken. Try another one.');
        return;
      }
    } on Exception {
      _message('Could not check username availability. Please try again.');
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmUsernameDialog(username: username),
    );
    if (confirmed != true || !mounted) return;

    await _save(() => widget.authRepository.updateProfile(username: username));
  }

  Future<void> _editProfileField({
    required String label,
    required String initialValue,
    required String hint,
    required Future<UserProfile> Function(String value) save,
  }) async {
    if (_profile == null) return;

    final value = await showDialog<String>(
      context: context,
      builder: (_) => _ChangeProfileFieldDialog(
        label: label,
        initialValue: initialValue,
        hint: hint,
      ),
    );
    if (value == null || value == initialValue || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmProfileChangeDialog(label: label, value: value),
    );
    if (confirmed != true || !mounted) return;

    await _save(() => save(value));
  }

  /// Email is a sign-in alias, so Cognito verifies the new address with a
  /// code before the profile is updated; the old address stays active until
  /// then.
  Future<void> _editEmail() async {
    final profile = _profile;
    if (profile == null) return;

    final value = await showDialog<String>(
      context: context,
      builder: (_) => _ChangeProfileFieldDialog(
        label: 'Email Address',
        initialValue: profile.email ?? '',
        hint: 'janedoe@email.com',
        validator: (value) =>
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)
            ? null
            : 'Enter a valid email address.',
      ),
    );
    final email = value?.toLowerCase();
    if (email == null || email == profile.email || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _ConfirmProfileChangeDialog(label: 'Email Address', value: email),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await widget.authRepository.requestEmailChange(email);
    } on AuthFailure catch (error) {
      _message(error.message);
      return;
    } on Exception {
      _message('Could not send a verification code. Please try again.');
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    // A mistyped code can be retried; any other failure ends the flow.
    while (true) {
      if (!mounted) return;
      final code = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _EmailCodeDialog(email: email),
      );
      if (code == null || !mounted) return;
      final result = await _save(
        () => widget.authRepository.confirmEmailChange(email: email, code: code),
      );
      if (result != _SaveResult.codeError) return;
    }
  }

  /// Saves behind a progress bar, then shows the stored profile.
  Future<_SaveResult> _save(Future<UserProfile> Function() action) async {
    setState(() => _saving = true);
    final UserProfile saved;
    try {
      saved = await action();
    } on AuthFailure catch (error) {
      _message(error.message);
      return error.isCodeError ? _SaveResult.codeError : _SaveResult.failed;
    } on Exception {
      _message('Could not save your changes. Please try again.');
      return _SaveResult.failed;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return _SaveResult.saved;
    setState(() => _profile = saved);

    await showDialog<void>(
      context: context,
      builder: (_) => const _UsernameSavedDialog(),
    );
    return _SaveResult.saved;
  }

  void _copyUserId() {
    final id = _profile?.id;
    if (id == null) return;
    Clipboard.setData(ClipboardData(text: id));
    _message('User ID copied.');
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _navigation(int index) {
    if (index == 3) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRoutes.settings);
    } else if (index == 0) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRoutes.home);
    } else if (index == 1) {
      final isOrg = _plan == SubscriptionPlanIds.organization;
      Navigator.of(context)
          .pushNamed(isOrg ? AppRoutes.branches : AppRoutes.devices);
    } else if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.analytics);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
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
                title: 'Account Profile',
                onBack: () => Navigator.pop(context),
                trailing: IconButton(
                  onPressed: () {},
                  tooltip: 'Help',
                  icon: const Icon(Icons.help_outline, size: 18),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sectionGap,
                          bottom: 24,
                        ),
                        children: [
                          const _SectionLabel('Personal Info'),
                          _InfoCard(
                            rows: [
                              _InfoRow(
                                'Username',
                                profile?.username ?? '—',
                                editable: true,
                                onTap: _saving ? null : _editUsername,
                              ),
                              _InfoRow(
                                'First name',
                                profile?.firstName ?? '—',
                                editable: true,
                                onTap: _saving
                                    ? null
                                    : () => _editProfileField(
                                        label: 'First Name',
                                        initialValue: profile?.firstName ?? '',
                                        hint: 'Jane',
                                        save: (value) => widget.authRepository
                                            .updateProfile(firstName: value),
                                      ),
                              ),
                              _InfoRow(
                                'Last name',
                                profile?.lastName ?? '—',
                                editable: true,
                                onTap: _saving
                                    ? null
                                    : () => _editProfileField(
                                        label: 'Last Name',
                                        initialValue: profile?.lastName ?? '',
                                        hint: 'Doe',
                                        save: (value) => widget.authRepository
                                            .updateProfile(lastName: value),
                                      ),
                              ),
                              _InfoRow(
                                'Email address',
                                profile?.email ?? '—',
                                editable: true,
                                onTap: _saving ? null : _editEmail,
                                last: true,
                              ),
                            ],
                          ),
                          if (_saving)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          const SizedBox(height: 14),
                          const _SectionLabel('System Info'),
                          _InfoCard(
                            rows: [
                              _InfoRow(
                                'User ID',
                                profile?.id ?? '—',
                                onTap: _copyUserId,
                              ),
                              _InfoRow(
                                'Member Since',
                                switch (profile?.createdAt) {
                                  final createdAt? => formatDate(createdAt),
                                  null => '—',
                                },
                                last: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _SectionLabel('Business Info'),
                          _InfoCard(
                            rows: [
                              _InfoRow(
                                'Plan Tier',
                                _loading ? '—' : _planLabel(_plan),
                                editable: true,
                                onTap: () => Navigator.of(context)
                                    .pushNamed(AppRoutes.billingInformation),
                              ),
                              _InfoRow(
                                'Registered Devices',
                                '${_deviceCount ?? '—'} Devices',
                              ),
                              _InfoRow(
                                'Registered Branches',
                                '${_branchCount ?? '—'} Branches',
                                last: true,
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavigation(
        selectedIndex: 3,
        organizationPlan: _plan == SubscriptionPlanIds.organization,
        onSelect: _navigation,
      ),
    );
  }

  String _planLabel(String? plan) => switch (plan) {
    SubscriptionPlanIds.organization => 'Org Tier',
    SubscriptionPlanIds.basic => 'Basic Tier',
    _ => '—',
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.sectionLabel,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<_InfoRow> rows;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
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
    child: Column(
      children: [
        for (final row in rows)
          InkWell(
            onTap: row.onTap,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 14, height: 1.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        row.value,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.fieldHint,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  if (row.editable)
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.sectionLabel,
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _InfoRow {
  const _InfoRow(
    this.label,
    this.value, {
    this.editable = false,
    this.last = false,
    this.onTap,
  });
  final String label;
  final String value;
  final bool editable;
  final bool last;
  final VoidCallback? onTap;
}

class _ChangeUsernameDialog extends StatefulWidget {
  const _ChangeUsernameDialog({required this.initialUsername});

  final String initialUsername;

  @override
  State<_ChangeUsernameDialog> createState() => _ChangeUsernameDialogState();
}

class _ChangeUsernameDialogState extends State<_ChangeUsernameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final username = _controller.text.trim();
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(username)) {
      setState(() => _error = 'Use letters, numbers, and underscores only.');
      return;
    }
    Navigator.of(context).pop(username);
  }

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    title: 'Change Username',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter a new unique username. Letters, numbers, and underscores only.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.3),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: InputDecoration(
            hintText: 'janedoe123456',
            errorText: _error,
            filled: true,
            fillColor: AppColors.dashboardCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    ),
    actions: [
      _DialogCancelButton(onPressed: () => Navigator.pop(context)),
      _DialogPrimaryButton(label: 'Save', onPressed: _save),
    ],
  );
}

class _ConfirmUsernameDialog extends StatelessWidget {
  const _ConfirmUsernameDialog({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    content: Text.rich(
      TextSpan(
        style: const TextStyle(color: AppColors.ink, fontSize: 16, height: 1.3),
        children: [
          const TextSpan(text: 'Are you sure you want to save\n'),
          TextSpan(
            text: '$username?',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    ),
    actions: [
      _DialogCancelButton(onPressed: () => Navigator.pop(context, false)),
      _DialogPrimaryButton(
        label: 'OK',
        onPressed: () => Navigator.pop(context, true),
      ),
    ],
  );
}

class _UsernameSavedDialog extends StatelessWidget {
  const _UsernameSavedDialog();

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    title: 'Changes Saved!',
    content: const Text(
      'Looking good! Your changes are now have been saved.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.3),
    ),
    actions: [
      _DialogPrimaryButton(
        label: 'OK',
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}

class _ChangeProfileFieldDialog extends StatefulWidget {
  const _ChangeProfileFieldDialog({
    required this.label,
    required this.initialValue,
    required this.hint,
    this.validator,
  });

  final String label;
  final String initialValue;
  final String hint;
  final String? Function(String value)? validator;

  @override
  State<_ChangeProfileFieldDialog> createState() =>
      _ChangeProfileFieldDialogState();
}

class _ChangeProfileFieldDialogState extends State<_ChangeProfileFieldDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = '${widget.label} is required.');
      return;
    }
    final validationMessage = widget.validator?.call(value);
    if (validationMessage != null) {
      setState(() => _error = validationMessage);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    title: 'Change ${widget.label}',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Enter your new ${widget.label.toLowerCase()}.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: widget.label == 'Email Address'
              ? TextInputType.emailAddress
              : TextInputType.name,
          textCapitalization: widget.label == 'Email Address'
              ? TextCapitalization.none
              : TextCapitalization.words,
          autocorrect: false,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: _error,
            filled: true,
            fillColor: AppColors.dashboardCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) => _save(),
        ),
      ],
    ),
    actions: [
      _DialogCancelButton(onPressed: () => Navigator.pop(context)),
      _DialogPrimaryButton(label: 'Save', onPressed: _save),
    ],
  );
}

enum _SaveResult { saved, codeError, failed }

class _EmailCodeDialog extends StatefulWidget {
  const _EmailCodeDialog({required this.email});

  final String email;

  @override
  State<_EmailCodeDialog> createState() => _EmailCodeDialogState();
}

class _EmailCodeDialogState extends State<_EmailCodeDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    final code = _controller.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    title: 'Verify Email',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Enter the 6-digit code we sent to ${widget.email}.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: InputDecoration(
            hintText: '123456',
            counterText: '',
            errorText: _error,
            filled: true,
            fillColor: AppColors.dashboardCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) => _verify(),
        ),
      ],
    ),
    actions: [
      _DialogCancelButton(onPressed: () => Navigator.pop(context)),
      _DialogPrimaryButton(label: 'Verify', onPressed: _verify),
    ],
  );
}

class _ConfirmProfileChangeDialog extends StatelessWidget {
  const _ConfirmProfileChangeDialog({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    content: Text.rich(
      TextSpan(
        style: const TextStyle(color: AppColors.ink, fontSize: 16, height: 1.3),
        children: [
          TextSpan(text: 'Are you sure you want to save your $label?\n'),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    ),
    actions: [
      _DialogCancelButton(onPressed: () => Navigator.pop(context, false)),
      _DialogPrimaryButton(
        label: 'OK',
        onPressed: () => Navigator.pop(context, true),
      ),
    ],
  );
}

class _ProfileDialog extends StatelessWidget {
  const _ProfileDialog({
    this.title,
    required this.content,
    required this.actions,
  });

  final String? title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.sectionLabel,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
          ],
          content,
          const SizedBox(height: 22),
          Row(
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(width: 10),
                Expanded(child: actions[index]),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

class _DialogCancelButton extends StatelessWidget {
  const _DialogCancelButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.fieldHint,
        backgroundColor: AppColors.dashboardCard,
        side: const BorderSide(color: AppColors.dashboardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      child: const Text('Cancel'),
    ),
  );
}

class _DialogPrimaryButton extends StatelessWidget {
  const _DialogPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    ),
  );
}
