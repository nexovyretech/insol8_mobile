import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/auth/brand_mark.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.firstName,
    this.onNotifications,
  });

  final String firstName;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.pageHeaderHeight,
      child: Row(
        children: [
          const BrandMark(size: 34),
          Expanded(
            child: Text(
              'Hey, $firstName!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
          Material(
            color: AppColors.dashboardCard,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onNotifications,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.notifications_none, color: AppColors.primary),
                    Positioned(
                      top: 7,
                      right: 9,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
