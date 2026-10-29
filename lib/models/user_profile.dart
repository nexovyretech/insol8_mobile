class UserProfile {
  const UserProfile({
    required this.username,
    required this.firstName,
    required this.lastName,
    this.email,
    this.mobileNumber,
    this.id,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    username: json['username'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String?,
    mobileNumber: json['mobileNumber'] as String?,
    id: json['id'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );

  final String username;
  final String firstName;
  final String lastName;
  final String? email;
  final String? mobileNumber;

  /// The profile's UUID in Neon, shown as the account's User ID.
  final String? id;

  /// When the profile was created ("Member Since").
  final DateTime? createdAt;

  UserProfile copyWith({
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? mobileNumber,
  }) => UserProfile(
    username: username ?? this.username,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    id: id,
    createdAt: createdAt,
  );

  String get fullName => '$firstName $lastName';
}
