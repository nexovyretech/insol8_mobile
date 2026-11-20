import 'package:insol8_mobile/models/branch_data.dart';

/// Backend boundary for Organization subscription branch management.
abstract interface class BranchRepository {
  Future<List<BranchData>> fetchBranches();

  Future<void> createBranch(BranchData branch);

  /// Assigns a named manager to an existing branch, or clears the assignment
  /// when both names are null (`managerOption: myself` on the backend).
  Future<void> updateBranchManager({
    required String branchId,
    required String? firstName,
    required String? lastName,
  });
}
