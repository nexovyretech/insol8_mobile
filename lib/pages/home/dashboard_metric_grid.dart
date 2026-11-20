import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/models/dashboard_data.dart';

/// Colours sampled from the Basic/Org dashboard screenshots.
abstract final class DashboardMetricColors {
  static const card = Color(0xFFFDF6F1);
  static const border = Color(0xFFFBE9DA);
  static const iconBackground = Color(0xFFFBE9DA);
  static const accent = Color(0xFFD97247);
  static const label = Color(0xFF917F75);
}

class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({
    super.key,
    required this.data,
    this.organizationPlan = false,
  });

  final DashboardData data;
  final bool organizationPlan;

  List<_Metric> get _basicMetrics => [
    _Metric(
      label: 'Drying now',
      value: '${data.runningDryers}',
      note: 'Currently running',
      iconAsset: 'assets/icons/dashboard_units.svg',
    ),
    _Metric(
      label: 'Ready to dry',
      value: '${data.readyToDry}',
      note: 'Available dryers',
      iconAsset: 'assets/icons/dashboard_units.svg',
    ),
    _Metric(
      label: 'Loads dried today',
      value: '${data.loadsDriedToday}',
      note: '${data.loadsDriedToday} loads, up from yesterday',
      iconAsset: 'assets/icons/dashboard_loads.svg',
    ),
    _Metric(
      label: 'Energy saved today',
      value: '${_formatEnergy(data.energySavedKwh)} kWh',
      note:
          '${_formatEnergy(data.energySavedKwh)} kWh saved, about ₱${data.energySavingsEstimatePhp.toStringAsFixed(2)}',
      iconAsset: 'assets/icons/dashboard_energy.svg',
    ),
  ];

  List<_Metric> get _organizationMetrics => [
    _Metric(
      label: 'Energy saved today',
      value: '${_formatEnergy(data.energySavedKwh)} kWh',
      note: '${_formatEnergy(data.energySavedKwh)} kWh saved in all branches',
      iconAsset: 'assets/icons/dashboard_energy.svg',
    ),
    _Metric(
      label: 'Money earned today',
      value: _formatPesoWhole(data.moneyEarnedTodayPhp),
      note: 'All Branches',
      iconAsset: 'assets/icons/dashboard_loads.svg',
    ),
    _Metric(
      label: 'Active branches',
      value: '${data.activeBranches} of ${data.totalBranches}',
      note: 'Open branches',
      iconAsset: 'assets/icons/dashboard_units.svg',
    ),
    _Metric(
      label: 'Loads dried today',
      value: '${data.loadsDriedToday}',
      note: '${data.loadsDriedToday} loads, up from yesterday',
      iconAsset: 'assets/icons/dashboard_loads.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final metrics = organizationPlan ? _organizationMetrics : _basicMetrics;
    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 150,
      ),
      itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
    );
  }

  String _formatEnergy(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  /// `₱2,450` — the Org screenshot has no centavos.
  String _formatPesoWhole(double value) {
    final whole = value.round().toString();
    final withSeparators = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '₱$withSeparators';
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: DashboardMetricColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DashboardMetricColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: DashboardMetricColors.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 19,
                height: 19,
                child: SvgPicture.asset(
                  metric.iconAsset,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    DashboardMetricColors.accent,
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
              color: DashboardMetricColors.label,
              fontSize: 13,
              height: 1.2,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              style: textTheme.headlineSmall?.copyWith(
                color: DashboardMetricColors.accent,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            metric.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: DashboardMetricColors.label,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
