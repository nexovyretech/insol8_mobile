import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

class SignUpStepHeading extends StatelessWidget {
  const SignUpStepHeading({
    super.key,
    required this.title,
    required this.description,
  });

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

class SignUpSignInPrompt extends StatelessWidget {
  const SignUpSignInPrompt({super.key, required this.onTap});

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

class SignUpMessageBanner extends StatelessWidget {
  const SignUpMessageBanner({super.key, required this.message});

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
