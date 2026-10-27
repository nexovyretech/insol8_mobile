import 'package:insol8_mobile/models/device_data.dart';

class DeviceManagementData {
  const DeviceManagementData({
    required this.device,
    required this.serialId,
    required this.modelType,
    required this.firmwareVersion,
    required this.status,
    required this.pcmReservePercent,
    required this.currentBranch,
    required this.availableBranches,
  });

  factory DeviceManagementData.fromJson(Map<String, dynamic> json) =>
      DeviceManagementData(
        device: DeviceData.fromJson(json['device'] as Map<String, dynamic>),
        serialId: json['serialId'] as String,
        modelType: json['modelType'] as String,
        firmwareVersion: json['firmwareVersion'] as String,
        status: DeviceStatus.values.firstWhere(
          (status) => status.name == json['status'],
          orElse: () => DeviceStatus.offline,
        ),
        pcmReservePercent: (json['pcmReservePercent'] as num).toInt(),
        currentBranch: json['currentBranch'] as String,
        availableBranches: (json['availableBranches'] as List<dynamic>)
            .cast<String>(),
      );

  final DeviceData device;
  final String serialId;
  final String modelType;
  final String firmwareVersion;
  final DeviceStatus status;
  final int pcmReservePercent;
  final String currentBranch;
  final List<String> availableBranches;
}

class DeviceManagementResult {
  const DeviceManagementResult({
    required this.deviceName,
    this.unregistered = false,
  });

  final String deviceName;
  final bool unregistered;
}
