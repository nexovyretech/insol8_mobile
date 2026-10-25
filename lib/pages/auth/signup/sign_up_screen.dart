import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/sign_up_data.dart';
import 'package:insol8_mobile/models/legal_document.dart';
import 'package:insol8_mobile/pages/auth/signup/signup_shared_widgets.dart';
import 'package:insol8_mobile/pages/auth/signup/signup_step_widgets.dart';
import 'package:insol8_mobile/pages/legal/legal_document_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/auth/brand_mark.dart';
import 'package:insol8_mobile/widgets/auth/primary_button.dart';
import 'package:insol8_mobile/widgets/auth/signup_progress.dart';

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
                              SignUpMessageBanner(message: _errorMessage!),
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
                              child: SignUpSignInPrompt(
                                onTap: _showSignInNotice,
                              ),
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
    switch (_step) {
      case 0:
        return SignUpNameStep(
          firstNameController: _firstName,
          lastNameController: _lastName,
          validateFirstName: (value) => _requiredName(value, 'first name'),
          validateLastName: (value) => _requiredName(value, 'last name'),
        );
      case 1:
        return SignUpContactStep(
          isEmail: _isEmail,
          emailController: _emailContact,
          mobileController: _mobileContact,
          validateEmail: _validateContact,
          validateMobile: _validatePhoneNumber,
          onToggleMethod: () => setState(() {
            _isEmail = !_isEmail;
            _activeContact.clear();
            _formKey.currentState?.reset();
          }),
        );
      case 2:
        return SignUpVerificationStep(
          isEmail: _isEmail,
          codeControllers: _codeFields,
          codeFocusNodes: _codeFocus,
          onCodeChanged: (index, value) {
            if (value.isNotEmpty && index < _codeFocus.length - 1) {
              _codeFocus[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              _codeFocus[index - 1].requestFocus();
            }
          },
          onResendCode: _resendCode,
        );
      case 3:
        return SignUpPasswordStep(
          passwordController: _password,
          confirmPasswordController: _confirmPassword,
          passwordVisible: _isPasswordVisible,
          confirmPasswordVisible: _isConfirmPasswordVisible,
          onTogglePasswordVisibility: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
          onToggleConfirmPasswordVisibility: () => setState(
            () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
          ),
          validatePassword: (value) {
            if (value == null || value.isEmpty) return 'Enter a password.';
            if (value.length < 8) return 'Use at least 8 characters.';
            return null;
          },
          validateConfirmPassword: (value) =>
              value != _password.text ? 'Passwords do not match.' : null,
        );
      case 4:
        return SignUpUsernameStep(
          usernameController: _username,
          acceptedTerms: _acceptedTerms,
          onTermsChanged: (value) => setState(() => _acceptedTerms = value),
          onOpenLegalDocument: _openLegalDocument,
          validateUsername: (value) {
            final username = value?.trim() ?? '';
            if (username.length < 3) return 'Use at least 3 characters.';
            if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(username)) {
              return 'Use letters, numbers, dots, or underscores.';
            }
            return null;
          },
        );
      default:
        return const SizedBox.shrink();
    }
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
