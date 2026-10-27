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
  );

  final int loadsDriedToday;
  final int registeredUnits;
  final int activeBranches;
  final int totalBranches;
  final double energySavedKwh;
  final double energySavingsEstimatePhp;
  final List<DashboardAttentionItem> attentionItems;
}

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
