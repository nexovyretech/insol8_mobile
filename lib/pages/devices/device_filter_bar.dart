import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

enum DeviceFilter { all, active, idle, offline }

class DeviceFilterBar extends StatelessWidget {
  const DeviceFilterBar({
    super.key,
    required this.selectedFilter,
    required this.counts,
    required this.onSelected,
  });

  final DeviceFilter selectedFilter;
  final Map<DeviceFilter, int> counts;
  final ValueChanged<DeviceFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = {
      DeviceFilter.all: 'All',
      DeviceFilter.active: 'Active',
      DeviceFilter.idle: 'Idle',
      DeviceFilter.offline: 'Offline',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in DeviceFilter.values) ...[
            if (filter != DeviceFilter.all) const SizedBox(width: 8),
            _FilterChip(
              label: '${labels[filter]} (${counts[filter] ?? 0})',
              isSelected: selectedFilter == filter,
              onTap: () => onSelected(filter),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: isSelected ? AppColors.dashboardCard : Colors.transparent,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppColors.ink : AppColors.fieldHint,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}
