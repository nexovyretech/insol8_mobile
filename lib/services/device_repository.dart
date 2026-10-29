import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/models/device_management_data.dart';

/// Data boundary for devices; [ApiDeviceRepository] in the app.
abstract interface class DeviceRepository {
  Future<List<DeviceData>> fetchDevices();

  Future<DeviceDetailData> fetchDeviceDetails(String deviceId);

  Future<void> updateCycleSettings({
    required String deviceId,
    required DeviceCycleSettings settings,
  });

  /// Starts one drying session with the selected fabric and runtime.
  Future<void> startDryingCycle({
    required String deviceId,
    required DeviceCycleSettings settings,
  });

  /// Stops the active drying session for [deviceId].
  Future<void> stopDryingCycle({required String deviceId});

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
