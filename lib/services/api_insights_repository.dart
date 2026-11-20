import 'package:insol8_mobile/models/analytics_data.dart';
import 'package:insol8_mobile/models/dashboard_data.dart';
import 'package:insol8_mobile/services/analytics_repository.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/dashboard_payload_adapter.dart';
import 'package:insol8_mobile/services/dashboard_repository.dart';

/// Dashboard backed by `GET /dashboard`. The adapter lets the backend grow the
/// payload without forcing a client change, while keeping the original fields
/// strictly validated.
class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository({
    ApiClient? apiClient,
    DashboardPayloadAdapter? adapter,
  }) : _api = apiClient ?? ApiClient(),
       _adapter = adapter ?? const DashboardPayloadAdapter();

  final ApiClient _api;
  final DashboardPayloadAdapter _adapter;

  @override
  Future<DashboardData> fetchDashboard() async =>
      _adapter.map(await _api.get('/dashboard'));
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
