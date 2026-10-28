import 'package:insol8_mobile/models/analytics_data.dart';

/// Data boundary for analytics. Replace this implementation with an API
/// adapter once the analytics endpoint and response contract are available.
abstract interface class AnalyticsRepository {
  Future<AnalyticsData> fetchAnalytics({
    required AnalyticsPeriod period,
    String? branchId,
  });
}

class MockAnalyticsRepository implements AnalyticsRepository {
  const MockAnalyticsRepository();

  @override
  Future<AnalyticsData> fetchAnalytics({
    required AnalyticsPeriod period,
    String? branchId,
  }) async {
    final scale = switch (period) {
      AnalyticsPeriod.today => 1.0,
      AnalyticsPeriod.thisWeek => 1.35,
      AnalyticsPeriod.thisMonth => 1.8,
    };
    return AnalyticsData(
      loadsDried: (18 * scale).round(),
      averageDryingHours: .97,
      moneySavedPhp: 150 * scale,
      energySavedKwh: 12 * scale,
      loadsByHour: const [2, 3, 4, 3, 1, 2, 2, 1, 1, 1],
      solarHeatPercent: 82,
      backupHeatPercent: 18,
      dryingTimeByPeriod: const [
        AnalyticsDuration(label: 'Other', minutes: 70),
        AnalyticsDuration(label: 'Midday', minutes: 55),
      ],
      dryerComparisons: const [
        AnalyticsDryerComparison(name: 'DRYER 01', loads: 7),
        AnalyticsDryerComparison(name: 'DRYER 02', loads: 4),
        AnalyticsDryerComparison(name: 'DRYER 03', loads: 2),
        AnalyticsDryerComparison(name: 'DRYER 04', loads: 1),
      ],
    );
  }
}
