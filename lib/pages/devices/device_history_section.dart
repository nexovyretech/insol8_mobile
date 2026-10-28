import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

class DeviceHistorySection extends StatelessWidget {
  const DeviceHistorySection({
    super.key,
    required this.records,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  final List<DeviceHistoryRecord> records;
  final DeviceHistoryPeriod selectedPeriod;
  final ValueChanged<DeviceHistoryPeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    final visibleRecords = records
        .where((record) => record.period.index <= selectedPeriod.index)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device History',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.sectionLabel,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final period in DeviceHistoryPeriod.values)
              Expanded(
                child: _PeriodTab(
                  period: period,
                  isSelected: selectedPeriod == period,
                  onTap: () => onPeriodSelected(period),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (visibleRecords.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No cycles recorded for this period.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.fieldHint, fontSize: 12),
              ),
            ),
          )
        else
          for (final record in visibleRecords) ...[
            _HistoryCard(record: record),
            const SizedBox(height: 7),
          ],
      ],
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.period,
    required this.isSelected,
    required this.onTap,
  });

  final DeviceHistoryPeriod period;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (period) {
      DeviceHistoryPeriod.today => 'Today',
      DeviceHistoryPeriod.pastSevenDays => 'Past 7 days',
      DeviceHistoryPeriod.pastMonths => 'Past Months',
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? AppColors.ink : AppColors.fieldHint,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});

  final DeviceHistoryRecord record;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.dashboardBorder),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.fabricType ?? 'Drying cycle',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_number(record.temperatureCelsius)}°C  |  ${_number(record.thermalChargePercent)}%  |  ${record.durationMinutes}mins',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.fieldHint, fontSize: 10),
              ),
            ],
          ),
        ),
        Text(
          record.time,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.fieldHint, fontSize: 10),
        ),
      ],
    ),
  );

  String _number(double? value) => value == null
      ? '—'
      : value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
