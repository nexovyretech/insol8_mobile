import 'package:flutter/material.dart';

import 'package:insol8_mobile/pages/onboarding/branch_setup_style.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_text_field.dart';
import 'package:insol8_mobile/pages/onboarding/onboarding_shared_widgets.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/utils/phone_number.dart';
import 'package:insol8_mobile/utils/profile_rules.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';
import 'package:insol8_mobile/widgets/auth/phone_number_field.dart';

/// The "Create manager account" screen shown after choosing "Add a new
/// manager". The invitation is created with the branch when the owner taps
/// Finish Setup, so the contact details are stored in [BranchSetupData].
class OnboardingManagerAccountStep extends StatelessWidget {
  const OnboardingManagerAccountStep({
    super.key,
    required this.onBack,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.mobileController,
    required this.isEmail,
    required this.onContactMethodChanged,
    required this.onFieldChanged,
    required this.onCreateAccount,
    this.isSaving = false,
  });

  final VoidCallback onBack;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final bool isEmail;
  final ValueChanged<bool> onContactMethodChanged;
  final VoidCallback onFieldChanged;
  final VoidCallback onCreateAccount;
  final bool isSaving;

  String? _mobileProblem(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Enter your mobile number.';
    return normalizePhilippineMobile(value!) == null
        ? 'Enter a valid mobile number.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final canCreate =
        nameProblem(firstNameController.text, 'first name') == null &&
        nameProblem(lastNameController.text, 'last name') == null &&
        (isEmail
            ? emailProblem(emailController.text) == null
            : _mobileProblem(mobileController.text) == null);

    return OnboardingScaffold(
      showBack: false,
      showGradient: false,
      topPadding: AppSpacing.pageHeaderTop,
      bottomPadding: AppSpacing.branchSetupBottom,
      headerSlotHeight: 0,
      child: OnboardingStickyLayout(
        header: AppInnerPageHeader(
          title: 'Branch Setup',
          onBack: onBack,
          titleColor: BranchSetupPalette.ink,
          iconColor: BranchSetupPalette.ink,
        ),
        content: [
          const SizedBox(height: 8),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create manager account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BranchSetupPalette.ink,
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create an account your branch manager can sign in with. '
                  'They will set their own password from the invitation.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: BranchSetupPalette.body, fontSize: 12),
                ),
                const SizedBox(height: 22),
                const OnboardingSectionLabel(
                  'Manager Name',
                  color: BranchSetupPalette.sectionLabel,
                ),
                const SizedBox(height: 12),
                BranchSetupTextField(
                  controller: firstNameController,
                  hint: 'First name',
                  capitalization: TextCapitalization.words,
                  onChanged: onFieldChanged,
                  validator: (value) => nameProblem(value ?? '', 'first name'),
                ),
                const SizedBox(height: 12),
                BranchSetupTextField(
                  controller: lastNameController,
                  hint: 'Last name',
                  capitalization: TextCapitalization.words,
                  onChanged: onFieldChanged,
                  validator: (value) => nameProblem(value ?? '', 'last name'),
                ),
                const SizedBox(height: 20),
                OnboardingSectionLabel(
                  isEmail ? 'Email Address' : 'Mobile Number',
                  color: BranchSetupPalette.sectionLabel,
                ),
                const SizedBox(height: 12),
                if (isEmail)
                  BranchSetupTextField(
                    controller: emailController,
                    hint: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: onFieldChanged,
                    validator: (value) => emailProblem(value ?? ''),
                  )
                else
                  BranchSetupTextField(
                    key: const ValueKey('manager-mobile'),
                    controller: mobileController,
                    hint: 'Mobile number',
                    keyboardType: TextInputType.phone,
                    inputFormatters: const [
                      PhoneNumberInputFormatter(
                        groupLengths: [3, 3, 4],
                        maxDigits: 10,
                      ),
                    ],
                    onChanged: onFieldChanged,
                    validator: _mobileProblem,
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const ValueKey('manager-contact-toggle'),
                    onPressed: () => onContactMethodChanged(!isEmail),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: BranchSetupPalette.ink,
                      overlayColor: Colors.transparent,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Or you can sign up with ',
                            style: const TextStyle(
                              color: BranchSetupPalette.ink,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: isEmail ? 'mobile number' : 'email',
                            style: const TextStyle(
                              color: BranchSetupPalette.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const OnboardingSectionLabel(
                  'Account Credentials',
                  color: BranchSetupPalette.sectionLabel,
                ),
                const SizedBox(height: 12),
                Text(
                  'The manager will receive an invitation to set up their '
                  'password.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: BranchSetupPalette.body, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(
                  'You can add more branches, change addresses, or reassign '
                  'store managers anytime in your Account Settings.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: BranchSetupPalette.body, fontSize: 12),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
        actions: [
          OnboardingGradientButton(
            label: isSaving ? 'Creating…' : 'Create Account',
            onPressed: canCreate && !isSaving ? onCreateAccount : null,
            gradientColors: const [
              BranchSetupPalette.orange,
              BranchSetupPalette.orange,
            ],
            disabledColor: BranchSetupPalette.disabled,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
