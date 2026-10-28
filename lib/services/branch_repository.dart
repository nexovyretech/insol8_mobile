import 'package:insol8_mobile/models/branch_data.dart';

/// Backend boundary for Organization subscription branch management.
abstract interface class BranchRepository {
  Future<List<BranchData>> fetchBranches();

  Future<void> createBranch(BranchData branch);
}
