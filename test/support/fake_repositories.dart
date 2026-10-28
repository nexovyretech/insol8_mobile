import 'package:insol8_mobile/models/dashboard_data.dart';
import 'package:insol8_mobile/services/analytics_repository.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/services/dashboard_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';

/// Test-only dashboard with fixed numbers.
class FakeDashboardRepository implements DashboardRepository {
  const FakeDashboardRepository();

  @override
  Future<DashboardData> fetchDashboard() async => const DashboardData(
    loadsDriedToday: 18,
    registeredUnits: 14,
    activeBranches: 3,
    totalBranches: 3,
    energySavedKwh: 12,
    energySavingsEstimatePhp: 150,
    attentionItems: [],
  );
}

/// Test-only subscription that reports [planId] as paid.
class FakeSubscriptionRepository implements SubscriptionRepository {
  const FakeSubscriptionRepository([this.planId]);

  final String? planId;

  @override
  Future<String?> fetchActivePlanId() async => planId;
}

// Pages these tests never open; any call fails the test.
class UnusedDeviceRepository implements DeviceRepository {
  const UnusedDeviceRepository();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('DeviceRepository is not used in this test.');
}

class UnusedAnalyticsRepository implements AnalyticsRepository {
  const UnusedAnalyticsRepository();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('AnalyticsRepository is not used in this test.');
}

class UnusedBranchRepository implements BranchRepository {
  const UnusedBranchRepository();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('BranchRepository is not used in this test.');
}
