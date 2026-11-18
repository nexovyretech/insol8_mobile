// The password rules every new password must meet: sign-up, forgot
// password, and Create/Update password in Settings. They mirror the Cognito
// user pool policy (infra/resources/cognito.yaml in insol8-backend: 8+
// characters with an uppercase letter, a lowercase letter, and a number), so
// a password that passes here is never rejected after a code is spent.

/// One requirement, shown as a line in the live checklist.
class PasswordRule {
  const PasswordRule(this.label, this.isMet);

  final String label;
  final bool Function(String password) isMet;
}

final passwordRules = <PasswordRule>[
  PasswordRule('At least 8 characters', (value) => value.length >= 8),
  PasswordRule(
    'An uppercase letter',
    (value) => value.contains(RegExp('[A-Z]')),
  ),
  PasswordRule(
    'A lowercase letter',
    (value) => value.contains(RegExp('[a-z]')),
  ),
  PasswordRule('A number', (value) => value.contains(RegExp(r'\d'))),
];

bool meetsPasswordRules(String password) =>
    passwordRules.every((rule) => rule.isMet(password));

/// The message for a password that can't be used, or null when it can.
/// Spaces at the ends aren't a checklist line: Cognito rejects them with a
/// generic error, so they get their own message.
String? passwordProblem(String password) {
  if (password.isEmpty) return 'Enter a password.';
  if (!meetsPasswordRules(password)) {
    return 'Your password doesn’t meet all the requirements yet.';
  }
  if (password.trim() != password) {
    return 'Your password can’t start or end with a space.';
  }
  return null;
}
