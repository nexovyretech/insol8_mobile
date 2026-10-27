import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/dashboard_data.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

class DashboardAttentionList extends StatelessWidget {
  const DashboardAttentionList({
    super.key,
    required this.items,
    this.onTapItem,
  });

  final List<DashboardAttentionItem> items;
  final ValueChanged<DashboardAttentionItem>? onTapItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'All devices are operating normally.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A35170F),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 56, endIndent: 14),
            _AttentionRow(
              item: items[index],
              onTap: () => onTapItem?.call(items[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item, required this.onTap});

  final DashboardAttentionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = item.type == DashboardAttentionType.connection
        ? Icons.warning_amber_rounded
        : Icons.battery_alert_outlined;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.dashboardCard,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.sectionLabel, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.deviceName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.message,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.fieldHint, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.sectionLabel),
          ],
        ),
      ),
    );
  }
}
