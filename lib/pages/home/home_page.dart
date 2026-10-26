import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/auth/brand_mark.dart';
import 'package:insol8_mobile/widgets/auth/primary_button.dart';

/// Signed-in landing screen; sign-in and the onboarding flow both end here.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserProfile? _profile;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    if (!await widget.authRepository.hasActiveSession()) {
      _leave();
      return;
    }
    try {
      final profile = await widget.authRepository.loadProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    await widget.authRepository.signOut();
    _leave();
  }

  void _leave() {
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.getStarted, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Center(child: BrandMark(size: 60)),
              const SizedBox(height: 36),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_profile case final profile?) ...[
                Text(
                  'Welcome, ${profile.firstName}!',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  '@${profile.username}',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (profile.email != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile.email!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ] else ...[
                Text(
                  _errorMessage ?? 'We couldn’t load your profile.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: _load, child: const Text('Try again')),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Sign out',
                onPressed: _signOut,
                isLoading: _isSigningOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
