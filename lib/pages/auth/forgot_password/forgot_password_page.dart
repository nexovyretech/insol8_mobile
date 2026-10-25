import 'package:flutter/material.dart';

import 'package:insol8_mobile/pages/auth/forgot_password/forgot_password_view.dart';
import 'package:insol8_mobile/services/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _identifierController = TextEditingController();
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Cognito recovers accounts by verified email only, so email is the default.
  bool _isEmail = true;
  bool _isCodeStep = false;
  bool _isNewPasswordStep = false;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_handleInputChanged);
    for (final controller in _codeControllers) {
      controller.addListener(_handleInputChanged);
    }
    _passwordController.addListener(_handleInputChanged);
    _confirmPasswordController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _identifierController
      ..removeListener(_handleInputChanged)
      ..dispose();
    for (final controller in _codeControllers) {
      controller
        ..removeListener(_handleInputChanged)
        ..dispose();
    }
    _passwordController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_handleInputChanged)
      ..dispose();
    for (final focusNode in _codeFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleInputChanged() {
    if (mounted) setState(() {});
  }

  bool get _isIdentifierValid {
    final value = _identifierController.text.trim();
    if (_isEmail) {
      return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
    }
    return value.replaceAll(RegExp(r'\D'), '').length == 10;
  }

  String get _identifierForAuth {
    final value = _identifierController.text.trim();
    if (_isEmail) return value;
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+63$digits';
  }

  bool get _hasCompleteCode =>
      _codeControllers.every((controller) => controller.text.isNotEmpty);

  bool get _canSetPassword =>
      _passwordController.text.length >= 8 &&
      _passwordController.text == _confirmPasswordController.text;

  /// Mirrors the Cognito pool policy so most mistakes are caught before
  /// the code is spent.
  String? get _passwordPolicyError {
    final value = _passwordController.text;
    if (value.length < 8) {
      return 'Use at least 8 characters for your new password.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'\d').hasMatch(value)) {
      return 'Include an uppercase letter, a lowercase letter, and a number.';
    }
    return null;
  }

  Future<void> _sendCode() async {
    if (!_isIdentifierValid) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.requestPasswordReset(
        identifier: _identifierForAuth,
      );
      if (!mounted) return;
      for (final controller in _codeControllers) {
        controller.clear();
      }
      setState(() => _isCodeStep = true);
      // Same wording whether or not the account exists.
      _showMessage('If an account uses that email, we’ve sent it a code.');
    } on AuthFailure catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } on AuthNotConfiguredException {
      if (!mounted) return;
      setState(() => _isCodeStep = true);
      _showMessage(
        'Preview only: code delivery will work when the backend is connected.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('We couldn’t send a code. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    try {
      await widget.authRepository.resendPasswordResetCode(
        identifier: _identifierForAuth,
      );
      if (!mounted) return;
      _showMessage('If an account uses that email, we’ve sent it a new code.');
    } on AuthFailure catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } on AuthNotConfiguredException {
      if (!mounted) return;
      _showMessage(
        'Preview only: resend will work when the backend is connected.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('We couldn’t resend the code. Please try again.');
    }
  }

  String get _code =>
      _codeControllers.map((controller) => controller.text).join();

  void _clearCode() {
    for (final controller in _codeControllers) {
      controller.clear();
    }
    _codeFocusNodes.first.requestFocus();
  }

  /// Checks the code with Cognito before showing the new password fields;
  /// a wrong or expired code keeps the user on this screen.
  Future<void> _verifyCode() async {
    if (!_hasCompleteCode) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.verifyPasswordResetCode(
        identifier: _identifierForAuth,
        code: _code,
      );
      if (!mounted) return;
      setState(() {
        _isCodeStep = false;
        _isNewPasswordStep = true;
      });
    } on AuthFailure catch (error) {
      if (!mounted) return;
      if (error.isCodeError) _clearCode();
      _showMessage(error.message);
    } on AuthNotConfiguredException {
      if (!mounted) return;
      setState(() {
        _isCodeStep = false;
        _isNewPasswordStep = true;
      });
      _showMessage(
        'Preview only: showing the new password step. Code verification needs the backend.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('That code could not be verified. Check it and try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _setNewPassword() async {
    final policyError = _passwordPolicyError;
    if (policyError != null) {
      _showMessage(policyError);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.resetPassword(
        identifier: _identifierForAuth,
        code: _code,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      _showMessage('Your password has been updated. Sign in with your new password.');
      Navigator.of(context).pop();
    } on AuthFailure catch (error) {
      if (!mounted) return;
      if (error.isCodeError) {
        // The code expired while the user was choosing a password.
        setState(() {
          _isNewPasswordStep = false;
          _isCodeStep = true;
        });
        _clearCode();
      }
      _showMessage(error.message);
    } on AuthNotConfiguredException {
      if (!mounted) return;
      _showMessage('Password reset is ready once the backend is connected.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('We couldn’t reset your password. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goBack() {
    if (_isNewPasswordStep) {
      setState(() {
        _isNewPasswordStep = false;
        _isCodeStep = true;
      });
      return;
    }
    if (_isCodeStep) {
      setState(() {
        _isCodeStep = false;
      });
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordView(
      identifierController: _identifierController,
      codeControllers: _codeControllers,
      codeFocusNodes: _codeFocusNodes,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      isEmail: _isEmail,
      isCodeStep: _isCodeStep,
      isNewPasswordStep: _isNewPasswordStep,
      isSubmitting: _isSubmitting,
      passwordVisible: _passwordVisible,
      confirmPasswordVisible: _confirmPasswordVisible,
      description: _description,
      isIdentifierValid: _isIdentifierValid,
      hasCompleteCode: _hasCompleteCode,
      canSetPassword: _canSetPassword,
      onBack: _goBack,
      onToggleEmail: () => setState(() {
        _isEmail = !_isEmail;
        _identifierController.clear();
      }),
      onCodeChanged: (index, value) {
        if (value.isNotEmpty && index < _codeFocusNodes.length - 1) {
          _codeFocusNodes[index + 1].requestFocus();
        } else if (value.isEmpty && index > 0) {
          _codeFocusNodes[index - 1].requestFocus();
        }
      },
      onResendCode: _resendCode,
      onTogglePasswordVisibility: () =>
          setState(() => _passwordVisible = !_passwordVisible),
      onToggleConfirmPasswordVisibility: () =>
          setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
      onSendCode: _sendCode,
      onVerifyCode: _verifyCode,
      onSetNewPassword: _setNewPassword,
      onContactSupport: () =>
          _showMessage('Contact the inSOL8 support team for account help.'),
    );
  }

  String get _description {
    if (_isNewPasswordStep) {
      return 'Use at least 8 characters with an uppercase\nletter, a lowercase letter, and a number.';
    }
    if (!_isCodeStep) {
      return _isEmail
          ? 'Enter the email associated with your\naccount and we’ll send you a code.'
          : 'Enter the mobile associated with your\naccount and we’ll send you a code.';
    }
    return 'Enter the 6-digit code we sent to your\n${_isEmail ? 'email.' : 'phone.'}';
  }
}
