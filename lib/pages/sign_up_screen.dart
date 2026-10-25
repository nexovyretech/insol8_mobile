import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/sign_up_data.dart';
import 'package:insol8_mobile/constants/legal_documents.dart';
import 'package:insol8_mobile/models/legal_document.dart';
import 'package:insol8_mobile/pages/legal_document_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/auth/auth_password_field.dart';
import 'package:insol8_mobile/widgets/auth/auth_text_field.dart';
import 'package:insol8_mobile/widgets/auth/brand_mark.dart';
import 'package:insol8_mobile/widgets/auth/phone_number_field.dart';
import 'package:insol8_mobile/widgets/auth/primary_button.dart';
import 'package:insol8_mobile/widgets/auth/signup_progress.dart';
import 'package:insol8_mobile/widgets/auth/verification_code_input.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _emailContact = TextEditingController();
  final _mobileContact = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _username = TextEditingController();
  final _codeFields = List.generate(6, (_) => TextEditingController());
  final _codeFocus = List.generate(6, (_) => FocusNode());
  int _step = 0;
  bool _isVerifying = false;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isEmail = true;
  bool _acceptedTerms = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _firstName,
      _lastName,
      _emailContact,
      _mobileContact,
      _password,
      _confirmPassword,
      _username,
      ..._codeFields,
    ]) {
      controller.addListener(_handleInputChanged);
    }
  }

  void _handleInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _emailContact,
      _mobileContact,
      _password,
      _confirmPassword,
      _username,
      ..._codeFields,
    ]) {
      controller.removeListener(_handleInputChanged);
    }
    _firstName.dispose();
    _lastName.dispose();
    _emailContact.dispose();
    _mobileContact.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _username.dispose();
    for (final controller in _codeFields) {
      controller.dispose();
    }
    for (final focusNode in _codeFocus) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step == 1) {
      _requestVerificationCode();
      return;
    }
    if (_step < 4) {
      setState(() {
        _errorMessage = null;
        _step++;
      });
      return;
    }
    _submitSignUp();
  }

  Future<void> _requestVerificationCode() async {
    if (!widget.authRepository.isConfigured) {
      setState(() {
        _step = 2;
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preview only: a verification code will be sent after the backend is connected.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _step = 2;
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.authRepository.requestVerificationCode(
        contact: _contactForAuth,
        method: _isEmail
            ? SignUpContactMethod.email
            : SignUpContactMethod.mobile,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    } on AuthNotConfiguredException {
      _setSubmitError(
        'Verification is ready, but the backend is not connected yet.',
      );
    } catch (_) {
      _setSubmitError(
        'We couldn’t send a verification code. Please try again.',
      );
    }
  }

  Future<void> _submitSignUp() async {
    if (!widget.authRepository.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preview only: account creation is waiting for the backend.',
          ),
          action: SnackBarAction(
            label: 'Preview onboarding',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.onboarding),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final data = SignUpData(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      contact: _contactForAuth,
      contactMethod: _isEmail
          ? SignUpContactMethod.email
          : SignUpContactMethod.mobile,
      password: _password.text,
      username: _username.text.trim(),
      termsAccepted: _acceptedTerms,
    );
    try {
      await widget.authRepository.beginSignUp(data);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    } on AuthNotConfiguredException {
      _setSubmitError(
        'Sign up is ready, but the backend is not connected yet. Your details are still here.',
      );
    } catch (_) {
      _setSubmitError('We couldn’t create your account. Please try again.');
    }
  }

  void _setSubmitError(String message) {
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _errorMessage = message;
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeFields.map((field) => field.text).join();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit verification code.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    try {
      await widget.authRepository.verifyContact(
        contact: _contactForAuth,
        method: _isEmail
            ? SignUpContactMethod.email
            : SignUpContactMethod.mobile,
        code: code,
      );
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = null;
        _step = 3;
      });
    } on AuthNotConfiguredException {
      _setVerifyError('Verification will work when the backend is connected.');
    } catch (_) {
      _setVerifyError(
        'That code could not be verified. Check it and try again.',
      );
    }
  }

  void _setVerifyError(String message) {
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _errorMessage = message;
    });
  }

  void _skipVerificationForPreview() {
    setState(() {
      _step = 3;
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Preview only: verification is skipped until the backend is connected.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVerification = _step == 2;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 810;
            final logoTitleGap = isCompact ? 40.0 : 54.0;
            final titleSubtitleGap = isCompact ? 20.0 : 30.0;
            final subtitleProgressGap = isCompact ? 20.0 : 30.0;
            final progressFormGap = isCompact ? 32.0 : 58.0;

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
                                    onPressed: () {
                                      if (_step > 0) {
                                        setState(() {
                                          _step--;
                                          _errorMessage = null;
                                        });
                                      } else {
                                        Navigator.of(context).maybePop();
                                      }
                                    },
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
                                    disabledColor: Colors.transparent,
                                    tooltip: 'Back',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const BrandMark(size: 69),
                            SizedBox(height: logoTitleGap),
                            Text(
                              'Create your Account',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            SizedBox(height: titleSubtitleGap),
                            Text(
                              'Set up your account to start managing\nyour inSOL8 system.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontSize: 13, height: 1.25),
                            ),
                            SizedBox(height: subtitleProgressGap),
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 290,
                                ),
                                child: SignupProgress(
                                  activeStep: isVerification
                                      ? 1
                                      : (_step < 2 ? _step : _step - 1),
                                ),
                              ),
                            ),
                            SizedBox(height: progressFormGap),
                          ],
                        ),
                        Form(key: _formKey, child: _buildStepContent(context)),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              _MessageBanner(message: _errorMessage!),
                            ],
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: _buttonLabel,
                              onPressed: isVerification
                                  ? (widget.authRepository.isConfigured
                                        ? _verifyCode
                                        : _skipVerificationForPreview)
                                  : _continue,
                              isLoading: _isSubmitting || _isVerifying,
                              enabled: _hasCurrentStepInput,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SignInPrompt(onTap: _showSignInNotice),
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

  String get _buttonLabel {
    if (_step == 2) {
      return widget.authRepository.isConfigured
          ? 'Verify'
          : 'Continue (preview)';
    }
    if (_step == 4) return 'Create account';
    return 'Continue';
  }

  bool get _hasCurrentStepInput {
    switch (_step) {
      case 0:
        return _firstName.text.trim().isNotEmpty &&
            _lastName.text.trim().isNotEmpty;
      case 1:
        return _activeContact.text.trim().isNotEmpty;
      case 3:
        return _password.text.isNotEmpty && _confirmPassword.text.isNotEmpty;
      case 4:
        return _username.text.trim().isNotEmpty && _acceptedTerms;
      case 2:
        return !widget.authRepository.isConfigured ||
            _codeFields.every((field) => field.text.isNotEmpty);
      default:
        return false;
    }
  }

  Widget _buildStepContent(BuildContext context) {
    if (_step == 2) return _buildVerificationStep(context);
    switch (_step) {
      case 0:
        return _buildNameStep(context);
      case 1:
        return _buildContactStep(context);
      case 3:
        return _buildPasswordStep(context);
      case 4:
        return _buildUsernameStep(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeading(
          title: 'What’s your name?',
          description: 'Add your name so we can identify who you are.',
        ),
        const SizedBox(height: 28),
        AuthTextField(
          controller: _firstName,
          hintText: 'Enter your first name',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (value) => _requiredName(value, 'first name'),
        ),
        const SizedBox(height: 10),
        AuthTextField(
          controller: _lastName,
          hintText: 'Enter your last name',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (value) => _requiredName(value, 'last name'),
        ),
      ],
    );
  }

  Widget _buildContactStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeading(
          title: _isEmail ? 'What’s your email?' : 'What’s your mobile?',
          description: _isEmail
              ? 'Share your email where we can reach you.'
              : 'Share your mobile number where we can reach you.',
        ),
        const SizedBox(height: 28),
        if (_isEmail)
          AuthTextField(
            key: const ValueKey('signup-email-contact'),
            controller: _emailContact,
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            validator: _validateContact,
            textInputAction: TextInputAction.done,
          )
        else
          PhoneNumberField(
            key: const ValueKey('signup-mobile-contact'),
            controller: _mobileContact,
            validator: _validatePhoneNumber,
          ),
        const SizedBox(height: 16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Or you can ', style: Theme.of(context).textTheme.bodyMedium),
            TextButton(
              onPressed: () => setState(() {
                _isEmail = !_isEmail;
                _activeContact.clear();
                _formKey.currentState?.reset();
              }),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
                textStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              child: Text(
                _isEmail ? 'sign up with mobile number' : 'sign up with email',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeading(
          title: 'Create a password',
          description:
              'Create a password comprising a\nminimum 8 letters or digit',
        ),
        const SizedBox(height: 28),
        AuthPasswordField(
          controller: _password,
          hintText: 'Enter your password',
          visible: _isPasswordVisible,
          onToggleVisibility: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Enter a password.';
            if (value.length < 8) return 'Use at least 8 characters.';
            return null;
          },
        ),
        const SizedBox(height: 10),
        AuthPasswordField(
          controller: _confirmPassword,
          hintText: 'Confirm your password',
          visible: _isConfirmPasswordVisible,
          onToggleVisibility: () => setState(
            () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
          ),
          validator: (value) =>
              value != _password.text ? 'Passwords do not match.' : null,
        ),
      ],
    );
  }

  Widget _buildUsernameStep(BuildContext context) {
    final legalLinkStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.primary, fontSize: 12, height: 1.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeading(
          title: 'Create username',
          description:
              'Choose a username. You can update it\nwhenever you like',
        ),
        const SizedBox(height: 28),
        AuthTextField(
          controller: _username,
          hintText: 'Enter a username',
          textInputAction: TextInputAction.done,
          validator: (value) {
            final username = value?.trim() ?? '';
            if (username.length < 3) return 'Use at least 3 characters.';
            if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(username)) {
              return 'Use letters, numbers, dots, or underscores.';
            }
            return null;
          },
        ),
        const SizedBox(height: 52),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _acceptedTerms,
                onChanged: (value) =>
                    setState(() => _acceptedTerms = value ?? false),
                activeColor: AppColors.primary,
                side: const BorderSide(color: AppColors.fieldHint),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontSize: 12, height: 1.2),
                    children: [
                      const TextSpan(text: 'I agree with the '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Semantics(
                          link: true,
                          child: InkWell(
                            onTap: () =>
                                _openLegalDocument(LegalDocuments.terms),
                            child: Text(
                              'Terms and Conditions',
                              style: legalLinkStyle,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Semantics(
                          link: true,
                          child: InkWell(
                            onTap: () =>
                                _openLegalDocument(LegalDocuments.privacy),
                            child: Text(
                              'Privacy Policy',
                              style: legalLinkStyle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationStep(BuildContext context) {
    final description = _isEmail
        ? 'Enter the verification code we’ve sent\nto your inbox to verify your account.'
        : 'Enter the verification code we’ve sent\nto your phone to verify your account.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeading(
          title: 'Verify your ${_isEmail ? 'email' : 'mobile'}',
          description: description,
        ),
        const SizedBox(height: 28),
        VerificationCodeInput(
          controllers: _codeFields,
          focusNodes: _codeFocus,
          onChanged: (index, value) {
            if (value.isNotEmpty && index < _codeFocus.length - 1) {
              _codeFocus[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              _codeFocus[index - 1].requestFocus();
            }
          },
        ),
        const SizedBox(height: 18),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Didn’t get the code? ',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 12),
            ),
            TextButton(
              onPressed: _resendCode,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Resend it'),
            ),
          ],
        ),
      ],
    );
  }

  String? _requiredName(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Enter your $label.';
    if (value.trim().length < 2) return 'Enter at least 2 characters.';
    return null;
  }

  String? _validateContact(String? value) {
    final contact = value?.trim() ?? '';
    if (contact.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(contact)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.isEmpty) return 'Enter your mobile number.';
    if (digits.length != 10) {
      return 'Enter a valid mobile number.';
    }
    return null;
  }

  TextEditingController get _activeContact =>
      _isEmail ? _emailContact : _mobileContact;

  String get _contactForAuth {
    if (_isEmail) return _emailContact.text.trim();
    var nationalNumber = _mobileContact.text.replaceAll(RegExp(r'\D'), '');
    if (nationalNumber.startsWith('0')) {
      nationalNumber = nationalNumber.substring(1);
    }
    return '+63$nationalNumber';
  }

  Future<void> _resendCode() async {
    setState(() => _errorMessage = null);
    try {
      await widget.authRepository.resendVerificationCode(
        contact: _contactForAuth,
        method: _isEmail
            ? SignUpContactMethod.email
            : SignUpContactMethod.mobile,
      );
      if (!mounted) return;
      setState(() => _errorMessage = 'A new verification code has been sent.');
    } on AuthNotConfiguredException {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Resending will work when the backend is connected.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'We couldn’t resend the code. Please try again.',
      );
    }
  }

  void _showSignInNotice() {
    Navigator.of(context).pushNamed(AppRoutes.login);
  }

  void _openLegalDocument(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentPage(document: document),
      ),
    );
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(fontSize: 12, color: AppColors.ink),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final success =
        message == 'Your account has been verified.' ||
        message == 'A new verification code has been sent.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: success ? AppColors.field : AppColors.errorSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          height: 1.3,
          color: success ? AppColors.body : AppColors.error,
        ),
      ),
    );
  }
}
