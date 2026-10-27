import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({
    super.key,
    required this.onAddDevice,
    required this.onReportIssue,
  });

  final VoidCallback onAddDevice;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dashboardCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              label: 'Add Device',
              icon: Icons.add,
              onPressed: onAddDevice,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionButton(
              label: 'Report an Issue',
              icon: Icons.flag_outlined,
              onPressed: onReportIssue,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
