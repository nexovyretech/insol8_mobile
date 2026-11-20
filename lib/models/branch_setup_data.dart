enum BranchManagerOption {
  myself('myself'),
  newManager('newManager');

  const BranchManagerOption(this.apiValue);

  /// Value sent to `POST /branches`.
  final String apiValue;
}

class BranchSetupData {
  const BranchSetupData({
    required this.name,
    required this.address,
    required this.managerOption,
    this.managerFirstName,
    this.managerLastName,
    this.managerEmail,
    this.managerMobileNumber,
  });

  final String name;
  final String address;
  final BranchManagerOption managerOption;
  final String? managerFirstName;
  final String? managerLastName;

  /// Contact from the new manager account step. Kept for the UI and local
  /// payload tests, but intentionally not sent to `POST /branches`: the backend
  /// whitelist only accepts branch name, address and manager names.
  final String? managerEmail;
  final String? managerMobileNumber;

  Map<String, dynamic> toJson() => {
    'name': name,
    'storeAddress': address,
    'managerOption': managerOption.apiValue,
    if (managerOption == BranchManagerOption.newManager) ...{
      'managerFirstName': managerFirstName,
      'managerLastName': managerLastName,
    },
  };
}
