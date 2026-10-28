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
  });

  final String name;
  final String address;
  final BranchManagerOption managerOption;
  final String? managerFirstName;
  final String? managerLastName;

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
