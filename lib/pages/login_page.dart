import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/auth/auth_password_field.dart';
import 'package:insol8_mobile/widgets/auth/auth_text_field.dart';
import 'package:insol8_mobile/widgets/auth/brand_mark.dart';
import 'package:insol8_mobile/widgets/auth/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _passwordVisible = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_handleInputChanged);
    _passwordController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _identifierController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _passwordController
      ..removeListener(_handleInputChanged)
      ..dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.signIn(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
      if (!mounted) return;
      _showMessage('You are signed in.');
    } on AuthNotConfiguredException {
      if (!mounted) return;
      _showMessage('Sign in is ready once the backend is connected.');
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'We couldn’t sign you in. Check your details and try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _requestPasswordReset() {
    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
  }

  Future<void> _signInWithGoogle() async {
    try {
      await widget.authRepository.signInWithGoogle();
      if (!mounted) return;
      _showMessage('You are signed in with Google.');
    } on AuthNotConfiguredException {
      if (!mounted) return;
      _showMessage('Google sign in is ready once the backend is connected.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Google sign in failed. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final canSignIn =
        _identifierController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      color: AppColors.ink,
                      tooltip: 'Back',
                    ),
                    const SizedBox(height: 12),
                    const Center(child: BrandMark(size: 60)),
                    const SizedBox(height: 36),
                    Center(
                      child: Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        'Sign in to continue managing your inSOL8\nsystem.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 46),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Username, Email or Mobile Number'),
                          const SizedBox(height: 8),
                          AuthTextField(
                            controller: _identifierController,
                            hintText: 'Enter your username, email or mobile',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter your username, email, or mobile number.'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          const _FieldLabel('Password'),
                          const SizedBox(height: 8),
                          AuthPasswordField(
                            controller: _passwordController,
                            hintText: 'Enter your password',
                            visible: _passwordVisible,
                            onToggleVisibility: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your password.'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) =>
                                setState(() => _rememberMe = value ?? false),
                            activeColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.fieldHint),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Remember me',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 11),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _requestPasswordReset,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('Forgot Password'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed(AppRoutes.signUp),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Create Account'),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 112,
                          child: PrimaryButton(
                            label: 'Sign in',
                            onPressed: _submit,
                            isLoading: _isSubmitting,
                            enabled: canSignIn,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _OrDivider(),
                    const SizedBox(height: 22),
                    _GoogleSignInButton(onPressed: _signInWithGoogle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dividerLine(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Or',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.fieldHint),
          ),
        ),
        _dividerLine(),
      ],
    );
  }

  Widget _dividerLine() => const Expanded(
    child: Divider(color: AppColors.inactive, thickness: 1, height: 1),
  );
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.googleButton,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/google_g.svg',
              width: 19,
              height: 19,
              semanticsLabel: 'Google',
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
