import 'package:insol8_mobile/models/analytics_data.dart';
import 'package:insol8_mobile/models/dashboard_data.dart';
import 'package:insol8_mobile/services/analytics_repository.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/dashboard_repository.dart';

/// Dashboard backed by `GET /dashboard`, whose response matches
/// [DashboardData] field for field.
class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  @override
  Future<DashboardData> fetchDashboard() async =>
      DashboardData.fromJson(await _api.get('/dashboard'));
}

/// Analytics backed by `GET /analytics`. Period names match
/// [AnalyticsPeriod] (`today`, `thisWeek`, `thisMonth`).
class ApiAnalyticsRepository implements AnalyticsRepository {
  ApiAnalyticsRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  @override
  Future<AnalyticsData> fetchAnalytics({
    required AnalyticsPeriod period,
    String? branchId,
  }) async {
    final query = Uri(
      queryParameters: {'period': period.name, 'branchId': ?branchId},
    ).query;
    return AnalyticsData.fromJson(await _api.get('/analytics?$query'));
  }
}
