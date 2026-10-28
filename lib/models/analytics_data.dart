/// Analytics response models. Keep these independent from presentation widgets
/// so a backend adapter can map its API response into the same types.
class AnalyticsData {
  const AnalyticsData({
    required this.loadsDried,
    required this.averageDryingHours,
    required this.moneySavedPhp,
    required this.energySavedKwh,
    required this.loadsByHour,
    required this.solarHeatPercent,
    required this.backupHeatPercent,
    required this.dryingTimeByPeriod,
    required this.dryerComparisons,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) => AnalyticsData(
    loadsDried: (json['loadsDried'] as num).toInt(),
    averageDryingHours: (json['averageDryingHours'] as num).toDouble(),
    moneySavedPhp: (json['moneySavedPhp'] as num).toDouble(),
    energySavedKwh: (json['energySavedKwh'] as num).toDouble(),
    loadsByHour: (json['loadsByHour'] as List<dynamic>)
        .map((value) => (value as num).toDouble())
        .toList(growable: false),
    solarHeatPercent: (json['solarHeatPercent'] as num?)?.toInt(),
    backupHeatPercent: (json['backupHeatPercent'] as num?)?.toInt(),
    dryingTimeByPeriod: (json['dryingTimeByPeriod'] as List<dynamic>)
        .map(
          (value) => AnalyticsDuration.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false),
    dryerComparisons: (json['dryerComparisons'] as List<dynamic>)
        .map(
          (value) =>
              AnalyticsDryerComparison.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false),
  );

  final int loadsDried;
  final double averageDryingHours;
  final double moneySavedPhp;
  final double energySavedKwh;
  final List<double> loadsByHour;

  /// Null until there is enough data to estimate where the heat came from.
  final int? solarHeatPercent;
  final int? backupHeatPercent;
  final List<AnalyticsDuration> dryingTimeByPeriod;
  final List<AnalyticsDryerComparison> dryerComparisons;
}

class AnalyticsDuration {
  const AnalyticsDuration({required this.label, required this.minutes});

  factory AnalyticsDuration.fromJson(Map<String, dynamic> json) =>
      AnalyticsDuration(
        label: json['label'] as String,
        minutes: (json['minutes'] as num).toInt(),
      );

  final String label;
  final int minutes;
}

class AnalyticsDryerComparison {
  const AnalyticsDryerComparison({required this.name, required this.loads});

  factory AnalyticsDryerComparison.fromJson(Map<String, dynamic> json) =>
      AnalyticsDryerComparison(
        name: json['name'] as String,
        loads: (json['loads'] as num).toInt(),
      );

  final String name;
  final int loads;
}

enum AnalyticsPeriod { today, thisWeek, thisMonth }
