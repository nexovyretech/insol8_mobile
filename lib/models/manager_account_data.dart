import 'package:insol8_mobile/utils/phone_number.dart';

/// Contact details entered for a branch manager before the branch is saved.
///
/// The backend has no separate manager-invite endpoint yet and its branch
/// whitelist does not accept contact fields, so these stay in the UI only.
enum ManagerContactMethod { email, mobile }

class ManagerAccountData {
  const ManagerAccountData({
    required this.firstName,
    required this.lastName,
    required this.contactMethod,
    required this.contact,
  });

  final String firstName;
  final String lastName;
  final ManagerContactMethod contactMethod;

  /// Email address, or the mobile number exactly as typed in the field.
  final String contact;

  String get fullName => '$firstName $lastName';

  String? get email =>
      contactMethod == ManagerContactMethod.email ? contact.trim() : null;

  String? get mobileNumber => contactMethod == ManagerContactMethod.mobile
      ? normalizePhilippineMobile(contact)
      : null;

  /// Contact shown after the account is created, exactly as it was entered.
  String get displayContact => contact.trim();

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    if (contactMethod == ManagerContactMethod.email) 'email': email,
    if (contactMethod == ManagerContactMethod.mobile)
      'mobileNumber': mobileNumber,
  };
}
