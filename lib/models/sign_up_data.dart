enum SignUpContactMethod { email, mobile }

class SignUpData {
  const SignUpData({
    required this.firstName,
    required this.lastName,
    required this.contact,
    required this.contactMethod,
    required this.password,
    required this.username,
    required this.termsAccepted,
  });

  final String firstName;
  final String lastName;
  final String contact;
  final SignUpContactMethod contactMethod;
  final String password;
  final String username;
  final bool termsAccepted;
}
