import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/models/device_management_data.dart';

/// Data boundary for the device list. The API adapter should map its response
/// into [DeviceData] after the device endpoint contract is agreed.
abstract interface class DeviceRepository {
  Future<List<DeviceData>> fetchDevices();

  Future<DeviceDetailData> fetchDeviceDetails(String deviceId);

  Future<void> updateCycleSettings({
    required String deviceId,
    required DeviceCycleSettings settings,
  });

  Future<void> updateOperatingMode({
    required String deviceId,
    required DeviceOperatingMode mode,
  });

  Future<DeviceManagementData> fetchManagementDetails(DeviceData device);

  Future<void> updateDeviceName({
    required String deviceId,
    required String name,
  });

  Future<void> updateDeviceBranch({
    required String deviceId,
    required String branchName,
  });

  Future<void> unregisterDevice(String deviceId);
}

/// Local device fixtures used for UI preview until the device API is connected.
class MockDeviceRepository implements DeviceRepository {
  const MockDeviceRepository();

  // Shared preview state lets separate pages/repository instances see changes
  // made to the same device until the API adapter replaces this mock.
  static final Map<String, String> _deviceNames = {};
  static final Map<String, String> _deviceBranches = {};
  static final Map<String, DeviceCycleSettings> _cycleSettings = {};
  static final Map<String, DeviceOperatingMode> _operatingModes = {};
  static final Set<String> _unregisteredDeviceIds = {};

  @override
  Future<List<DeviceData>> fetchDevices() async => List.generate(14, (index) {
    final unitNumber = index + 1;
    final deviceId = 'dryer-${unitNumber.toString().padLeft(2, '0')}';
    final isIdle = unitNumber == 2 || unitNumber == 3;
    return DeviceData(
      id: deviceId,
      name:
          _deviceNames[deviceId] ??
          'DRYER UNIT ${unitNumber.toString().padLeft(2, '0')}',
      status: isIdle ? DeviceStatus.idle : DeviceStatus.active,
      temperatureCelsius: isIdle ? 48 : 62,
      batteryPercent: 91,
      cycleDuration: isIdle ? '0min' : '18mins',
      lastUpdated: '12:34 PM',
    );
  }).where((device) => !_unregisteredDeviceIds.contains(device.id)).toList();

  @override
  Future<DeviceDetailData> fetchDeviceDetails(String deviceId) async {
    final settings = _cycleSettings[deviceId];
    return DeviceDetailData(
      deviceId: deviceId,
      isActive: true,
      timeStarted: '12:34 PM',
      chamberTemperatureCelsius: 68,
      thermalChargePercent: 91,
      loadCapacityKg: 8,
      timeRemainingMinutes: 18,
      energySavedKwh: 12,
      fabricType: settings?.fabricType ?? 'Cotton',
      runtimeMinutes: settings?.runtimeMinutes ?? 0,
      operatingMode: _operatingModes[deviceId] ?? DeviceOperatingMode.automatic,
      history: const [
        DeviceHistoryRecord(
          fabricType: 'Cotton',
          period: DeviceHistoryPeriod.today,
          temperatureCelsius: 62,
          thermalChargePercent: 91,
          durationMinutes: 18,
          time: '12:34 PM',
        ),
        DeviceHistoryRecord(
          fabricType: 'Synthetics',
          period: DeviceHistoryPeriod.pastSevenDays,
          temperatureCelsius: 62,
          thermalChargePercent: 91,
          durationMinutes: 18,
          time: '12:34 PM',
        ),
        DeviceHistoryRecord(
          fabricType: 'Heavy',
          period: DeviceHistoryPeriod.pastMonths,
          temperatureCelsius: 62,
          thermalChargePercent: 91,
          durationMinutes: 18,
          time: '12:34 PM',
        ),
        DeviceHistoryRecord(
          fabricType: 'Delicates',
          period: DeviceHistoryPeriod.pastMonths,
          temperatureCelsius: 62,
          thermalChargePercent: 91,
          durationMinutes: 18,
          time: '12:34 PM',
        ),
      ],
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
    final currentDevice = DeviceData(
      id: device.id,
      name: _deviceNames[device.id] ?? device.name,
      status: device.status,
      temperatureCelsius: device.temperatureCelsius,
      batteryPercent: device.batteryPercent,
      cycleDuration: device.cycleDuration,
      lastUpdated: device.lastUpdated,
    );
    return DeviceManagementData(
      device: currentDevice,
      serialId: 'INSOL8-DRY-0941',
      modelType: 'PCM Solar Thermal Hybrid',
      firmwareVersion: 'v2.4.1 (up to date)',
      status: device.status,
      pcmReservePercent: 94,
      currentBranch: _deviceBranches[device.id] ?? 'Camarin',
      availableBranches: const ['Bagumbong', 'Bagong Silang', 'Camarin'],
    );
  }

  @override
  Future<void> updateDeviceName({
    required String deviceId,
    required String name,
  }) async {
    _deviceNames[deviceId] = name;
  }

  @override
  Future<void> updateDeviceBranch({
    required String deviceId,
    required String branchName,
  }) async {
    _deviceBranches[deviceId] = branchName;
  }

  @override
  Future<void> unregisterDevice(String deviceId) async {
    _unregisteredDeviceIds.add(deviceId);
  }
}
