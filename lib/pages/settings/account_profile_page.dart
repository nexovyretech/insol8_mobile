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
import 'package:insol8_mobile/utils/phone_number.dart';
import 'package:insol8_mobile/utils/profile_rules.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';
import 'package:insol8_mobile/widgets/auth/phone_number_field.dart';
import 'package:insol8_mobile/widgets/dialog_icon_badge.dart';
import 'package:insol8_mobile/widgets/error_banner.dart';
import 'package:insol8_mobile/widgets/resend_code_link.dart';
import 'package:insol8_mobile/widgets/six_digit_code_field.dart';

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

  /// False until the plan request succeeds ("—" rather than "No plan yet").
  bool _planLoaded = false;
  int? _deviceCount;
  int? _branchCount;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Each value loads on its own, so one failed request (say, devices) only
  /// leaves its own row showing "—" instead of blanking the whole page.
  Future<void> _load() async {
    Future<T?> attempt<T>(Future<T> Function() load) async {
      try {
        return await load();
      } on Exception {
        return null;
      }
    }

    final results = await Future.wait<Object?>([
      attempt(widget.authRepository.loadProfile),
      // Wrapped so "no plan" (null) differs from a failed request.
      attempt(
        () async => (await widget.subscriptionRepository.fetchActivePlanId(),),
      ),
      attempt(widget.deviceRepository.fetchDevices),
      attempt(widget.branchRepository.fetchBranches),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as UserProfile?;
      final plan = results[1] as (String?,)?;
      _planLoaded = plan != null;
      _plan = plan?.$1;
      _deviceCount = (results[2] as List<DeviceData>?)?.length;
      _branchCount = (results[3] as List<BranchData>?)?.length;
      _loading = false;
    });
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
        validator: (value) => nameProblem(value, label.toLowerCase()),
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
  /// then. An account without an email (mobile or Google sign-up) adds one the
  /// same way; a Google sign-up's Gmail stays separate, under Password &
  /// Security.
  Future<void> _editEmail() async {
    final profile = _profile;
    if (profile == null) return;
    final adding = profile.email == null;

    final value = await showDialog<String>(
      context: context,
      builder: (_) => _ChangeProfileFieldDialog(
        label: 'Email Address',
        title: adding ? 'Add Email Address' : null,
        initialValue: profile.email ?? '',
        hint: 'janedoe@email.com',
        validator: emailProblem,
      ),
    );
    final email = value?.toLowerCase();
    if (email == null || email == profile.email || !mounted) return;

    await _changeContact(
      label: 'Email Address',
      display: email,
      adding: adding,
      request: () => widget.authRepository.requestEmailChange(email),
      codeDialog: (resend) => _CodeDialog(
        title: 'Verify Email',
        destination: email,
        icon: Icons.mark_email_unread_outlined,
        onResend: resend,
      ),
      confirm: (code) =>
          widget.authRepository.confirmEmailChange(email: email, code: code),
    );
  }

  /// Same as email: Cognito texts a code to the new number, which replaces
  /// the old one (or is added) only once the code is confirmed.
  Future<void> _editMobileNumber() async {
    final profile = _profile;
    if (profile == null) return;
    final adding = profile.mobileNumber == null;

    final mobileNumber = await showDialog<String>(
      context: context,
      builder: (_) => _ChangeMobileNumberDialog(
        adding: adding,
        initialNumber: profile.mobileNumber,
      ),
    );
    if (mobileNumber == null ||
        mobileNumber == profile.mobileNumber ||
        !mounted) {
      return;
    }

    final display = formatPhilippineMobile(mobileNumber);
    await _changeContact(
      label: 'Mobile Number',
      display: display,
      adding: adding,
      request: () =>
          widget.authRepository.requestMobileNumberChange(mobileNumber),
      codeDialog: (resend) => _CodeDialog(
        title: 'Verify Mobile Number',
        destination: display,
        icon: Icons.sms_outlined,
        onResend: resend,
      ),
      confirm: (code) => widget.authRepository.confirmMobileNumberChange(
        mobileNumber: mobileNumber,
        code: code,
      ),
    );
  }

  /// Confirm → send code → enter code (retried while the code is wrong) →
  /// saved notice.
  Future<void> _changeContact({
    required String label,
    required String display,
    required bool adding,
    required Future<void> Function() request,
    required Widget Function(Future<bool> Function() resend) codeDialog,
    required Future<UserProfile> Function(String code) confirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmProfileChangeDialog(label: label, value: display),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await request();
    } on AuthFailure catch (error) {
      _message(error.message);
      return;
    } on Exception {
      _message('Could not send a verification code. Please try again.');
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    // Asking for the same email or number again sends a fresh code.
    Future<bool> resend() async {
      try {
        await request();
        _message('We sent you a new code.');
        return true;
      } on AuthFailure catch (error) {
        _message(error.message);
      } on Exception {
        _message('Could not send a new code. Please try again.');
      }
      return false;
    }

    // A mistyped code can be retried; any other failure ends the flow.
    while (true) {
      if (!mounted) return;
      final code = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => codeDialog(resend),
      );
      if (code == null || !mounted) return;
      final result = await _save(
        () => confirm(code),
        savedTitle: adding ? '$label Added!' : null,
        savedMessage: adding
            ? 'You can now use $display to sign in to inSOL8.'
            : null,
      );
      if (result != _SaveResult.codeError) return;
    }
  }

  /// Saves behind a progress bar, then shows the stored profile.
  Future<_SaveResult> _save(
    Future<UserProfile> Function() action, {
    String? savedTitle,
    String? savedMessage,
  }) async {
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
      builder: (_) => _SavedDialog(title: savedTitle, message: savedMessage),
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
                                profile?.email ?? 'Add email address',
                                editable: true,
                                placeholder: profile?.email == null,
                                onTap: _saving ? null : _editEmail,
                              ),
                              _InfoRow(
                                'Mobile number',
                                switch (profile?.mobileNumber) {
                                  final number? => formatPhilippineMobile(
                                    number,
                                  ),
                                  null => 'Add mobile number',
                                },
                                editable: true,
                                placeholder: profile?.mobileNumber == null,
                                onTap: _saving ? null : _editMobileNumber,
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
                                _planLoaded ? _planLabel(_plan) : '—',
                                editable: true,
                                onTap: () => Navigator.of(context)
                                    .pushNamed(AppRoutes.billingInformation),
                              ),
                              _InfoRow(
                                'Registered Devices',
                                switch (_deviceCount) {
                                  null => '—',
                                  1 => '1 Device',
                                  final count => '$count Devices',
                                },
                              ),
                              _InfoRow(
                                'Registered Branches',
                                switch (_branchCount) {
                                  null => '—',
                                  1 => '1 Branch',
                                  final count => '$count Branches',
                                },
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

  /// Only a plan the backend reports; an account without one says so
  /// rather than showing a made-up "Basic Tier".
  String _planLabel(String? plan) => switch (plan) {
    SubscriptionPlanIds.organization => 'Org Tier',
    SubscriptionPlanIds.basic => 'Basic Tier',
    null => 'No plan yet',
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
                          // An empty contact reads as an action: "Add …".
                          color: row.placeholder
                              ? AppColors.primary
                              : AppColors.fieldHint,
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
    this.placeholder = false,
    this.last = false,
    this.onTap,
  });
  final String label;
  final String value;
  final bool editable;

  /// [value] is an "Add …" prompt rather than saved data.
  final bool placeholder;
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

  /// Same rule as sign-up; shown as soon as the user edits the field.
  bool get _valid => usernameProblem(_controller.text) == null;

  void _save() {
    if (!_valid) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    icon: Icons.alternate_email_rounded,
    title: 'Change Username',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter a new unique username. Letters, numbers, dots, and underscores only.',
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
          onChanged: (value) => setState(() => _error = usernameProblem(value)),
          decoration: InputDecoration(
            hintText: 'janedoe123456',
            error: _error == null ? null : const SizedBox.shrink(),
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
        if (_error case final error?) ...[
          const SizedBox(height: 8),
          ErrorBanner(error),
        ],
      ],
    ),
    actions: [
      _DialogCancelButton(onPressed: () => Navigator.pop(context)),
      _DialogPrimaryButton(label: 'Save', onPressed: _valid ? _save : null),
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

class _SavedDialog extends StatelessWidget {
  const _SavedDialog({this.title, this.message});

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    title: title ?? 'Changes Saved!',
    content: Text(
      message ?? 'Looking good! Your changes are now have been saved.',
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.ink, fontSize: 16, height: 1.3),
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
    this.title,
    required this.validator,
  });

  final String label;

  /// Defaults to "Change [label]".
  final String? title;
  final String initialValue;
  final String hint;

  /// The field's rule; its message shows as soon as the user edits.
  final String? Function(String value) validator;

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

  bool get _isEmail => widget.label == 'Email Address';

  bool get _valid => widget.validator(_controller.text) == null;

  void _save() {
    if (!_valid) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    icon: _isEmail ? Icons.mail_outline_rounded : Icons.person_outline_rounded,
    title: widget.title ?? 'Change ${widget.label}',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title == null
              ? 'Enter your new ${widget.label.toLowerCase()}.'
              : 'Enter your ${widget.label.toLowerCase()}. We’ll send it a '
                    '6-digit code.',
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
          keyboardType: _isEmail
              ? TextInputType.emailAddress
              : TextInputType.name,
          textCapitalization: _isEmail
              ? TextCapitalization.none
              : TextCapitalization.words,
          autocorrect: false,
          onChanged: (value) =>
              setState(() => _error = widget.validator(value)),
          decoration: InputDecoration(
            hintText: widget.hint,
            error: _error == null ? null : const SizedBox.shrink(),
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
        if (_error case final error?) ...[
          const SizedBox(height: 8),
          ErrorBanner(error),
        ],
      ],
    ),
    actions: [
      _DialogCancelButton(onPressed: () => Navigator.pop(context)),
      _DialogPrimaryButton(label: 'Save', onPressed: _valid ? _save : null),
    ],
  );
}

enum _SaveResult { saved, codeError, failed }

/// Philippine mobile input in the same 🇵🇭 +63 field as sign-up. Pops the
/// number as +639XXXXXXXXX.
class _ChangeMobileNumberDialog extends StatefulWidget {
  const _ChangeMobileNumberDialog({required this.adding, this.initialNumber});

  final bool adding;
  final String? initialNumber;

  @override
  State<_ChangeMobileNumberDialog> createState() =>
      _ChangeMobileNumberDialogState();
}

class _ChangeMobileNumberDialogState extends State<_ChangeMobileNumberDialog> {
  late final TextEditingController _controller;

  /// Shown under the field row, starting under the flag: the Smart/TNT
  /// notice as soon as the prefix is typed, other problems once Save is
  /// tapped.
  String? _notice;
  bool _submitted = false;

  static const _formatter = PhoneNumberInputFormatter(
    groupLengths: [3, 3, 4],
    maxDigits: 10,
  );

  @override
  void initState() {
    super.initState();
    final current = widget.initialNumber;
    _controller = TextEditingController(
      text: current == null
          ? ''
          : _formatter.formatDigits(current.substring(3)),
    )..addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _problem({required bool complete}) {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 3 &&
        isSmartNetworkNumber('+63${digits.padRight(10, '0')}')) {
      return smartNetworkUnsupportedMessage;
    }
    if (digits.isNotEmpty && !digits.startsWith('9')) {
      return 'Enter a mobile number that starts with 9, like 917 123 4567.';
    }
    if (!complete) return null;
    if (digits.isEmpty) return 'Enter your mobile number.';
    if (normalizePhilippineMobile(digits) == null) {
      return 'Enter a mobile number that starts with 9, like 917 123 4567.';
    }
    return null;
  }

  // Every keystroke: the notice and whether Save is enabled can change.
  void _onChanged() => setState(() => _notice = _problem(complete: _submitted));

  void _save() {
    _submitted = true;
    final notice = _problem(complete: true);
    if (notice != null) {
      setState(() => _notice = notice);
      return;
    }
    Navigator.of(context).pop(normalizePhilippineMobile(_controller.text));
  }

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    icon: Icons.smartphone_rounded,
    title: widget.adding ? 'Add Mobile Number' : 'Change Mobile Number',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter your Philippine mobile number. We’ll text it a 6-digit code.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.3),
        ),
        const SizedBox(height: 24),
        PhoneNumberField(
          controller: _controller,
          validator: (_) => null,
          hintText: '917 123 4567',
          onSubmitted: (_) => _save(),
          errorText: _notice,
        ),
      ],
    ),
    actions: [
      _DialogCancelButton(onPressed: () => Navigator.pop(context)),
      _DialogPrimaryButton(
        label: 'Save',
        onPressed: _problem(complete: true) == null ? _save : null,
      ),
    ],
  );
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog({
    required this.title,
    required this.destination,
    required this.icon,
    required this.onResend,
  });

  final String title;

  /// Where the code was sent: an email address or a formatted mobile number.
  final String destination;
  final IconData icon;
  final Future<bool> Function() onResend;

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  String _code = '';
  String? _error;

  void _verify() {
    if (!RegExp(r'^\d{6}$').hasMatch(_code)) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    Navigator.of(context).pop(_code);
  }

  @override
  Widget build(BuildContext context) => _ProfileDialog(
    icon: widget.icon,
    title: widget.title,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              height: 1.3,
            ),
            children: [
              const TextSpan(text: 'Enter the 6-digit code we sent to\n'),
              TextSpan(
                text: widget.destination,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        SixDigitCodeField(
          onChanged: (code) => setState(() {
            _code = code;
            _error = null;
          }),
          // Verifies as soon as the last digit is typed.
          onCompleted: (_) => _verify(),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: 10),
          ErrorBanner(error),
        ],
        const SizedBox(height: 14),
        ResendCodeLink(onResend: widget.onResend),
      ],
    ),
    actions: [
      _DialogCancelButton(onPressed: () => Navigator.pop(context)),
      _DialogPrimaryButton(
        label: 'Verify',
        onPressed: _code.length == 6 ? _verify : null,
      ),
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
    this.icon,
    this.title,
    required this.content,
    required this.actions,
  });

  /// Shown in a round badge above the title. Only dialogs with a field
  /// (input or code) have one; confirmations and notices do not.
  final IconData? icon;
  final String? title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    // Scrolls when the keyboard leaves too little room.
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            DialogIconBadge(icon!),
            const SizedBox(height: 14),
          ],
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

  /// Null greys the button out (the dialog's input isn't valid yet).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.disabled,
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    ),
  );
}
