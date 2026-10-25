enum BranchManagerOption { myself, newManager }

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
}
