import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

/// Transparent, reusable branch result/list card.
class BranchCard extends StatelessWidget {
  const BranchCard({
    super.key,
    required this.branch,
    required this.onTap,
    this.cityOnlyAddress = false,
    this.searchResultStyle = false,
  });

  final BranchData branch;
  final VoidCallback onTap;
  final bool cityOnlyAddress;
  final bool searchResultStyle;

  String get _displayAddress {
    if (!cityOnlyAddress) return branch.address;
    final segments = branch.address.split(',');
    return segments.isEmpty ? branch.address : segments.last.trim();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        constraints: BoxConstraints(minHeight: searchResultStyle ? 88 : 0),
        padding: EdgeInsets.symmetric(
          horizontal: searchResultStyle ? 20 : 16,
          vertical: searchResultStyle ? 14 : 13,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.dashboardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: searchResultStyle
                          ? AppColors.sectionLabel
                          : branch.isOpen
                          ? AppColors.primary
                          : AppColors.sectionLabel,
                      fontSize: searchResultStyle ? 16 : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$_displayAddress  |  ${branch.dryerCount} Dryers  |  ${branch.activeCycles} Active Cycles',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.fieldHint,
                      fontSize: searchResultStyle ? 12 : 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  branch.managerName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.fieldHint,
                    fontSize: searchResultStyle ? 12 : 10,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: branch.isOpen
                        ? AppColors.sectionLabel
                        : AppColors.disabled,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
