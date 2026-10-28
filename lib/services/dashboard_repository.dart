import 'package:insol8_mobile/models/dashboard_data.dart';

/// Data boundary for the signed-in dashboard.
///
/// The backend implementation should map its agreed response into
/// [DashboardData]. Keep HTTP and response parsing out of dashboard widgets.
abstract interface class DashboardRepository {
  Future<DashboardData> fetchDashboard();
}
