/// Read-only dashboard data returned by [DashboardRepository].
class DashboardData {
  const DashboardData({
    required this.loadsDriedToday,
    required this.registeredUnits,
    required this.activeBranches,
    required this.totalBranches,
    required this.energySavedKwh,
    required this.energySavingsEstimatePhp,
    required this.attentionItems,
    this.runningDryers = 2,
    this.readyToDry = 4,
    this.moneyEarnedTodayPhp = 2450,
    this.dryingJobs = defaultDashboardDryingJobs,
    this.branchActivity = defaultDashboardBranchActivity,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    loadsDriedToday: json['loadsDriedToday'] as int,
    registeredUnits: json['registeredUnits'] as int,
    activeBranches: json['activeBranches'] as int,
    totalBranches: json['totalBranches'] as int,
    energySavedKwh: (json['energySavedKwh'] as num).toDouble(),
    energySavingsEstimatePhp: (json['energySavingsEstimatePhp'] as num)
        .toDouble(),
    attentionItems: (json['attentionItems'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              DashboardAttentionItem.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false),
    runningDryers: (json['runningDryers'] as num?)?.toInt() ?? 2,
    readyToDry: (json['readyToDry'] as num?)?.toInt() ?? 4,
    moneyEarnedTodayPhp:
        (json['moneyEarnedTodayPhp'] as num?)?.toDouble() ?? 2450,
    dryingJobs:
        (json['dryingJobs'] as List<dynamic>?)
            ?.map(
              (job) => DashboardDryingJob.fromJson(job as Map<String, dynamic>),
            )
            .toList(growable: false) ??
        defaultDashboardDryingJobs,
    branchActivity:
        (json['branchActivity'] as List<dynamic>?)
            ?.map(
              (branch) => DashboardBranchActivity.fromJson(
                branch as Map<String, dynamic>,
              ),
            )
            .toList(growable: false) ??
        defaultDashboardBranchActivity,
  );

  final int loadsDriedToday;
  final int registeredUnits;
  final int activeBranches;
  final int totalBranches;
  final double energySavedKwh;
  final double energySavingsEstimatePhp;
  final List<DashboardAttentionItem> attentionItems;

  /// Basic tier: "Drying now" / "Currently running".
  final int runningDryers;

  /// Basic tier: "Ready to dry" / "Available dryers".
  final int readyToDry;

  /// Org tier: "Money earned today".
  final double moneyEarnedTodayPhp;

  /// Basic tier: "Current Drying Jobs".
  final List<DashboardDryingJob> dryingJobs;

  /// Org tier: "Branches".
  final List<DashboardBranchActivity> branchActivity;
}

/// A running job in the Basic tier's "Current Drying Jobs" list.
class DashboardDryingJob {
  const DashboardDryingJob({
    required this.dryerName,
    required this.loadKg,
    required this.remainingMinutes,
    this.status = 'Running',
  });

  factory DashboardDryingJob.fromJson(Map<String, dynamic> json) =>
      DashboardDryingJob(
        dryerName: json['dryerName'] as String,
        loadKg: (json['loadKg'] as num).toDouble(),
        remainingMinutes: json['remainingMinutes'] as int,
        status: json['status'] as String? ?? 'Running',
      );

  final String dryerName;
  final double loadKg;
  final int remainingMinutes;
  final String status;
}

/// One row in the Org tier's "Branches" list.
class DashboardBranchActivity {
  const DashboardBranchActivity({
    required this.number,
    required this.name,
    required this.location,
    required this.time,
  });

  factory DashboardBranchActivity.fromJson(Map<String, dynamic> json) =>
      DashboardBranchActivity(
        number: json['number'] as int,
        name: json['name'] as String,
        location: json['location'] as String,
        time: json['time'] as String,
      );

  final int number;
  final String name;
  final String location;
  final String time;
}

/// Design values shown when the dashboard API does not provide these fields.
const defaultDashboardDryingJobs = [
  DashboardDryingJob(dryerName: 'DRYER 02', loadKg: 3.4, remainingMinutes: 25),
  DashboardDryingJob(dryerName: 'DRYER 05', loadKg: 2.8, remainingMinutes: 12),
];

const defaultDashboardBranchActivity = [
  DashboardBranchActivity(
    number: 2,
    name: 'Branch 1',
    location: 'Caloocan',
    time: '8:15 AM',
  ),
  DashboardBranchActivity(
    number: 3,
    name: 'Branch 2',
    location: 'Quezon City',
    time: '9:02 AM',
  ),
];

class DashboardAttentionItem {
  const DashboardAttentionItem({
    required this.deviceId,
    required this.deviceName,
    required this.message,
    required this.type,
  });

  factory DashboardAttentionItem.fromJson(Map<String, dynamic> json) =>
      DashboardAttentionItem(
        deviceId: json['deviceId'] as String,
        deviceName: json['deviceName'] as String,
        message: json['message'] as String,
        type: DashboardAttentionType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => DashboardAttentionType.connection,
        ),
      );

  final String deviceId;
  final String deviceName;
  final String message;
  final DashboardAttentionType type;
}

enum DashboardAttentionType { connection, battery }
