import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:insol8_mobile/models/analytics_data.dart';
import 'package:insol8_mobile/pages/home/dashboard_bottom_navigation.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/analytics_report.dart';
import 'package:insol8_mobile/services/analytics_repository.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({
    super.key,
    required this.authRepository,
    required this.analyticsRepository,
    required this.subscriptionRepository,
    this.shareReport = shareAnalyticsReport,
  });

  final AuthRepository authRepository;
  final AnalyticsRepository analyticsRepository;
  final SubscriptionRepository subscriptionRepository;

  /// Creates and shares the PDF report; replaceable in tests.
  final Future<void> Function({
    required AnalyticsData data,
    required AnalyticsPeriod period,
  })
  shareReport;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsPeriod _period = AnalyticsPeriod.today;
  AnalyticsData? _data;
  String? _error;
  bool _loading = true;
  int _loadGeneration = 0;
  bool _organizationPlan = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final period = _period;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hasSession = await widget.authRepository.hasActiveSession();
      if (!mounted || generation != _loadGeneration) return;
      if (!hasSession) {
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.getStarted, (_) => false);
        }
        return;
      }
      final planId = await widget.subscriptionRepository.fetchActivePlanId();
      if (!mounted || generation != _loadGeneration) return;
      _organizationPlan = planId == SubscriptionPlanIds.organization;
      final data = await widget.analyticsRepository.fetchAnalytics(
        period: period,
      );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } on Exception {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = 'We couldn’t load analytics. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _selectPeriod(AnalyticsPeriod period) async {
    setState(() => _period = period);
    await _load();
  }

  Future<void> _downloadReport() async {
    final data = _data;
    if (data == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      await widget.shareReport(data: data, period: _period);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('We couldn’t create the report.')),
        );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _onNavigationSelected(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.of(context)
          .popUntil((route) => route.settings.name == AppRoutes.home);
    } else if (index == 1) {
      Navigator.of(
        context,
      ).pushNamed(_organizationPlan ? AppRoutes.branches : AppRoutes.devices);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.settings);
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.pageHeaderTop),
              const AppPageHeader(title: 'Analytics'),
              const SizedBox(height: AppSpacing.contentGap),
              _buildPeriodSelector(),
              const SizedBox(height: 12),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavigation(
        selectedIndex: 2,
        organizationPlan: _organizationPlan,
        onSelect: _onNavigationSelected,
      ),
    ),
  );

  Widget _buildPeriodSelector() => Row(
    children: [
      for (final period in AnalyticsPeriod.values)
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _selectPeriod(period),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _period == period
                    ? AppColors.dashboardCard
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                analyticsPeriodLabel(period),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _period == period
                      ? AppColors.ink
                      : AppColors.fieldHint,
                  fontSize: 11,
                  fontWeight: _period == period
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _buildContent() {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          _MetricCards(data: data, period: _period),
          const SizedBox(height: 8),
          _LoadsByHourCard(values: data.loadsByHour),
          const SizedBox(height: 8),
          _EnergySourceCard(data: data),
          const SizedBox(height: 8),
          _DryingTimeCard(durations: data.dryingTimeByPeriod),
          const SizedBox(height: 8),
          _DryerComparisonCard(dryers: data.dryerComparisons),
          const SizedBox(height: 8),
          FractionallySizedBox(
            widthFactor: 0.88,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _exporting || _loading ? null : _downloadReport,
                icon: _exporting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  _exporting ? 'Preparing report…' : 'Download report',
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCards extends StatelessWidget {
  const _MetricCards({required this.data, required this.period});

  final AnalyticsData data;
  final AnalyticsPeriod period;

  String get _when => switch (period) {
    AnalyticsPeriod.today => 'today',
    AnalyticsPeriod.thisWeek => 'this week',
    AnalyticsPeriod.thisMonth => 'this month',
  };

  @override
  Widget build(BuildContext context) => GridView.builder(
    itemCount: 4,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      mainAxisExtent: 176,
    ),
    itemBuilder: (context, index) => _MetricCard(
      metric: switch (index) {
        0 => _AnalyticsMetric(
          label: 'Loads dried $_when',
          value: '${data.loadsDried}',
          note: 'Finished jobs',
          icon: Icons.local_laundry_service_outlined,
        ),
        1 => _AnalyticsMetric(
          label: 'Avg. drying time',
          value:
              '${data.averageDryingHours.toStringAsFixed(2)} '
              '${data.averageDryingHours <= 1 ? 'hr' : 'hrs'}',
          note: 'Per finished job',
          icon: Icons.timer_outlined,
        ),
        2 => _AnalyticsMetric(
          label: 'Money saved',
          value: '₱${data.moneySavedPhp.round()}',
          note: 'Less electricity',
          icon: Icons.payments_outlined,
        ),
        _ => _AnalyticsMetric(
          label: 'Energy saved $_when',
          value: '${data.energySavedKwh.round()} kWh',
          note: 'Free from the sun',
          icon: Icons.bolt_outlined,
        ),
      },
    ),
  );
}

class _AnalyticsMetric {
  const _AnalyticsMetric({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
  });

  final String label;
  final String value;
  final String note;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _AnalyticsMetric metric;

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
            child: Icon(metric.icon, size: 20, color: AppColors.primary),
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

class _LoadsByHourCard extends StatelessWidget {
  const _LoadsByHourCard({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final peakIndex = values.isEmpty ? 0 : values.indexOf(maxValue);
    return Container(
      height: 194,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dashboardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A35170F),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOADS DRIED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.body,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'By hour',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppColors.fieldHint, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < values.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: (values[index] / maxValue).clamp(
                                  .08,
                                  1.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: values[index] == maxValue
                                        ? AppColors.primary
                                        : const Color(0xFFFFCFB8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${(index + 8) % 12 == 0 ? 12 : (index + 8) % 12}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.fieldHint,
                                  fontSize: 8,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              'Peak hour: ${chartHourLabel(peakIndex)} '
              '(${maxValue.round()} loads)',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.sectionLabel, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergySourceCard extends StatelessWidget {
  const _EnergySourceCard({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final solar = data.solarHeatPercent;
    final backup = data.backupHeatPercent;
    return _AnalyticsPanel(
      title: 'ENERGY SOURCE',
      child: solar == null || backup == null
          ? Text(
              'Not enough drying data yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.fieldHint, fontSize: 10),
            )
          : _split(context, solar, backup),
    );
  }

  Widget _split(BuildContext context, int solar, int backup) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            // A zero share takes no space (Expanded needs a positive flex).
            if (solar > 0)
              Expanded(
                flex: solar,
                child: Container(height: 10, color: AppColors.primary),
              ),
            if (backup > 0)
              Expanded(
                flex: backup,
                child: Container(height: 10, color: const Color(0xFFFFCFB8)),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PercentLabel(
            label: 'Free solar heat',
            percent: solar,
            align: TextAlign.left,
          ),
          _PercentLabel(
            label: 'Backup heat',
            percent: backup,
            align: TextAlign.right,
          ),
        ],
      ),
    ],
  );
}

class _PercentLabel extends StatelessWidget {
  const _PercentLabel({
    required this.label,
    required this.percent,
    required this.align,
  });

  final String label;
  final int percent;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
    '$label $percent%',
    textAlign: align,
    style: Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: AppColors.fieldHint, fontSize: 10),
  );
}

class _DryingTimeCard extends StatelessWidget {
  const _DryingTimeCard({required this.durations});

  final List<AnalyticsDuration> durations;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = durations.isEmpty
        ? 1
        : durations.map((item) => item.minutes).reduce((a, b) => a > b ? a : b);
    return _AnalyticsPanel(
      title: 'DRYING TIME BY HOUR',
      child: Column(
        children: [
          for (final duration in durations)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _HorizontalMetricBar(
                label: duration.label,
                value: duration.minutes,
                maxValue: maxMinutes,
                trailing: '${duration.minutes}mins',
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Loads dry fastest from 10 AM to 2 PM, when the sun is strongest.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.fieldHint, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _DryerComparisonCard extends StatelessWidget {
  const _DryerComparisonCard({required this.dryers});

  final List<AnalyticsDryerComparison> dryers;

  @override
  Widget build(BuildContext context) {
    final maxLoads = dryers.isEmpty
        ? 1
        : dryers.map((item) => item.loads).reduce((a, b) => a > b ? a : b);
    return _AnalyticsPanel(
      title: 'DRYERS COMPARED',
      child: Column(
        children: [
          for (final dryer in dryers)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _HorizontalMetricBar(
                label: dryer.name,
                value: dryer.loads,
                maxValue: maxLoads,
                trailing:
                    '${dryer.loads} ${dryer.loads == 1 ? 'load' : 'loads'}',
              ),
            ),
        ],
      ),
    );
  }
}

class _HorizontalMetricBar extends StatelessWidget {
  const _HorizontalMetricBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.trailing,
  });

  final String label;
  final int value;
  final int maxValue;
  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 56,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.body, fontSize: 9),
        ),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(height: 10, color: const Color(0xFFFFCFB8)),
              FractionallySizedBox(
                widthFactor: (value / maxValue).clamp(0.0, 1.0),
                child: Container(height: 10, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
      SizedBox(
        width: 50,
        child: Text(
          trailing,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.body, fontSize: 8),
        ),
      ),
    ],
  );
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.dashboardBorder),
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A35170F),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.body,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}
