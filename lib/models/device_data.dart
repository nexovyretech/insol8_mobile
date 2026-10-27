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
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) => DeviceData(
    id: json['id'] as String,
    name: json['name'] as String,
    status: DeviceStatus.values.firstWhere(
      (status) => status.name == json['status'],
      orElse: () => DeviceStatus.offline,
    ),
    temperatureCelsius: (json['temperatureCelsius'] as num).toDouble(),
    batteryPercent: (json['batteryPercent'] as num).toInt(),
    cycleDuration: json['cycleDuration'] as String,
    lastUpdated: json['lastUpdated'] as String,
  );

  final String id;
  final String name;
  final DeviceStatus status;
  final double temperatureCelsius;
  final int batteryPercent;
  final String cycleDuration;
  final String lastUpdated;
}

enum DeviceStatus { active, idle, offline }
