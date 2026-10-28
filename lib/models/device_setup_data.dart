class DevicePairingRequest {
  const DevicePairingRequest({required this.deviceCode});

  final String deviceCode;
}

class DeviceVerificationRequest {
  const DeviceVerificationRequest({required this.deviceCode});

  final String deviceCode;
}

class DeviceSetupData {
  const DeviceSetupData({
    required this.deviceCode,
    required this.deviceName,
    this.branchId,
  });

  final String deviceCode;
  final String deviceName;

  /// The branch created during onboarding; null leaves the device unassigned.
  final String? branchId;
}
