import 'package:flutter/material.dart';

import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

class DeviceSummaryCard extends StatelessWidget {
  const DeviceSummaryCard({super.key, required this.details});

  final DeviceDetailData details;

  @override
  Widget build(BuildContext context) {
    final remaining = details.timeRemainingMinutes;
    final metrics = [
      _GaugeMetric(
        title: 'Chamber Temperature',
        value: '${_number(details.chamberTemperatureCelsius)}°C',
        progress: _fraction(details.chamberTemperatureCelsius, 100),
      ),
      _GaugeMetric(
        title: 'Thermal Charge Status',
        value: '${_number(details.thermalChargePercent)}%',
        progress: _fraction(details.thermalChargePercent, 100),
      ),
      _GaugeMetric(
        title: 'Load Capacity',
        value: '${_number(details.loadCapacityKg)}kg',
        progress: details.loadCapacityKg == null ? 0 : 0.78,
      ),
      _GaugeMetric(
        title: 'Time Remaining',
        value: '${remaining ?? '—'}mins',
        progress: remaining == null || details.runtimeMinutes == 0
            ? 0
            : _fraction(remaining.toDouble(), details.runtimeMinutes),
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.dashboardCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ActiveBadge(isActive: details.isActive),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Time Started:',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.fieldHint, fontSize: 10),
                  ),
                  Text(
                    details.timeStarted,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.body, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.dashboardBorder),
          ),
          GridView.builder(
            itemCount: metrics.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 6,
              mainAxisExtent: 112,
            ),
            itemBuilder: (context, index) =>
                _MetricGauge(metric: metrics[index]),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.dashboardBorder),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Energy Saved',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Free from the sun',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.fieldHint, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Text(
                '${_energy(details.energySavedKwh)}kWh',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Values the backend cannot provide yet arrive as null and show as a dash.
  String _number(double? value) => value == null
      ? '—'
      : value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  // A cycle saves fractions of a kWh, so one decimal would hide it climbing.
  String _energy(double? value) =>
      value == null ? '—' : value.toStringAsFixed(2);

  double _fraction(double? value, num whole) =>
      value == null ? 0 : (value / whole).clamp(0, 1).toDouble();
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: isActive
          ? AppColors.field
          : AppColors.inactive.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.fieldHint,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'ACTIVE' : 'IDLE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive ? AppColors.primary : AppColors.fieldHint,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _GaugeMetric {
  const _GaugeMetric({
    required this.title,
    required this.value,
    required this.progress,
  });

  final String title;
  final String value;
  final double progress;
}

class _MetricGauge extends StatelessWidget {
  const _MetricGauge({required this.metric});

  final _GaugeMetric metric;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        metric.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.fieldHint, fontSize: 10),
      ),
      SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: metric.progress,
                strokeWidth: 11,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.field,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            Text(
              metric.value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
