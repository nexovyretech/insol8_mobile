import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

/// The round icon at the top of a settings dialog, in the same soft-orange
/// badge style as the dashboard and Settings icons.
class DialogIconBadge extends StatelessWidget {
  const DialogIconBadge(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: const BoxDecoration(
      color: AppColors.dashboardIconBackground,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: AppColors.primary, size: 26),
  );
}
