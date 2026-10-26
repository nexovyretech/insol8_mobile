import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/auth/auth_password_field.dart';
import 'package:insol8_mobile/widgets/auth/auth_text_field.dart';
import 'package:insol8_mobile/widgets/auth/brand_mark.dart';
import 'package:insol8_mobile/widgets/auth/phone_number_field.dart';
import 'package:insol8_mobile/widgets/auth/primary_button.dart';
import 'package:insol8_mobile/widgets/auth/verification_code_input.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({
    super.key,
    required this.identifierController,
    required this.codeControllers,
    required this.codeFocusNodes,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isEmail,
    required this.isCodeStep,
    required this.isNewPasswordStep,
    required this.isSubmitting,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.description,
    required this.isIdentifierValid,
    required this.hasCompleteCode,
    required this.canSetPassword,
    this.passwordError,
    required this.onBack,
    required this.onToggleEmail,
    required this.onCodeChanged,
    required this.onResendCode,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    required this.onSendCode,
    required this.onVerifyCode,
    required this.onSetNewPassword,
    required this.onContactSupport,
  });

  final TextEditingController identifierController;
  final List<TextEditingController> codeControllers;
  final List<FocusNode> codeFocusNodes;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isEmail;
  final bool isCodeStep;
  final bool isNewPasswordStep;
  final bool isSubmitting;
  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final String description;
  final bool isIdentifierValid;
  final bool hasCompleteCode;
  final bool canSetPassword;

  /// Shown under the new-password fields, e.g. "Passwords do not match."
  final String? passwordError;
  final VoidCallback onBack;
  final VoidCallback onToggleEmail;
  final void Function(int index, String value) onCodeChanged;
  final VoidCallback onResendCode;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final VoidCallback onSendCode;
  final VoidCallback onVerifyCode;
  final VoidCallback onSetNewPassword;
  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
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
                      onPressed: onBack,
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
                    const Center(child: BrandMark(size: 64)),
                    const SizedBox(height: 42),
                    Center(
                      child: Text(
                        isNewPasswordStep
                            ? 'New Password'
                            : isCodeStep
                            ? 'Verify your ${isEmail ? 'email' : 'mobile'}'
                            : 'Forgot Password',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 56),
                    if (isCodeStep) ...[
                      VerificationCodeInput(
                        controllers: codeControllers,
                        focusNodes: codeFocusNodes,
                        onChanged: onCodeChanged,
                      ),
                      const SizedBox(height: 12),
                      _InlineAction(
                        prefix: 'Didn’t receive the code? ',
                        action: 'Resend',
                        onPressed: onResendCode,
                      ),
                    ] else if (isNewPasswordStep) ...[
                      AuthPasswordField(
                        controller: passwordController,
                        hintText: 'Enter your password',
                        visible: passwordVisible,
                        onToggleVisibility: onTogglePasswordVisibility,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      AuthPasswordField(
                        controller: confirmPasswordController,
                        hintText: 'Confirm your password',
                        visible: confirmPasswordVisible,
                        onToggleVisibility: onToggleConfirmPasswordVisibility,
                      ),
                      if (passwordError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          passwordError!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 12, color: AppColors.error),
                        ),
                      ],
                    ] else ...[
                      if (isEmail)
                        AuthTextField(
                          controller: identifierController,
                          hintText: 'Enter your email address',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                        )
                      else
                        PhoneNumberField(
                          controller: identifierController,
                          hintText: 'Enter mobile number',
                          validator: (_) => null,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Want to use your ${isEmail ? 'mobile number' : 'email address'} instead?',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontSize: 12),
                      ),
                      TextButton(
                        onPressed: onToggleEmail,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: Text(
                          'Use ${isEmail ? 'mobile number' : 'email address'}',
                        ),
                      ),
                    ],
                    const SizedBox(height: 64),
                    PrimaryButton(
                      label: isNewPasswordStep
                          ? 'Set New Password'
                          : isCodeStep
                          ? 'Verify'
                          : 'Send Code',
                      onPressed: isNewPasswordStep
                          ? onSetNewPassword
                          : isCodeStep
                          ? onVerifyCode
                          : onSendCode,
                      enabled: isNewPasswordStep
                          ? canSetPassword
                          : isCodeStep
                          ? hasCompleteCode
                          : isIdentifierValid,
                      isLoading: isSubmitting,
                    ),
                    const SizedBox(height: 36),
                    const Divider(height: 1, color: AppColors.inactive),
                    const SizedBox(height: 24),
                    Text(
                      'Need help?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'If you’re having trouble accessing your account, contact the inSOL8 support team.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: onContactSupport,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Contact Support'),
                    ),
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

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.prefix,
    required this.action,
    required this.onPressed,
  });

  final String prefix;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prefix,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: Text(action),
        ),
      ],
    );
  }
}
