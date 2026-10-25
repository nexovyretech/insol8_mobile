import 'package:flutter/material.dart';

import 'package:insol8_mobile/constants/legal_documents.dart';
import 'package:insol8_mobile/models/legal_document.dart';
import 'package:insol8_mobile/pages/auth/signup/signup_shared_widgets.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/widgets/auth/auth_password_field.dart';
import 'package:insol8_mobile/widgets/auth/auth_text_field.dart';
import 'package:insol8_mobile/widgets/auth/phone_number_field.dart';
import 'package:insol8_mobile/widgets/auth/verification_code_input.dart';

class SignUpNameStep extends StatelessWidget {
  const SignUpNameStep({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.validateFirstName,
    required this.validateLastName,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final FormFieldValidator<String> validateFirstName;
  final FormFieldValidator<String> validateLastName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignUpStepHeading(
          title: 'What’s your name?',
          description: 'Add your name so we can identify who you are.',
        ),
        const SizedBox(height: 28),
        AuthTextField(
          controller: firstNameController,
          hintText: 'Enter your first name',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: validateFirstName,
        ),
        const SizedBox(height: 10),
        AuthTextField(
          controller: lastNameController,
          hintText: 'Enter your last name',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: validateLastName,
        ),
      ],
    );
  }
}

class SignUpContactStep extends StatelessWidget {
  const SignUpContactStep({
    super.key,
    required this.isEmail,
    required this.emailController,
    required this.mobileController,
    required this.validateEmail,
    required this.validateMobile,
    required this.onToggleMethod,
  });

  final bool isEmail;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validateMobile;
  final VoidCallback onToggleMethod;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SignUpStepHeading(
          title: isEmail ? 'What’s your email?' : 'What’s your mobile?',
          description: isEmail
              ? 'Share your email where we can reach you.'
              : 'Share your mobile number where we can reach you.',
        ),
        const SizedBox(height: 28),
        if (isEmail)
          AuthTextField(
            key: const ValueKey('signup-email-contact'),
            controller: emailController,
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
            textInputAction: TextInputAction.done,
          )
        else
          PhoneNumberField(
            key: const ValueKey('signup-mobile-contact'),
            controller: mobileController,
            validator: validateMobile,
          ),
        const SizedBox(height: 16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Or you can ', style: Theme.of(context).textTheme.bodyMedium),
            TextButton(
              onPressed: onToggleMethod,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
                textStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              child: Text(
                isEmail ? 'sign up with mobile number' : 'sign up with email',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SignUpPasswordStep extends StatelessWidget {
  const SignUpPasswordStep({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    required this.validatePassword,
    required this.validateConfirmPassword,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignUpStepHeading(
          title: 'Create a password',
          description:
              'Use at least 8 characters with an uppercase\nletter, a lowercase letter, and a number.',
        ),
        const SizedBox(height: 28),
        AuthPasswordField(
          controller: passwordController,
          hintText: 'Enter your password',
          visible: passwordVisible,
          onToggleVisibility: onTogglePasswordVisibility,
          textInputAction: TextInputAction.next,
          validator: validatePassword,
        ),
        const SizedBox(height: 10),
        AuthPasswordField(
          controller: confirmPasswordController,
          hintText: 'Confirm your password',
          visible: confirmPasswordVisible,
          onToggleVisibility: onToggleConfirmPasswordVisibility,
          validator: validateConfirmPassword,
        ),
      ],
    );
  }
}

class SignUpUsernameStep extends StatelessWidget {
  const SignUpUsernameStep({
    super.key,
    required this.usernameController,
    required this.acceptedTerms,
    required this.onTermsChanged,
    required this.onOpenLegalDocument,
    required this.validateUsername,
  });

  final TextEditingController usernameController;
  final bool acceptedTerms;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<LegalDocument> onOpenLegalDocument;
  final FormFieldValidator<String> validateUsername;

  @override
  Widget build(BuildContext context) {
    final legalLinkStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.primary, fontSize: 12, height: 1.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignUpStepHeading(
          title: 'Create username',
          description:
              'Choose a username. You can update it\nwhenever you like',
        ),
        const SizedBox(height: 28),
        AuthTextField(
          controller: usernameController,
          hintText: 'Enter a username',
          textInputAction: TextInputAction.done,
          validator: validateUsername,
        ),
        const SizedBox(height: 52),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: acceptedTerms,
                onChanged: (value) => onTermsChanged(value ?? false),
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
                                onOpenLegalDocument(LegalDocuments.terms),
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
                                onOpenLegalDocument(LegalDocuments.privacy),
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
}

class SignUpVerificationStep extends StatelessWidget {
  const SignUpVerificationStep({
    super.key,
    required this.isEmail,
    required this.codeControllers,
    required this.codeFocusNodes,
    required this.onCodeChanged,
    required this.onResendCode,
  });

  final bool isEmail;
  final List<TextEditingController> codeControllers;
  final List<FocusNode> codeFocusNodes;
  final void Function(int index, String value) onCodeChanged;
  final VoidCallback onResendCode;

  @override
  Widget build(BuildContext context) {
    final description = isEmail
        ? 'Enter the verification code we’ve sent\nto your inbox to verify your account.'
        : 'Enter the verification code we’ve sent\nto your phone to verify your account.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SignUpStepHeading(
          title: 'Verify your ${isEmail ? 'email' : 'mobile'}',
          description: description,
        ),
        const SizedBox(height: 28),
        VerificationCodeInput(
          controllers: codeControllers,
          focusNodes: codeFocusNodes,
          onChanged: onCodeChanged,
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
              onPressed: onResendCode,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
                // Theme-derived like the contact step's link, so the switch
                // between steps can animate the style without an assertion.
                textStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
              child: const Text('Resend it'),
            ),
          ],
        ),
      ],
    );
  }
}
