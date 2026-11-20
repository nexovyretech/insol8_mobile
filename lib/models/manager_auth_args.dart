/// Invitation details carried by the manager activation deep link.
///
/// The invite is delivered outside the app (email or SMS), so these values are
/// optional: the Figma activation frames only ask for a password and username.
class ManagerAuthArgs {
  const ManagerAuthArgs({this.contact, this.isEmail = true});

  final String? contact;
  final bool isEmail;

  static ManagerAuthArgs from(Object? arguments) {
    // Match any Map so a Map<String, String> literal cannot break navigation.
    if (arguments is Map) {
      return ManagerAuthArgs(
        contact: arguments['contact'] as String?,
        isEmail: arguments['isEmail'] as bool? ?? true,
      );
    }
    final contact = arguments as String?;
    return ManagerAuthArgs(
      contact: contact,
      isEmail: contact == null || !contact.startsWith('+'),
    );
  }

  Map<String, dynamic> toMap() => {'contact': ?contact, 'isEmail': isEmail};
}
