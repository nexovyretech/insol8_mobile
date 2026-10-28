import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/branch_repository.dart';

/// Branches backed by `/branches`, with dryer counts from `GET /devices`.
class ApiBranchRepository implements BranchRepository {
  ApiBranchRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  @override
  Future<List<BranchData>> fetchBranches() async {
    final results = await Future.wait([
      _api.getList('/branches'),
      _api.getList('/devices'),
    ]);
    final devices = results[1];
    return [
      for (final branch in results[0])
        _branch(
          branch,
          devices.where((device) => device['branchId'] == branch['branchId']),
        ),
    ];
  }

  // POST /branches needs the manager option chosen in the form.
  @override
  Future<void> createBranch(BranchData branch) async {
    final setup = branch.setup;
    if (setup == null) {
      throw ArgumentError.value(branch, 'branch', 'setup is required');
    }
    await _api.post('/branches', setup.toJson());
  }

  // A branch is shown as open while any of its dryers is online.
  BranchData _branch(
    Map<String, dynamic> json,
    Iterable<Map<String, dynamic>> devices,
  ) => BranchData(
    id: json['branchId'] as String,
    name: (json['name'] as String).toUpperCase(),
    address: json['storeAddress'] as String,
    managerName: json['managerOption'] == 'newManager'
        ? '${json['managerFirstName']} ${json['managerLastName']}'
        : 'You',
    dryerCount: devices.length,
    activeCycles: devices
        .where((device) => device['activeSessionId'] != null)
        .length,
    isOpen: devices.any((device) => device['online'] == true),
    deviceIds: [for (final device in devices) device['deviceId'] as String],
  );
}
