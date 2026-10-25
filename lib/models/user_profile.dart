class UserProfile {
  const UserProfile({
    required this.username,
    required this.firstName,
    required this.lastName,
    this.email,
    this.mobileNumber,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    username: json['username'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String?,
    mobileNumber: json['mobileNumber'] as String?,
  );

  final String username;
  final String firstName;
  final String lastName;
  final String? email;
  final String? mobileNumber;

  String get fullName => '$firstName $lastName';
}
