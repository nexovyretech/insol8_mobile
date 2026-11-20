import 'package:insol8_mobile/models/branch_setup_data.dart';

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
    this.setup,
    this.managerOption,
    this.managerFirstName,
    this.managerLastName,
    this.managerEmail,
    this.managerStatus,
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
    managerOption: json['managerOption'] as String?,
    managerFirstName: json['managerFirstName'] as String?,
    managerLastName: json['managerLastName'] as String?,
    managerEmail: json['managerEmail'] as String?,
    managerStatus: json['managerStatus'] as String?,
  );

  final String id;
  final String name;
  final String address;
  final String managerName;
  final int dryerCount;
  final int activeCycles;
  final bool isOpen;
  final List<String> deviceIds;

  /// What the user entered when adding the branch; `POST /branches` needs the
  /// manager option, which [managerName] alone cannot express.
  final BranchSetupData? setup;

  /// Manager identity returned by `GET /branches`. The backend currently stores
  /// only the name; the remaining fields are read when/if they are added.
  final String? managerOption;
  final String? managerFirstName;
  final String? managerLastName;
  final String? managerEmail;
  final String? managerStatus;

  bool get hasNamedManager => managerOption == 'newManager';
}
