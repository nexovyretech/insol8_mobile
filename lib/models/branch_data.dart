/// Display and summary data for a business branch.
class BranchData {
  const BranchData({
    required this.id,
    required this.name,
    required this.address,
    required this.managerName,
    required this.dryerCount,
    required this.activeCycles,
    required this.isOpen,
    this.deviceIds = const [],
  });

  factory BranchData.fromJson(Map<String, dynamic> json) => BranchData(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    managerName: json['managerName'] as String,
    dryerCount: (json['dryerCount'] as num).toInt(),
    activeCycles: (json['activeCycles'] as num).toInt(),
    isOpen: json['isOpen'] as bool,
    deviceIds:
        (json['deviceIds'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  final String id;
  final String name;
  final String address;
  final String managerName;
  final int dryerCount;
  final int activeCycles;
  final bool isOpen;
  final List<String> deviceIds;
}
