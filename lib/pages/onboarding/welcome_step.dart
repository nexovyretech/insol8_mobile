import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({
    super.key,
    required this.title,
    required this.description,
    required this.pageIndex,
    required this.buttonLabel,
    required this.onContinue,
  });

  final String title;
  final String description;
  final int pageIndex;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBack: false,
      // The logo fills spare height; on very short screens the content
      // scrolls and the button stays pinned.
      child: OnboardingStickyLayout(
        fillViewport: true,
        crossAxisAlignment: CrossAxisAlignment.center,
        content: [
          Expanded(
            child: Center(
              child: SvgPicture.asset(
                'assets/logo/getstarted_logo.svg',
                width: 190,
                fit: BoxFit.contain,
                semanticsLabel: 'inSOL8',
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              final active = index == pageIndex;
              return Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : AppColors.fieldHint,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 60,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 22, height: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 72,
            child: Center(
              child: Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        actions: [
          SizedBox(
            width: double.infinity,
            child: OnboardingGradientButton(
              label: buttonLabel,
              trailingIcon: Icons.chevron_right,
              height: 52,
              borderRadius: 16,
              fontSize: 15,
              gradientColors: const [AppColors.primary, Color(0xFFB94220)],
              onPressed: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}
