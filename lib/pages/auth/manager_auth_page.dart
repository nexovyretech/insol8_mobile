import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/legal_document.dart';
import 'package:insol8_mobile/models/manager_auth_args.dart';
import 'package:insol8_mobile/pages/auth/signup/signup_shared_widgets.dart';
import 'package:insol8_mobile/pages/auth/signup/signup_step_widgets.dart';
import 'package:insol8_mobile/pages/legal/legal_document_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/utils/password_rules.dart';
import 'package:insol8_mobile/utils/profile_rules.dart';
import 'package:insol8_mobile/widgets/auth/auth_password_field.dart';
import 'package:insol8_mobile/widgets/auth/brand_mark.dart';
import 'package:insol8_mobile/widgets/auth/primary_button.dart';
import 'package:insol8_mobile/widgets/error_banner.dart';

/// Manager activation after the owner invites them by email or SMS.
///
/// The Figma frames start at "Create a password" and continue to
/// "Create username" under the same "Welcome to InSOL8!" invitation header.
/// The backend has no manager-activation endpoint yet, so the final submit is
/// a preview that routes to sign in instead of pretending to create an account.
class ManagerAuthPage extends StatefulWidget {
  const ManagerAuthPage({super.key, ManagerAuthArgs? args})
    : args = args ?? const ManagerAuthArgs();

  final ManagerAuthArgs args;

  @override
  State<ManagerAuthPage> createState() => _ManagerAuthPageState();
}

class _ManagerAuthPageState extends State<ManagerAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _username = TextEditingController();

  int _step = 0;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _acceptedTerms = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (final controller in [_password, _confirmPassword, _username]) {
      controller.addListener(_handleInputChanged);
    }
  }

  void _handleInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [_password, _confirmPassword, _username]) {
      controller.removeListener(_handleInputChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _back() {
    if (_step == 1) {
      setState(() {
        _step = 0;
        _errorMessage = null;
      });
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _errorMessage = null);
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    _submit();
  }

  void _submit() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Preview only: manager account setup is waiting for the backend.',
          ),
          action: SnackBarAction(
            label: 'Go to sign in',
            onPressed: () =>
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
          ),
        ),
      );
  }

  void _openSignIn() => Navigator.of(context).pushNamed(AppRoutes.login);

  void _openLegalDocument(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentPage(document: document),
      ),
    );
  }

  bool get _canContinue => switch (_step) {
    0 =>
      passwordProblem(_password.text) == null &&
          _confirmPassword.text == _password.text,
    1 => usernameProblem(_username.text) == null && _acceptedTerms,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 810;
            final logoTitleGap = isCompact ? 40.0 : 54.0;
            final titleSubtitleGap = isCompact ? 20.0 : 30.0;
            final subtitleFormGap = isCompact ? 32.0 : 58.0;

            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontal,
                      AppSpacing.pageVertical,
                      AppSpacing.pageHorizontal,
                      AppSpacing.pageVertical,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 52,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Transform.translate(
                                  offset: const Offset(-8, 0),
                                  child: IconButton(
                                    onPressed: _back,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 42,
                                      height: 42,
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 20,
                                    ),
                                    color: AppColors.ink,
                                    tooltip: 'Back',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const BrandMark(size: 69),
                            SizedBox(height: logoTitleGap),
                            const Text(
                              'Welcome to InSOL8!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Sora',
                                color: AppColors.ink,
                                fontSize: 23,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: titleSubtitleGap),
                            const Text(
                              'Your branch owner has invited you\n'
                              'to manage a branch.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Work Sans',
                                color: AppColors.body,
                                fontSize: 13,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: subtitleFormGap),
                          ],
                        ),
                        Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: _step == 0
                              ? _ManagerPasswordStep(
                                  passwordController: _password,
                                  confirmController: _confirmPassword,
                                  passwordVisible: _passwordVisible,
                                  confirmPasswordVisible:
                                      _confirmPasswordVisible,
                                  onTogglePasswordVisibility: () => setState(
                                    () => _passwordVisible = !_passwordVisible,
                                  ),
                                  onToggleConfirmVisibility: () => setState(
                                    () => _confirmPasswordVisible =
                                        !_confirmPasswordVisible,
                                  ),
                                )
                              : SignUpUsernameStep(
                                  usernameController: _username,
                                  acceptedTerms: _acceptedTerms,
                                  onTermsChanged: (value) =>
                                      setState(() => _acceptedTerms = value),
                                  onOpenLegalDocument: _openLegalDocument,
                                  validateUsername: (value) =>
                                      usernameProblem(value ?? ''),
                                ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              ErrorBanner(_errorMessage!),
                            ],
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: _step == 0 ? 'Continue' : 'Create Account',
                              onPressed: _continue,
                              enabled: _canContinue,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SignUpSignInPrompt(onTap: _openSignIn),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ManagerPasswordStep extends StatelessWidget {
  const _ManagerPasswordStep({
    required this.passwordController,
    required this.confirmController,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmVisibility,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignUpStepHeading(
          title: 'Create a password',
          description:
              'Create a password comprising a minimum 8 letters or digits',
        ),
        const SizedBox(height: 28),
        AuthPasswordField(
          controller: passwordController,
          hintText: 'Enter your password',
          visible: passwordVisible,
          onToggleVisibility: onTogglePasswordVisibility,
          textInputAction: TextInputAction.next,
          validator: (value) => passwordProblem(value ?? ''),
        ),
        const SizedBox(height: 10),
        AuthPasswordField(
          controller: confirmController,
          hintText: 'Confirm your password',
          visible: confirmPasswordVisible,
          onToggleVisibility: onToggleConfirmVisibility,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Confirm your password.';
            return value == passwordController.text
                ? null
                : 'Passwords do not match.';
          },
        ),
      ],
    );
  }
}
