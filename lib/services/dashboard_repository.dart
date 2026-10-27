import 'package:insol8_mobile/models/dashboard_data.dart';

/// Data boundary for the signed-in dashboard.
///
/// The backend implementation should map its agreed response into
/// [DashboardData]. Keep HTTP and response parsing out of dashboard widgets.
abstract interface class DashboardRepository {
  Future<DashboardData> fetchDashboard();
}

/// Local preview data matching the dashboard design. No device or account
/// metrics are fetched from a live service yet.
class MockDashboardRepository implements DashboardRepository {
  const MockDashboardRepository();

  @override
  Future<DashboardData> fetchDashboard() async => const DashboardData(
    loadsDriedToday: 18,
    registeredUnits: 14,
    activeBranches: 3,
    totalBranches: 3,
    energySavedKwh: 12,
    energySavingsEstimatePhp: 150,
    attentionItems: [
      DashboardAttentionItem(
        deviceId: 'dryer-02',
        deviceName: 'DRYER UNIT 02',
        message: 'Unit has lost a connection',
        type: DashboardAttentionType.connection,
      ),
      DashboardAttentionItem(
        deviceId: 'dryer-14',
        deviceName: 'DRYER UNIT 14',
        message: 'Unit has low battery',
        type: DashboardAttentionType.battery,
      ),
    ],
  );
}
