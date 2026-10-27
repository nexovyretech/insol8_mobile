import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

class DeviceCycleControlPanel extends StatelessWidget {
  const DeviceCycleControlPanel({
    super.key,
    required this.fabricType,
    required this.runtimeMinutes,
    required this.onFabricChanged,
    required this.onRuntimeChanged,
  });

  static const fabricTypes = ['Cotton', 'Delicates', 'Synthetics', 'Heavy'];

  final String? fabricType;
  final int runtimeMinutes;
  final ValueChanged<String?> onFabricChanged;
  final ValueChanged<int> onRuntimeChanged;

  @override
  Widget build(BuildContext context) {
    final selectedFabricType = fabricTypes.contains(fabricType)
        ? fabricType
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Cycle Control Panel'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dashboardCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dashboardBorder),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Fabric Type',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.ink, fontSize: 13),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedFabricType,
                        hint: const Text('Select'),
                        alignment: AlignmentDirectional.centerEnd,
                        menuWidth: 160,
                        menuMaxHeight: 220,
                        itemHeight: 48,
                        dropdownColor: AppColors.dashboardCard,
                        borderRadius: BorderRadius.circular(18),
                        elevation: 8,
                        icon: const Icon(
                          Icons.unfold_more,
                          color: AppColors.sectionLabel,
                          size: 18,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.fieldHint,
                          fontSize: 13,
                        ),
                        items: [
                          for (final fabric in fabricTypes)
                            DropdownMenuItem(
                              value: fabric,
                              alignment: AlignmentDirectional.centerStart,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(fabric),
                              ),
                            ),
                        ],
                        onChanged: onFabricChanged,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 14, endIndent: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 8, 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Runtime Selector',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.ink, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      onPressed: runtimeMinutes == 0
                          ? null
                          : () => onRuntimeChanged(
                              (runtimeMinutes - 5).clamp(0, 240).toInt(),
                            ),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 17),
                      color: AppColors.sectionLabel,
                      disabledColor: AppColors.disabled,
                    ),
                    Text(
                      '${runtimeMinutes.toString().padLeft(2, '0')} mins',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.fieldHint, fontSize: 11),
                    ),
                    IconButton(
                      onPressed: runtimeMinutes >= 240
                          ? null
                          : () => onRuntimeChanged(runtimeMinutes + 5),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 17),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.sectionLabel,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
