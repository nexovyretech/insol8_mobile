// Rules for the profile fields people type, shared by sign-up and Account
// Profile so both accept exactly the same values. Each returns the message
// to show, or null when the value can be used.

/// Letters in any language (ñ, é, ...), with spaces, hyphens, apostrophes,
/// and periods between them: "De La Cruz", "O'Neil", "Ma. Theresa". No
/// numbers or other symbols. Kept in sync with NAME_PATTERN in
/// insol8-backend/src/services/users-service.js.
final _namePattern = RegExp(r"^\p{L}[\p{L}\p{M} .'\-]*$", unicode: true);

String? nameProblem(String value, String label) {
  final name = value.trim();
  if (name.isEmpty) return 'Enter your $label.';
  if (name.length < 2) return 'Enter at least 2 characters.';
  if (name.length > 50) return 'Use 50 characters or fewer.';
  if (!_namePattern.hasMatch(name)) {
    return 'Use letters only. Spaces, hyphens (-), apostrophes (\'), and '
        'periods (.) are allowed.';
  }
  return null;
}

String? usernameProblem(String value) {
  final username = value.trim();
  if (username.length < 3) return 'Use at least 3 characters.';
  if (username.length > 40) return 'Use 40 characters or fewer.';
  if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(username)) {
    return 'Use letters, numbers, dots, or underscores.';
  }
  return null;
}

String? emailProblem(String value) {
  final email = value.trim();
  if (email.isEmpty) return 'Enter your email address.';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}
