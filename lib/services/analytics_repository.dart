import 'package:insol8_mobile/models/analytics_data.dart';

/// Data boundary for analytics; [ApiAnalyticsRepository] in the app.
abstract interface class AnalyticsRepository {
  Future<AnalyticsData> fetchAnalytics({
    required AnalyticsPeriod period,
    String? branchId,
  });
}
