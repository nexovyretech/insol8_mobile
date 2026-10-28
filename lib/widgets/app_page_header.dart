import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

/// Shared title row for signed-in pages, keeping title and action alignment
/// consistent as users move between the main sections.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSpacing.pageHeaderHeight,
    child: Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...actions,
      ],
    ),
  );
}

/// Centered header for signed-in pages opened from a main tab.
///
/// Fixed-width leading and trailing slots keep the title centered even when
/// only one side has an action.
class AppInnerPageHeader extends StatelessWidget {
  const AppInnerPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
    this.leadingIcon = Icons.chevron_left,
    this.leadingTooltip = 'Back',
    this.titleFontSize = 18,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;
  final IconData leadingIcon;
  final String leadingTooltip;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSpacing.pageHeaderHeight,
    child: Row(
      children: [
        SizedBox(
          width: AppSpacing.pageHeaderSlotWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              tooltip: leadingTooltip,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.pageHeaderSlotWidth,
                height: AppSpacing.pageHeaderHeight,
              ),
              icon: Icon(leadingIcon, size: 24, color: AppColors.ink),
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontSize: titleFontSize,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: AppSpacing.pageHeaderSlotWidth,
          height: AppSpacing.pageHeaderHeight,
          child: trailing == null ? null : Center(child: trailing),
        ),
      ],
    ),
  );
}
