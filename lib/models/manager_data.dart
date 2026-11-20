import 'package:insol8_mobile/models/branch_data.dart';

enum ManagerStatus { active, invitationPending }

/// A named manager, grouped from the branches they manage.
///
/// The backend stores a manager as a name on each branch rather than as a
/// standalone account, so one manager can appear on several branches.
class ManagerData {
  const ManagerData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.status,
    required this.branchIds,
    required this.branchNames,
  });

  final String firstName;
  final String lastName;
  final String email;
  final ManagerStatus status;
  final List<String> branchIds;
  final List<String> branchNames;

  String get name => '$firstName $lastName';

  String get statusLabel => switch (status) {
    ManagerStatus.active => 'Active',
    ManagerStatus.invitationPending => 'Invitation Pending',
  };

  String get key => name.trim().toLowerCase();

  /// Builds the manager list shown in Settings > Manager Management from the
  /// branch records returned by `GET /branches`.
  static List<ManagerData> fromBranches(List<BranchData> branches) {
    final grouped = <String, _ManagerGroup>{};
    for (final branch in branches) {
      if (!branch.hasNamedManager) continue;
      final first = (branch.managerFirstName ?? '').trim();
      final last = (branch.managerLastName ?? '').trim();
      if (first.isEmpty || last.isEmpty) continue;
      final manager = ManagerData(
        firstName: first,
        lastName: last,
        email: branch.managerEmail ?? '',
        status: _status(branch.managerStatus),
        branchIds: const [],
        branchNames: const [],
      );
      final group = grouped.putIfAbsent(
        manager.key,
        () => _ManagerGroup(manager),
      );
      group.branchIds.add(branch.id);
      group.branchNames.add(displayBranchName(branch.name));
    }
    final managers = [for (final group in grouped.values) group.build()]
      ..sort((a, b) => a.name.compareTo(b.name));
    return managers;
  }

  static ManagerStatus _status(String? value) => switch (value?.toLowerCase()) {
    'invitation_pending' ||
    'invitationpending' ||
    'pending' => ManagerStatus.invitationPending,
    _ => ManagerStatus.active,
  };

  /// Branch names are stored uppercase; Figma uses title case.
  static String displayBranchName(String name) {
    if (name.isEmpty) return name;
    return name
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }
}

class _ManagerGroup {
  _ManagerGroup(this.manager);

  final ManagerData manager;
  final branchIds = <String>[];
  final branchNames = <String>[];

  ManagerData build() => ManagerData(
    firstName: manager.firstName,
    lastName: manager.lastName,
    email: manager.email,
    status: manager.status,
    branchIds: List.unmodifiable(branchIds),
    branchNames: List.unmodifiable(branchNames),
  );
}
