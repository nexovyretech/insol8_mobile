import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/models/dashboard_data.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric(
        label: 'Loads dried today',
        value: '${data.loadsDriedToday}',
        note: '${data.loadsDriedToday} loads, up from yesterday',
        iconAsset: 'assets/icons/dashboard_loads.svg',
      ),
      _Metric(
        label: 'Registered units',
        value: '${data.registeredUnits}',
        note: 'All registered devices',
        iconAsset: 'assets/icons/dashboard_units.svg',
      ),
      _Metric(
        label: 'Active branches',
        value: '${data.activeBranches} of ${data.totalBranches}',
        note: 'Open branches',
        iconAsset: 'assets/icons/dashboard_units.svg',
      ),
      _Metric(
        label: 'Energy saved today',
        value: '${_formatEnergy(data.energySavedKwh)} kWh',
        note:
            '${_formatEnergy(data.energySavedKwh)} kWh saved, about ₱${data.energySavingsEstimatePhp.toStringAsFixed(2)}',
        iconAsset: 'assets/icons/dashboard_energy.svg',
      ),
    ];

    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 176,
      ),
      itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
    );
  }

  String _formatEnergy(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.note,
    required this.iconAsset,
  });

  final String label;
  final String value;
  final String note;
  final String iconAsset;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dashboardCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dashboardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D35170F),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.dashboardIconBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: SvgPicture.asset(
                  metric.iconAsset,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.fieldHint,
              fontSize: 14,
              height: 1.2,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontSize: 34,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            metric.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.fieldHint,
              fontSize: 13,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
