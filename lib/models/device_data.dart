/// Display data for one dryer in the device list.
class DeviceData {
  const DeviceData({
    required this.id,
    required this.name,
    required this.status,
    required this.temperatureCelsius,
    required this.batteryPercent,
    required this.cycleDuration,
    required this.lastUpdated,
    this.maxLoadKg = defaultMaxLoadKg,
  });

  /// Load capacity of the current dryer model; the API sends each dryer's own.
  static const defaultMaxLoadKg = 8.0;

  factory DeviceData.fromJson(Map<String, dynamic> json) => DeviceData(
    id: json['id'] as String,
    name: json['name'] as String,
    status: DeviceStatus.values.firstWhere(
      (status) => status.name == json['status'],
      orElse: () => DeviceStatus.offline,
    ),
    temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble(),
    batteryPercent: (json['batteryPercent'] as num?)?.toInt(),
    cycleDuration: json['cycleDuration'] as String,
    lastUpdated: json['lastUpdated'] as String,
    maxLoadKg: (json['maxLoadKg'] as num?)?.toDouble() ?? defaultMaxLoadKg,
  );

  final String id;
  final String name;
  final DeviceStatus status;

  /// Null until the dryer has sent a chamber temperature.
  final double? temperatureCelsius;

  /// Null until the battery calculation is defined.
  final int? batteryPercent;
  final String cycleDuration;
  final String lastUpdated;

  /// The most laundry (kg) this dryer can hold in one job.
  final double maxLoadKg;
}

enum DeviceStatus { active, idle, offline }
