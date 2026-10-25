class DevicePairingRequest {
  const DevicePairingRequest({
    required this.deviceCode,
    required this.branchName,
  });

  final String deviceCode;
  final String branchName;
}

class DeviceVerificationRequest {
  const DeviceVerificationRequest({required this.deviceCode});

  final String deviceCode;
}

class DeviceSetupData {
  const DeviceSetupData({
    required this.deviceCode,
    required this.deviceName,
    required this.branchName,
  });

  final String deviceCode;
  final String deviceName;
  final String branchName;
}
