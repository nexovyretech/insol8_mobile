// Philippine mobile number helpers shared by sign-up and Account Profile.

/// Returns +639XXXXXXXXX for "917 123 4567", "0917…", "63917…" or
/// "+63917…", or null when it is not a Philippine mobile number.
String? normalizePhilippineMobile(String value) {
  final digits = value.replaceAll(RegExp(r'[\s()-]'), '');
  final match = RegExp(r'^(?:\+63|63|0)?(9\d{9})$').firstMatch(digits);
  return match == null ? null : '+63${match.group(1)}';
}

/// "+639171234567" → "+63 917 123 4567"; anything else is returned as is.
String formatPhilippineMobile(String phone) {
  final match = RegExp(r'^\+63(9\d{2})(\d{3})(\d{4})$').firstMatch(phone);
  return match == null
      ? phone
      : '+63 ${match.group(1)} ${match.group(2)} ${match.group(3)}';
}

/// Prefixes (the 3 digits after +63) of Smart, TNT, and Sun, which runs on
/// Smart's network. The SMS provider's shared sender no longer reaches these
/// networks, so verification codes to them never arrive. Ported numbers keep
/// their old prefix, so this is a best guess. Kept in sync with
/// src/lib/phone.js in insol8-backend, which rejects the same numbers.
const _smartNetworkPrefixes = {
  '907', '908', '909', '910', '911', '912', '913', '914', '918', '919', //
  '920', '921', '928', '929', '930', '938', '939', '940', '946', '947',
  '948', '949', '950', '951', '961', '963', '968', '969', '970', '981',
  '989', '998', '999',
  // Sun
  '922', '923', '924', '925', '931', '932', '933', '934', '941', '942',
  '943', '944', '973', '974',
};

/// True for a +639XXXXXXXXX number on Smart, TNT, or Sun.
bool isSmartNetworkNumber(String phone) =>
    RegExp(r'^\+639\d{9}$').hasMatch(phone) &&
    _smartNetworkPrefixes.contains(phone.substring(3, 6));

const smartNetworkUnsupportedMessage =
    'Smart and TNT numbers aren’t available at the moment due to a '
    'provider restriction. Please use a number from another network.';
