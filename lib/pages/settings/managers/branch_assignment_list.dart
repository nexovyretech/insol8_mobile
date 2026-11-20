import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/models/manager_data.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_style.dart';

/// Branch checkboxes used by Manager Access and Add Manager. The backend only
/// allows one manager per branch, so each branch is a simple on/off choice.
class BranchAssignmentList extends StatelessWidget {
  const BranchAssignmentList({
    super.key,
    required this.branches,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<BranchData> branches;
  final Set<String> selectedIds;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final branch in branches)
        SizedBox(
          height: 44,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: selectedIds.contains(branch.id),
                  activeColor: BranchSetupPalette.orange,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  // The Figma checkboxes use the same orange as the check
                  // itself; the old gray outline made the check look missing.
                  side: const BorderSide(
                    color: BranchSetupPalette.orange,
                    width: 1.5,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) => onChanged(branch.id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ManagerData.displayBranchName(branch.name),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: BranchSetupPalette.ink, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
