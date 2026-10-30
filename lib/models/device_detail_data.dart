import 'package:insol8_mobile/models/device_data.dart';

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
    this.sessionId,
    this.maxLoadKg = DeviceData.defaultMaxLoadKg,
  });

  factory DeviceDetailData.fromJson(
    Map<String, dynamic> json,
  ) => DeviceDetailData(
    deviceId: json['deviceId'] as String,
    isActive: json['isActive'] as bool,
    timeStarted: json['timeStarted'] as String,
    chamberTemperatureCelsius: (json['chamberTemperatureCelsius'] as num?)
        ?.toDouble(),
    thermalChargePercent: (json['thermalChargePercent'] as num?)?.toDouble(),
    loadCapacityKg: (json['loadCapacityKg'] as num?)?.toDouble(),
    timeRemainingMinutes: (json['timeRemainingMinutes'] as num?)?.toInt(),
    energySavedKwh: (json['energySavedKwh'] as num?)?.toDouble(),
    fabricType: json['fabricType'] as String?,
    runtimeMinutes: (json['runtimeMinutes'] as num?)?.toInt() ?? 0,
    operatingMode: DeviceOperatingMode.values.firstWhere(
      (mode) => mode.name == json['operatingMode'],
      orElse: () => DeviceOperatingMode.automatic,
    ),
    history: (json['history'] as List<dynamic>? ?? const [])
        .map(
          (item) => DeviceHistoryRecord.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false),
    sessionId: json['sessionId'] as String?,
    maxLoadKg:
        (json['maxLoadKg'] as num?)?.toDouble() ?? DeviceData.defaultMaxLoadKg,
  );

  final String deviceId;
  final bool isActive;
  final String timeStarted;

  /// Latest chamber temperature; null until the dryer has reported one.
  final double? chamberTemperatureCelsius;

  /// Null until the thermal charge calculation is defined.
  final double? thermalChargePercent;

  /// Weight of the running load, entered when the cycle starts.
  final double? loadCapacityKg;

  /// The most this dryer can hold; the Load Capacity gauge fills toward it.
  final double maxLoadKg;

  /// Null when no cycle is running or it has no set runtime.
  final int? timeRemainingMinutes;

  /// Null until the energy-saved calculation fills it in.
  final double? energySavedKwh;
  final String? fabricType;
  final int runtimeMinutes;
  final DeviceOperatingMode operatingMode;
  final List<DeviceHistoryRecord> history;

  /// The running drying session, if any.
  final String? sessionId;

  /// A copy showing newer live values; a null value keeps the current one.
  DeviceDetailData withLiveReading({
    double? chamberTemperatureCelsius,
    double? thermalChargePercent,
    double? energySavedKwh,
  }) => DeviceDetailData(
    deviceId: deviceId,
    isActive: isActive,
    timeStarted: timeStarted,
    chamberTemperatureCelsius:
        chamberTemperatureCelsius ?? this.chamberTemperatureCelsius,
    thermalChargePercent: thermalChargePercent ?? this.thermalChargePercent,
    loadCapacityKg: loadCapacityKg,
    timeRemainingMinutes: timeRemainingMinutes,
    energySavedKwh: energySavedKwh ?? this.energySavedKwh,
    fabricType: fabricType,
    runtimeMinutes: runtimeMinutes,
    operatingMode: operatingMode,
    history: history,
    sessionId: sessionId,
    maxLoadKg: maxLoadKg,
  );
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
        fabricType: json['fabricType'] as String?,
        period: DeviceHistoryPeriod.values.firstWhere(
          (period) => period.name == json['period'],
          orElse: () => DeviceHistoryPeriod.today,
        ),
        temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble(),
        thermalChargePercent: (json['thermalChargePercent'] as num?)
            ?.toDouble(),
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        time: json['time'] as String,
      );

  /// Null when the cycle was started without a fabric type.
  final String? fabricType;
  final DeviceHistoryPeriod period;

  /// Average chamber temperature over the cycle.
  final double? temperatureCelsius;
  final double? thermalChargePercent;
  final int durationMinutes;
  final String time;
}

enum DeviceHistoryPeriod { today, pastSevenDays, pastMonths }

class DeviceCycleSettings {
  const DeviceCycleSettings({
    required this.fabricType,
    required this.runtimeMinutes,
    this.loadKg,
  });

  final String? fabricType;
  final int runtimeMinutes;

  /// Weight of the laundry for this job, in kg.
  final double? loadKg;
}
