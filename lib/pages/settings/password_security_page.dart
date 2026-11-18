import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/home/dashboard_bottom_navigation.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/utils/password_rules.dart';
import 'package:insol8_mobile/utils/phone_number.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';
import 'package:insol8_mobile/widgets/dialog_icon_badge.dart';
import 'package:insol8_mobile/widgets/error_banner.dart';
import 'package:insol8_mobile/widgets/password_requirements.dart';
import 'package:insol8_mobile/widgets/resend_code_link.dart';
import 'package:insol8_mobile/widgets/six_digit_code_field.dart';

class PasswordSecurityPage extends StatefulWidget {
  const PasswordSecurityPage({
    super.key,
    required this.authRepository,
    required this.subscriptionRepository,
  });
  final AuthRepository authRepository;
  final SubscriptionRepository subscriptionRepository;

  @override
  State<PasswordSecurityPage> createState() => _PasswordSecurityPageState();
}

class _PasswordSecurityPageState extends State<PasswordSecurityPage>
    with WidgetsBindingObserver {
  /// The connected Google account's email, or null when none is connected.
  String? _googleEmail;

  UserProfile? _profile;

  /// Signed up with Google and has no password yet: the Password row offers
  /// "Create password" instead of "Update password".
  bool _googleAccount = false;
  bool _changingPassword = false;
  bool _loadingGoogle = true;
  bool _connecting = false;

  /// Set while Google's sign-in page is open in the browser; the page is
  /// checked again when the app comes back to the front.
  bool _awaitingGoogleReturn = false;
  bool _organizationPlan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadContact();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingGoogleReturn) {
      _awaitingGoogleReturn = false;
      _afterGoogleReturn();
    }
  }

  Future<void> _loadContact() async {
    try {
      final profile = await widget.authRepository.loadProfile();
      final googleAccount = await widget.authRepository.isGoogleAccount();
      final plan = await widget.subscriptionRepository.fetchActivePlanId();
      if (mounted) {
        setState(() {
          _profile = profile;
          _googleAccount = googleAccount;
          _googleEmail = profile.googleEmail;
          _organizationPlan = plan == SubscriptionPlanIds.organization;
        });
      }
    } on Exception {
      // The security screen remains usable when profile details are offline.
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  /// Opens Google's sign-in page in the browser. The backend links the chosen
  /// Google account and sends the browser back to the app; if linking fails,
  /// the browser page explains why.
  Future<void> _connectGoogle() async {
    setState(() => _connecting = true);
    try {
      final url = await widget.authRepository.startGoogleLink();
      _awaitingGoogleReturn = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!_awaitingGoogleReturn) {
        _message('Couldn’t open Google. Make sure a browser is installed.');
      }
    } on AuthFailure catch (error) {
      _message(error.message);
    } on Exception {
      _message('Couldn’t start connecting Google. Please try again.');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _afterGoogleReturn() async {
    setState(() => _loadingGoogle = true);
    await _loadContact();
    if (!mounted) return;
    final email = _googleEmail;
    if (email == null) {
      _message('Your Google account wasn’t connected.');
      return;
    }
    await _showNotice(
      title: 'Google Connected!',
      message: 'You can now use “Continue with Google” with $email to sign in.',
    );
  }

  void _message(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _disconnect() async {
    final confirmed = await _showConfirmation(
      message:
          'Are you sure you want to disconnect the\n'
          '${_googleEmail ?? 'Google'} account connected?',
    );
    if (!mounted || confirmed != true) return;

    await _showNotice(
      title: 'Account Disconnected!',
      message: 'Your Google account has been disconnected!',
    );
    if (mounted) {
      _message('Preview only — account disconnection is not connected yet.');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showConfirmation(
      message:
          'This action cannot be undone. All your personal data, saved '
          'items, and account history will be permanently erased.',
      emphasizeStart: 'This action cannot be undone.',
    );
    if (!mounted || confirmed != true) return;

    await _showNotice(
      title: 'Good Bye :(',
      message: 'We’re sorry to let you go. Baby come back oohhh',
    );
    if (mounted) {
      _message('Preview only — account deletion is not connected yet.');
    }
  }

  Future<bool?> _showConfirmation({
    required String message,
    String? emphasizeStart,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => _SecurityDialog(
      message: message,
      emphasizeStart: emphasizeStart,
      cancelLabel: 'Cancel',
      confirmLabel: 'OK',
    ),
  );

  Future<void> _showNotice({
    required String title,
    required String message,
    IconData? icon,
  }) => showDialog<void>(
    context: context,
    builder: (context) => _SecurityDialog(
      icon: icon,
      title: title,
      message: message,
      confirmLabel: 'OK',
    ),
  );

  Future<void> _onPasswordTap() =>
      _googleAccount ? _createPassword() : _updatePassword();

  Future<void> _updatePassword() async {
    final currentPassword = await _passwordPrompt(
      title: 'Enter Password',
      description: 'To proceed, please enter your current password.',
      // Checked with Cognito before the next step; a wrong one stays here.
      check: (password) async {
        try {
          await widget.authRepository.verifyCurrentPassword(password);
          return null;
        } on AuthFailure catch (error) {
          return error.message;
        } on Exception {
          return 'Couldn’t check your password. Please try again.';
        }
      },
    );
    if (!mounted || currentPassword == null) return;

    final newPassword = await _passwordPrompt(
      title: 'New Password',
      description: 'Choose a password that meets all the requirements below.',
      validator: _validateNewPassword,
      showRequirements: true,
    );
    if (!mounted || newPassword == null) return;

    final confirmation = await _passwordPrompt(
      title: 'Confirm New Password',
      description: 'Type your new password again to make sure it matches.',
      validator: (value) =>
          value == newPassword ? null : 'Passwords do not match.',
    );
    if (!mounted || confirmation == null) return;

    final confirmed = await _showConfirmation(
      message:
          'You’ll use your new password the next time you sign in. '
          'Do you wish to continue?',
      emphasizeStart: 'Do you wish to continue?',
    );
    if (!mounted || confirmed != true) return;

    setState(() => _changingPassword = true);
    try {
      await widget.authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AuthFailure catch (error) {
      if (error.signedOut) {
        _leaveToLogin();
      } else {
        _message(error.message);
      }
      return;
    } on Exception {
      _message('Couldn’t update your password. Please try again.');
      return;
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
    if (!mounted) return;
    await _showNotice(
      title: 'Password Updated!',
      message:
          'Your password has been changed successfully. You can now use '
          'your new password the next time you sign in.',
    );
  }

  /// A Google sign-up gets a password, staying signed in throughout:
  /// password → confirm → a code is sent to the account's email or mobile
  /// number → code → created. The backend moves the account to one that can
  /// have a password (data and Google sign-in kept), and the app swaps its
  /// sign-in for one on the new account with the new password.
  Future<void> _createPassword() async {
    final profile = _profile;
    if (profile == null) {
      _message('Your account is still loading. Please try again.');
      return;
    }
    final email = profile.email;
    final mobile = profile.mobileNumber;
    if (email == null && mobile == null) {
      await _showNotice(
        title: 'Add an Email or Mobile First',
        message:
            'We send a code there to create your password, and use it if '
            'you ever need to reset it. Add one in Account Profile.',
      );
      return;
    }
    final toEmail = email != null;
    final destination = email ?? formatPhilippineMobile(mobile!);

    final newPassword = await _passwordPrompt(
      title: 'Create Password',
      description: 'Choose a password that meets all the requirements below.',
      validator: _validateNewPassword,
      showRequirements: true,
    );
    if (!mounted || newPassword == null) return;

    final confirmation = await _passwordPrompt(
      title: 'Confirm Password',
      description: 'Type your password again to make sure it matches.',
      validator: (value) =>
          value == newPassword ? null : 'Passwords do not match.',
    );
    if (!mounted || confirmation == null) return;

    Future<bool> sendCode() async {
      try {
        await widget.authRepository.sendPasswordCreationCode(toEmail: toEmail);
        return true;
      } on AuthFailure catch (error) {
        _message(error.message);
      } on Exception {
        _message('Couldn’t send a code. Please try again.');
      }
      return false;
    }

    setState(() => _changingPassword = true);
    final sent = await sendCode();
    if (mounted) setState(() => _changingPassword = false);
    if (!sent || !mounted) return;

    // A wrong code can be retried; the dialog also offers a new code.
    while (true) {
      if (!mounted) return;
      final code = await _codePrompt(destination, onResend: sendCode);
      if (code == null || !mounted) return;
      setState(() => _changingPassword = true);
      try {
        await widget.authRepository.createPassword(
          toEmail: toEmail,
          code: code,
          password: newPassword,
        );
        break;
      } on AuthFailure catch (error) {
        if (error.signedOut) {
          _leaveToLogin();
          return;
        }
        _message(error.message);
        if (!error.isCodeError) return;
      } on Exception {
        _message('Couldn’t create your password. Please try again.');
        return;
      } finally {
        if (mounted) setState(() => _changingPassword = false);
      }
    }

    if (!mounted) return;
    await _showNotice(
      title: 'Password Created!',
      message:
          'You can now sign in with your password, or keep using '
          '“Continue with Google”.',
    );
    if (mounted) {
      setState(() => _loadingGoogle = true);
      await _loadContact();
    }
  }

  /// Only when the password was set but signing back in failed: the device
  /// is signed out, so it goes straight to the login screen. No success
  /// message: the user is no longer in the app to act on it.
  void _leaveToLogin() {
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Future<String?> _codePrompt(
    String destination, {
    required Future<bool> Function() onResend,
  }) => showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PasswordPromptDialog(
      icon: destination.contains('@')
          ? Icons.mark_email_unread_outlined
          : Icons.sms_outlined,
      title: 'Enter Code',
      description: 'Enter the 6-digit code we sent to $destination.',
      code: true,
      onResend: onResend,
    ),
  );

  Future<String?> _passwordPrompt({
    required String title,
    required String description,
    String? Function(String?)? validator,
    Future<String?> Function(String password)? check,
    bool showRequirements = false,
  }) => showDialog<String>(
    context: context,
    builder: (context) => _PasswordPromptDialog(
      icon: Icons.lock_outline_rounded,
      title: title,
      description: description,
      validator: validator,
      check: check,
      showRequirements: showRequirements,
    ),
  );

  /// The same rules as sign-up and the Cognito pool (password_rules.dart).
  String? _validateNewPassword(String? value) => passwordProblem(value ?? '');

  void _navigation(int index) {
    if (index == 3) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRoutes.settings);
    } else if (index == 0) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRoutes.home);
    } else if (index == 1) {
      Navigator.of(
        context,
      ).pushNamed(_organizationPlan ? AppRoutes.branches : AppRoutes.devices);
    } else if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.analytics);
    }
  }

  Widget _googleTile() {
    final email = _googleEmail;
    const padding = EdgeInsets.symmetric(horizontal: 14);
    if (_loadingGoogle) {
      return const ListTile(
        contentPadding: padding,
        leading: _GoogleBadge(),
        title: Text('Google'),
        subtitle: Text('Loading account…'),
      );
    }
    if (email != null) {
      return ListTile(
        contentPadding: padding,
        leading: const _GoogleBadge(),
        title: const Text('Connected'),
        subtitle: Text(email),
        // A Google sign-up has no other way in, so it can't disconnect.
        trailing: _googleAccount
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.sectionLabel,
                ),
                onPressed: _disconnect,
              ),
      );
    }
    return ListTile(
      contentPadding: padding,
      leading: const _GoogleBadge(),
      title: const Text('Google'),
      subtitle: const Text('Not connected'),
      trailing: SizedBox(
        height: 34,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _connecting ? null : _connectGoogle,
          child: _connecting
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Connect', style: TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
              title: 'Password & Security',
              onBack: () => Navigator.pop(context),
              trailing: IconButton(
                onPressed: () => _message(
                  'Password and security help will be available here.',
                ),
                tooltip: 'Help',
                icon: const Icon(Icons.help_outline, size: 18),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sectionGap,
                  bottom: 24,
                ),
                children: [
                  const _SectionLabel('Security Info'),
                  _SettingsCard(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: Text(
                        _loadingGoogle
                            ? 'Password'
                            : _googleAccount
                            ? 'Create password'
                            : 'Update password',
                      ),
                      trailing: _changingPassword
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.chevron_right,
                              color: AppColors.sectionLabel,
                            ),
                      onTap: _loadingGoogle || _changingPassword
                          ? null
                          : _onPasswordTap,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel('Account Info'),
                  _SettingsCard(child: _googleTile()),
                  const SizedBox(height: 16),
                  const _SectionLabel('Danger Zone'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 40,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: _deleteAccount,
                        child: const Text(
                          'Delete account',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permanently removes your account, unlinks registered devices, and clears your subscription tier.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.fieldHint,
                      fontSize: 12,
                      height: 1.35,
                    ),
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
      organizationPlan: _organizationPlan,
      onSelect: _navigation,
    ),
  );
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A35170F),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    // ListTiles paint their tap ripple on the nearest Material; without this
    // one, the card's own color would hide it.
    child: Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog({
    required this.icon,
    required this.title,
    required this.description,
    this.validator,
    this.check,
    this.code = false,
    this.onResend,
    this.showRequirements = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? Function(String?)? validator;

  /// Runs when OK is tapped (after [validator]); returns an error to show in
  /// the dialog, or null to close it with the password.
  final Future<String?> Function(String password)? check;

  /// Code mode: sends a new code; shown as "Resend code" after a countdown.
  final Future<bool> Function()? onResend;

  /// Shows the live password checklist under the field (new passwords).
  final bool showRequirements;

  /// Asks for a 6-digit code in six boxes instead of a password.
  final bool code;

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _visible = false;
  bool _checking = false;
  String? _checkError;
  String _code = '';
  String? _codeError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if ((value ?? '').isEmpty) return 'Please enter your password.';
    return _checkError ?? widget.validator?.call(value);
  }

  /// Shown while typing (for example "Passwords do not match."). A new
  /// password has the live checklist instead, so it gets no message here.
  String? get _liveError {
    final text = _controller.text;
    if (text.isEmpty || widget.showRequirements) return null;
    return widget.validator?.call(text);
  }

  /// OK / Verify stay greyed out until the input can be used.
  bool get _canSubmit {
    if (widget.code) return _code.length == 6;
    final text = _controller.text;
    return text.isNotEmpty && widget.validator?.call(text) == null;
  }

  static const _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide.none,
  );

  /// Errors (rules, a wrong current password) show in the error banner.
  Widget _passwordField() => FieldWithErrorBanner(
    controller: _controller,
    validator: _validate,
    message: _checkError ?? _liveError,
    builder: (context, validate) => TextFormField(
      controller: _controller,
      obscureText: !_visible,
      autofocus: true,
      validator: validate,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      onChanged: (_) => setState(() => _checkError = null),
      decoration: InputDecoration(
        hintText: 'password',
        errorStyle: FieldWithErrorBanner.hiddenErrorStyle,
        filled: true,
        fillColor: AppColors.dashboardCard,
        suffixIcon: IconButton(
          tooltip: _visible ? 'Hide password' : 'Show password',
          onPressed: () => setState(() => _visible = !_visible),
          icon: Icon(
            _visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.fieldHint,
            size: 20,
          ),
        ),
        border: _fieldBorder,
        enabledBorder: _fieldBorder,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.dashboardBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    ),
  );

  Widget _codeField() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SixDigitCodeField(
        onChanged: (code) => setState(() {
          _code = code;
          _codeError = null;
        }),
        onCompleted: (_) => _submit(),
      ),
      if (_codeError case final error?) ...[
        const SizedBox(height: 10),
        ErrorBanner(error),
      ],
      if (widget.onResend case final onResend?) ...[
        const SizedBox(height: 14),
        ResendCodeLink(onResend: onResend),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.surface,
    insetPadding: const EdgeInsets.symmetric(horizontal: 28),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    // Scrolls when the keyboard leaves too little room.
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogIconBadge(widget.icon),
            const SizedBox(height: 14),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.sectionLabel,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            if (widget.code) _codeField() else _passwordField(),
            if (widget.showRequirements) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: PasswordRequirements(controller: _controller),
              ),
            ],
            const SizedBox(height: 14),
            if (_checking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              _DialogActions(
                cancelLabel: 'Cancel',
                confirmLabel: widget.code ? 'Verify' : 'OK',
                onCancel: () => Navigator.pop(context),
                onConfirm: _canSubmit ? _submit : null,
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    if (widget.code) {
      if (!RegExp(r'^\d{6}$').hasMatch(_code)) {
        setState(() => _codeError = 'Enter the 6-digit code.');
        return;
      }
      Navigator.pop(context, _code);
      return;
    }
    if (_checking) return;
    _checkError = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final password = _controller.text;
    if (widget.check case final check?) {
      setState(() => _checking = true);
      final error = await check(password);
      if (!mounted) return;
      setState(() {
        _checking = false;
        _checkError = error;
      });
      if (error != null) {
        _formKey.currentState?.validate();
        return;
      }
    }
    Navigator.pop(context, password);
  }
}

/// The Google "G" drawn in the theme orange, in the app's round icon badge.
class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    padding: const EdgeInsets.all(8),
    decoration: const BoxDecoration(
      color: AppColors.dashboardIconBackground,
      shape: BoxShape.circle,
    ),
    child: SvgPicture.asset(
      'assets/icons/google_g.svg',
      colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
    ),
  );
}

class _SecurityDialog extends StatelessWidget {
  const _SecurityDialog({
    this.icon,
    this.title,
    required this.message,
    this.emphasizeStart,
    this.cancelLabel,
    required this.confirmLabel,
  });

  final IconData? icon;
  final String? title;
  final String message;
  final String? emphasizeStart;
  final String? cancelLabel;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.surface,
    insetPadding: const EdgeInsets.symmetric(horizontal: 28),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    // Scrolls when the keyboard leaves too little room.
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
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
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text.rich(
            _messageSpan(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          _DialogActions(
            cancelLabel: cancelLabel,
            confirmLabel: confirmLabel,
            onCancel: cancelLabel == null
                ? null
                : () => Navigator.pop(context, false),
            onConfirm: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ),
  );

  TextSpan _messageSpan() {
    final emphasized = emphasizeStart;
    if (emphasized == null || !message.contains(emphasized)) {
      return TextSpan(text: message);
    }
    final start = message.indexOf(emphasized);
    return TextSpan(
      children: [
        if (start > 0) TextSpan(text: message.substring(0, start)),
        TextSpan(
          text: emphasized,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (start + emphasized.length < message.length)
          TextSpan(text: message.substring(start + emphasized.length)),
      ],
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.cancelLabel,
    required this.confirmLabel,
    this.onCancel,
    required this.onConfirm,
  });

  final String? cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;

  /// Null greys the button out (the dialog's input isn't valid yet).
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final confirmButton = SizedBox(
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onConfirm,
        child: Text(
          confirmLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );

    if (cancelLabel == null) {
      return SizedBox(width: double.infinity, child: confirmButton);
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.fieldHint,
                backgroundColor: AppColors.dashboardCard,
                side: const BorderSide(color: AppColors.dashboardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onCancel,
              child: Text(cancelLabel!),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: confirmButton),
      ],
    );
  }
}
