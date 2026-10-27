enum DeviceOperatingMode { automatic, manual }

class DeviceDetailData {
  const DeviceDetailData({
    required this.deviceId,
    required this.isActive,
    required this.timeStarted,
    required this.chamberTemperatureCelsius,
    required this.thermalChargePercent,
    required this.loadCapacityKg,
    required this.timeRemainingMinutes,
    required this.energySavedKwh,
    required this.fabricType,
    required this.runtimeMinutes,
    required this.operatingMode,
    required this.history,
  });

  factory DeviceDetailData.fromJson(Map<String, dynamic> json) =>
      DeviceDetailData(
        deviceId: json['deviceId'] as String,
        isActive: json['isActive'] as bool,
        timeStarted: json['timeStarted'] as String,
        chamberTemperatureCelsius: (json['chamberTemperatureCelsius'] as num)
            .toDouble(),
        thermalChargePercent: (json['thermalChargePercent'] as num).toDouble(),
        loadCapacityKg: (json['loadCapacityKg'] as num).toDouble(),
        timeRemainingMinutes: (json['timeRemainingMinutes'] as num).toInt(),
        energySavedKwh: (json['energySavedKwh'] as num).toDouble(),
        fabricType: json['fabricType'] as String?,
        runtimeMinutes: (json['runtimeMinutes'] as num?)?.toInt() ?? 0,
        operatingMode: DeviceOperatingMode.values.firstWhere(
          (mode) => mode.name == json['operatingMode'],
          orElse: () => DeviceOperatingMode.automatic,
        ),
        history: (json['history'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  DeviceHistoryRecord.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  final String deviceId;
  final bool isActive;
  final String timeStarted;
  final double chamberTemperatureCelsius;
  final double thermalChargePercent;
  final double loadCapacityKg;
  final int timeRemainingMinutes;
  final double energySavedKwh;
  final String? fabricType;
  final int runtimeMinutes;
  final DeviceOperatingMode operatingMode;
  final List<DeviceHistoryRecord> history;
}

class DeviceHistoryRecord {
  const DeviceHistoryRecord({
    required this.fabricType,
    required this.period,
    required this.temperatureCelsius,
    required this.thermalChargePercent,
    required this.durationMinutes,
    required this.time,
  });

  factory DeviceHistoryRecord.fromJson(Map<String, dynamic> json) =>
      DeviceHistoryRecord(
        fabricType: json['fabricType'] as String,
        period: DeviceHistoryPeriod.values.firstWhere(
          (period) => period.name == json['period'],
          orElse: () => DeviceHistoryPeriod.today,
        ),
        temperatureCelsius: (json['temperatureCelsius'] as num).toDouble(),
        thermalChargePercent: (json['thermalChargePercent'] as num).toDouble(),
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        time: json['time'] as String,
      );

  final String fabricType;
  final DeviceHistoryPeriod period;
  final double temperatureCelsius;
  final double thermalChargePercent;
  final int durationMinutes;
  final String time;
}

enum DeviceHistoryPeriod { today, pastSevenDays, pastMonths }

class DeviceCycleSettings {
  const DeviceCycleSettings({
    required this.fabricType,
    required this.runtimeMinutes,
  });

  final String? fabricType;
  final int runtimeMinutes;
}
