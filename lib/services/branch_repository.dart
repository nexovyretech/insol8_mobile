import 'package:insol8_mobile/models/branch_data.dart';

/// Backend boundary for Organization subscription branch management.
abstract interface class BranchRepository {
  Future<List<BranchData>> fetchBranches();

  Future<void> createBranch(BranchData branch);
}

/// Preview data for the branch screens until the branch API is connected.
class MockBranchRepository implements BranchRepository {
  const MockBranchRepository();

  static final List<BranchData> _branches = [
    BranchData(
      id: 'bagumbong',
      name: 'BAGUMBONG',
      address: 'Bagumbong Rd., Caloocan City',
      managerName: 'Jane Doe',
      dryerCount: 6,
      activeCycles: 5,
      isOpen: true,
      deviceIds: const [
        'dryer-01',
        'dryer-02',
        'dryer-03',
        'dryer-04',
        'dryer-05',
        'dryer-06',
      ],
    ),
    BranchData(
      id: 'bagong-silang',
      name: 'BAGONG SILANG',
      address: 'Bagong Silang, Caloocan City',
      managerName: 'Jane Doe',
      dryerCount: 6,
      activeCycles: 5,
      isOpen: true,
      deviceIds: const [
        'dryer-07',
        'dryer-08',
        'dryer-09',
        'dryer-10',
        'dryer-11',
        'dryer-12',
      ],
    ),
    BranchData(
      id: 'camarin',
      name: 'CAMARIN',
      address: 'Camarin Rd., Caloocan City',
      managerName: 'Jane Doe',
      dryerCount: 2,
      activeCycles: 2,
      isOpen: true,
      deviceIds: const ['dryer-13', 'dryer-14'],
    ),
  ];

  @override
  Future<List<BranchData>> fetchBranches() async =>
      List<BranchData>.unmodifiable(_branches);

  @override
  Future<void> createBranch(BranchData branch) async {
    _branches.add(branch);
  }
}
