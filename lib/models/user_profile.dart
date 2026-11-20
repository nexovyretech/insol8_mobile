/// The account's role in the first Settings page. Owners see billing and
/// subscription rows; managers only see their personal/support rows.
enum AccountRole { owner, manager }

class UserProfile {
  const UserProfile({
    required this.username,
    required this.firstName,
    required this.lastName,
    this.email,
    this.mobileNumber,
    this.googleEmail,
    this.id,
    this.createdAt,
    this.role = AccountRole.owner,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    username: json['username'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String?,
    mobileNumber: json['mobileNumber'] as String?,
    googleEmail: json['googleEmail'] as String?,
    id: json['id'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    role: _roleFromJson(json),
  );

  final String username;
  final String firstName;
  final String lastName;
  final String? email;
  final String? mobileNumber;

  /// The Google account that "Continue with Google" signs in to, if any.
  final String? googleEmail;

  /// The profile's UUID in Neon, shown as the account's User ID.
  final String? id;

  /// When the profile was created ("Member Since").
  final DateTime? createdAt;

  /// Owner is the fallback so profiles saved before roles existed keep the
  /// existing Settings rows.
  final AccountRole role;

  UserProfile copyWith({
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? mobileNumber,
    AccountRole? role,
  }) => UserProfile(
    username: username ?? this.username,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    googleEmail: googleEmail,
    id: id,
    createdAt: createdAt,
    role: role ?? this.role,
  );

  String get fullName => '$firstName $lastName';
}

/// Accepts the common role spellings returned by the API. Anything unrecognized
/// is treated as an owner, which preserves the previous app behavior.
AccountRole _roleFromJson(Map<String, dynamic> json) {
  final raw =
      json['role'] ??
      json['accountRole'] ??
      json['userType'] ??
      json['isManager'];
  if (raw is bool) return raw ? AccountRole.manager : AccountRole.owner;
  final value = raw?.toString().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  if (value == 'manager' ||
      value == 'branchmanager' ||
      value == 'storemanager' ||
      value == 'staff') {
    return AccountRole.manager;
  }
  return AccountRole.owner;
}
