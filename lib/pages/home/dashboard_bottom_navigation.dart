import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

class DashboardBottomNavigation extends StatelessWidget {
  const DashboardBottomNavigation({
    super.key,
    required this.onSelect,
    this.selectedIndex = 0,
    this.organizationPlan = false,
  });

  final ValueChanged<int> onSelect;
  final int selectedIndex;
  final bool organizationPlan;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('assets/icons/nav_home.svg', 'Home'),
      (
        'assets/icons/nav_devices.svg',
        organizationPlan ? 'Branches' : 'Devices',
      ),
      ('assets/icons/nav_activity.svg', 'Analytics'),
      ('assets/icons/nav_settings.svg', 'Settings'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1035170F),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 32,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              if (index == selectedIndex)
                                const Positioned(
                                  top: 0,
                                  child: CircleAvatar(
                                    radius: 3,
                                    backgroundColor: AppColors.primary,
                                  ),
                                ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: SvgPicture.asset(
                                  items[index].$1,
                                  width: 23,
                                  height: 23,
                                  colorFilter: ColorFilter.mode(
                                    index == selectedIndex
                                        ? AppColors.primary
                                        : AppColors.sectionLabel,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 16,
                          child: index == selectedIndex
                              ? Text(
                                  items[index].$2,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                      ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardSectionTitle extends StatelessWidget {
  const DashboardSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.sectionLabel,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
