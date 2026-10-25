import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

class LoginFieldLabel extends StatelessWidget {
  const LoginFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
  );
}

class LoginOrDivider extends StatelessWidget {
  const LoginOrDivider({super.key});

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

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

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
