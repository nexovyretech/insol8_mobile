import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/models/device_management_data.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/utils/display_format.dart';

/// Devices backed by the InSOL8 API: `/devices`, `/sessions` and `/branches`.
class ApiDeviceRepository implements DeviceRepository {
  ApiDeviceRepository({ApiClient? apiClient, DateTime Function()? clock})
    : _api = apiClient ?? ApiClient(),
      _now = clock ?? DateTime.now;

  final ApiClient _api;
  final DateTime Function() _now;

  // The backend has no endpoint for cycle settings or operating mode yet: the
  // settings are sent with POST /sessions when the start-cycle flow is added,
  // and operating mode has no device command. Kept in memory until then.
  static final Map<String, DeviceCycleSettings> _cycleSettings = {};
  static final Map<String, DeviceOperatingMode> _operatingModes = {};

  String _devicePath(String deviceId) =>
      '/devices/${Uri.encodeComponent(deviceId)}';

  @override
  Future<List<DeviceData>> fetchDevices() async => [
    for (final device in await _api.getList('/devices')) _device(device),
  ];

  @override
  Future<DeviceDetailData> fetchDeviceDetails(String deviceId) async {
    final device = await _api.get(_devicePath(deviceId));
    final sessionId = device['activeSessionId'] as String?;
    final results = await Future.wait([
      if (sessionId != null)
        _api.get('/sessions/${Uri.encodeComponent(sessionId)}')
      else
        Future.value(<String, dynamic>{}),
      _api.getList('/sessions?deviceId=${Uri.encodeQueryComponent(deviceId)}'),
    ]);
    final session = sessionId == null
        ? null
        : results[0] as Map<String, dynamic>;
    final history = results[1] as List<Map<String, dynamic>>;
    final settings = _cycleSettings[deviceId];
    final startedAt = _time(session?['startedAt']);
    return DeviceDetailData(
      deviceId: deviceId,
      isActive: session?['status'] == 'running',
      timeStarted: startedAt == null ? '—' : formatClock(startedAt),
      chamberTemperatureCelsius: _number(
        (device['lastReading'] as Map<String, dynamic>?)?['temperatureC'],
      ),
      thermalChargePercent: _number(device['thermalChargePercent']),
      loadCapacityKg: _number(session?['loadKg']),
      timeRemainingMinutes: (session?['timeRemainingMinutes'] as num?)?.toInt(),
      energySavedKwh: _number(session?['energySavedKWh']),
      fabricType: session?['fabricType'] as String? ?? settings?.fabricType,
      runtimeMinutes:
          (session?['runtimeMinutes'] as num?)?.toInt() ??
          settings?.runtimeMinutes ??
          0,
      operatingMode: _operatingModes[deviceId] ?? DeviceOperatingMode.automatic,
      history: [for (final item in history) _historyRecord(item)],
      sessionId: sessionId,
    );
  }

  @override
  Future<void> updateCycleSettings({
    required String deviceId,
    required DeviceCycleSettings settings,
  }) async {
    _cycleSettings[deviceId] = settings;
  }

  @override
  Future<void> updateOperatingMode({
    required String deviceId,
    required DeviceOperatingMode mode,
  }) async {
    _operatingModes[deviceId] = mode;
  }

  @override
  Future<DeviceManagementData> fetchManagementDetails(DeviceData device) async {
    final results = await Future.wait([
      _api.get(_devicePath(device.id)),
      _api.getList('/branches'),
    ]);
    final current = results[0] as Map<String, dynamic>;
    final branches = results[1] as List<Map<String, dynamic>>;
    final branchId = current['branchId'] as String?;
    final branch = branches
        .where((item) => item['branchId'] == branchId)
        .firstOrNull;
    final shown = _device(current);
    return DeviceManagementData(
      device: shown,
      serialId: shown.id,
      modelType: null,
      firmwareVersion: null,
      status: shown.status,
      pcmReservePercent: (current['thermalChargePercent'] as num?)?.toInt(),
      currentBranch: branch?['name'] as String? ?? 'Unassigned',
      availableBranches: [for (final item in branches) item['name'] as String],
    );
  }

  @override
  Future<void> updateDeviceName({
    required String deviceId,
    required String name,
  }) async {
    await _api.put(_devicePath(deviceId), {'displayName': name});
  }

  // The management page picks a branch by name; the API stores its ID.
  @override
  Future<void> updateDeviceBranch({
    required String deviceId,
    required String branchName,
  }) async {
    final branches = await _api.getList('/branches');
    final branch = branches
        .where((item) => item['name'] == branchName)
        .firstOrNull;
    if (branch == null) {
      throw const ApiException(
        404,
        'BRANCH_NOT_FOUND',
        'That branch no longer exists.',
      );
    }
    await _api.put(_devicePath(deviceId), {'branchId': branch['branchId']});
  }

  @override
  Future<void> unregisterDevice(String deviceId) async {
    await _api.delete(_devicePath(deviceId));
  }

  DeviceData _device(Map<String, dynamic> json) {
    final lastSeenAt = _time(json['lastSeenAt']);
    final sessionStartedAt = _time(json['activeSessionStartedAt']);
    final running = json['activeSessionId'] != null;
    return DeviceData(
      id: json['deviceId'] as String,
      name: json['displayName'] as String? ?? json['deviceId'] as String,
      status: json['online'] != true
          ? DeviceStatus.offline
          : running
          ? DeviceStatus.active
          : DeviceStatus.idle,
      temperatureCelsius: _number(
        (json['lastReading'] as Map<String, dynamic>?)?['temperatureC'],
      ),
      batteryPercent: (json['batteryPercent'] as num?)?.toInt(),
      cycleDuration: running && sessionStartedAt != null
          ? formatMinutes(_now().difference(sessionStartedAt).inMinutes)
          : formatMinutes(0),
      lastUpdated: lastSeenAt == null
          ? 'Never'
          : formatClockOrDate(lastSeenAt, now: _now()),
    );
  }

  // Sessions newer than a week ago are "past 7 days"; the history filter
  // includes earlier periods, so "past months" holds everything older.
  DeviceHistoryRecord _historyRecord(Map<String, dynamic> json) {
    final endedAt = _time(json['endedAt']) ?? _time(json['startedAt'])!;
    final now = _now().toLocal();
    final local = endedAt.toLocal();
    final today =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return DeviceHistoryRecord(
      fabricType: json['fabricType'] as String?,
      period: today
          ? DeviceHistoryPeriod.today
          : now.difference(local).inDays < 7
          ? DeviceHistoryPeriod.pastSevenDays
          : DeviceHistoryPeriod.pastMonths,
      temperatureCelsius: _number(json['avgTemperatureC']),
      thermalChargePercent: null,
      durationMinutes: ((json['durationSec'] as num?) ?? 0) ~/ 60,
      time: formatClockOrDate(endedAt, now: _now()),
    );
  }

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static double? _number(Object? value) => (value as num?)?.toDouble();
}
