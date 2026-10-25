import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 1.05),
            radius: 1.15,
            colors: [Color(0xFFFFBD9F), AppColors.background],
            stops: [0, 0.78],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        AppSpacing.pageVertical,
                        AppSpacing.pageHorizontal,
                        AppSpacing.pageVertical,
                      ),
                      child: Column(
                        children: [
                          const Spacer(),
                          SvgPicture.asset(
                            'assets/logo/getstarted_logo.svg',
                            width: 180,
                            fit: BoxFit.contain,
                            semanticsLabel: 'inSOL8',
                          ),
                          const Spacer(),
                          Text(
                            'A Smarter Way to Dry',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontSize: 21),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Manage your drying system with stored\n'
                            'solar heat, real-time monitoring, and\n'
                            'better energy control.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 28),
                          _WelcomeActionButton(
                            label: 'Create Account',
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.signUp),
                            gradient: const [
                              AppColors.primary,
                              Color(0xFFB94220),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _WelcomeActionButton(
                            label: 'Sign In',
                            foregroundColor: AppColors.ink,
                            backgroundColor: AppColors.surface,
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.login),
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
      ),
    );
  }
}

class _WelcomeActionButton extends StatelessWidget {
  const _WelcomeActionButton({
    required this.label,
    required this.onPressed,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
  });

  final String label;
  final VoidCallback onPressed;
  final List<Color>? gradient;
  final Color? backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: gradient == null ? null : LinearGradient(colors: gradient!),
          borderRadius: BorderRadius.circular(16),
          boxShadow: backgroundColor == null
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x18A93415),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
