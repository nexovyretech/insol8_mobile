import 'package:flutter/material.dart';

import 'package:insol8_mobile/pages/home/dashboard_bottom_navigation.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

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

class _PasswordSecurityPageState extends State<PasswordSecurityPage> {
  String? _contact;
  bool _organizationPlan = false;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    try {
      final profile = await widget.authRepository.loadProfile();
      final plan = await widget.subscriptionRepository.fetchActivePlanId();
      if (mounted) {
        setState(() {
          _contact = profile.email ?? profile.mobileNumber;
          _organizationPlan = plan == SubscriptionPlanIds.organization;
        });
      }
    } on Exception {
      // The security screen remains usable when profile details are offline.
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _disconnect() async {
    final confirmed = await _showConfirmation(
      message:
          'Are you sure you want to disconnect the\n'
          '${_contact ?? 'account'} account connected?',
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

  Future<void> _showNotice({required String title, required String message}) =>
      showDialog<void>(
        context: context,
        builder: (context) =>
            _SecurityDialog(title: title, message: message, confirmLabel: 'OK'),
      );

  Future<void> _changePassword() async {
    final currentPassword = await _passwordPrompt(
      title: 'Enter Password',
      description: 'To proceed, please enter your current password.',
    );
    if (!mounted || currentPassword == null) return;

    final newPassword = await _passwordPrompt(
      title: 'New Password',
      description:
          'Create a strong password with a mix of letters, numbers, '
          'and symbols.',
      validator: _validateNewPassword,
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
          'Updating your password will sign you out of all other active '
          'devices. Do you wish to continue?',
      emphasizeStart: 'Do you wish to continue?',
    );
    if (!mounted || confirmed != true) return;

    // This is a UI preview only: AuthRepository currently supports password
    // reset, but not authenticated change-password or session revocation.
    await _showNotice(
      title: 'Password Updated!',
      message:
          'Your password has been changed successfully. You can now use '
          'your new password the next time you sign in.',
    );
    if (mounted) {
      _message('Preview only — password changes are not connected yet.');
    }
  }

  Future<String?> _passwordPrompt({
    required String title,
    required String description,
    String? Function(String?)? validator,
  }) => showDialog<String>(
    context: context,
    builder: (context) => _PasswordPromptDialog(
      title: title,
      description: description,
      validator: validator,
    ),
  );

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Use at least 8 characters with letters, numbers, and symbols.';
    }
    return null;
  }

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
                      title: const Text('Password'),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.sectionLabel,
                      ),
                      onTap: _changePassword,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel('Account Info'),
                  _SettingsCard(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      leading: const Icon(
                        Icons.circle,
                        size: 12,
                        color: AppColors.sectionLabel,
                      ),
                      title: const Text('Connected'),
                      subtitle: Text(_contact ?? 'Loading account…'),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.sectionLabel,
                        ),
                        onPressed: _disconnect,
                      ),
                    ),
                  ),
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
    child: child,
  );
}

class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog({
    required this.title,
    required this.description,
    this.validator,
  });

  final String title;
  final String description;
  final String? Function(String?)? validator;

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if ((value ?? '').isEmpty) return 'Please enter your password.';
    return widget.validator?.call(value);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.surface,
    insetPadding: const EdgeInsets.symmetric(horizontal: 28),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            TextFormField(
              controller: _controller,
              obscureText: true,
              autofocus: true,
              validator: _validate,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'password',
                filled: true,
                fillColor: AppColors.dashboardCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: AppColors.dashboardBorder),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _DialogActions(
              cancelLabel: 'Cancel',
              confirmLabel: 'OK',
              onCancel: () => Navigator.pop(context),
              onConfirm: _submit,
            ),
          ],
        ),
      ),
    ),
  );

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _controller.text);
    }
  }
}

class _SecurityDialog extends StatelessWidget {
  const _SecurityDialog({
    this.title,
    required this.message,
    this.emphasizeStart,
    this.cancelLabel,
    required this.confirmLabel,
  });

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
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final confirmButton = SizedBox(
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
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
