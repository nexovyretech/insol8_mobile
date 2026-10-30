import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/models/device_management_data.dart';
import 'package:insol8_mobile/pages/devices/device_detail_page.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';

class _SignedIn extends UnconfiguredAuthRepository {
  @override
  Future<bool> hasActiveSession() async => true;
}

const _device = DeviceData(
  id: 'INSOL8_01',
  name: 'Real Dryer',
  status: DeviceStatus.idle,
  temperatureCelsius: 31,
  batteryPercent: null,
  cycleDuration: '0min',
  lastUpdated: '',
);

// Only what the detail and management pages call here.
class _Devices implements DeviceRepository {
  _Devices({this.hasRunningJob = false, this.refuseUnregister = false});

  final bool hasRunningJob;

  /// Answers the unregister like the backend does when a job started after
  /// the page loaded.
  final bool refuseUnregister;
  final unregistered = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<DeviceDetailData> fetchDeviceDetails(String deviceId) async =>
      const DeviceDetailData(
        deviceId: 'INSOL8_01',
        isActive: false,
        timeStarted: '—',
        chamberTemperatureCelsius: 31,
        thermalChargePercent: null,
        loadCapacityKg: null,
        timeRemainingMinutes: null,
        energySavedKwh: 0.5,
        fabricType: null,
        runtimeMinutes: 0,
        operatingMode: DeviceOperatingMode.automatic,
        history: [],
      );

  @override
  Future<DeviceManagementData> fetchManagementDetails(DeviceData device) async =>
      DeviceManagementData(
        device: device,
        serialId: device.id,
        modelType: null,
        firmwareVersion: null,
        status: DeviceStatus.idle,
        pcmReservePercent: null,
        currentBranch: 'Unassigned',
        availableBranches: const [],
        hasRunningJob: hasRunningJob,
      );

  @override
  Future<void> unregisterDevice(String deviceId) async {
    if (refuseUnregister) {
      throw const ApiException(409, 'SESSION_RUNNING', 'Stop the job first.');
    }
    unregistered.add(deviceId);
  }
}

Future<void> _openManagement(WidgetTester tester, _Devices devices) async {
  await tester.pumpWidget(
    MaterialApp(
      home: DeviceDetailPage(
        device: _device,
        authRepository: _SignedIn(),
        deviceRepository: devices,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Device management'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Unregister Device'));
  await tester.tap(find.text('Unregister Device'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the header icon opens device management, and unregistering closes the device page with true',
    (tester) async {
      final devices = _Devices();
      Object? closedWith;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                closedWith = await Navigator.of(context).push<Object?>(
                  MaterialPageRoute<Object?>(
                    builder: (_) => DeviceDetailPage(
                      device: _device,
                      authRepository: _SignedIn(),
                      deviceRepository: devices,
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Device management'));
      await tester.pumpAndSettle();
      expect(find.text('Device Management'), findsOneWidget);

      await tester.ensureVisible(find.text('Unregister Device'));
      await tester.tap(find.text('Unregister Device'));
      await tester.pumpAndSettle();
      // Confirm in the dialog.
      await tester.tap(find.text('Unregister Device').last);
      await tester.pumpAndSettle();

      expect(devices.unregistered, ['INSOL8_01']);
      // The devices list removes the dryer when its page closes with true.
      expect(closedWith, true);
      expect(find.text('Open'), findsOneWidget);
    },
  );

  testWidgets('a dryer with a running job asks the user to stop it first', (
    tester,
  ) async {
    final devices = _Devices(hasRunningJob: true);
    await _openManagement(tester, devices);
    expect(find.text('Stop the Job First'), findsOneWidget);
    // No unregister confirmation is offered.
    expect(find.text('Unregister Device?'), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(devices.unregistered, isEmpty);
    expect(find.text('Device Management'), findsOneWidget);
  });

  testWidgets('a job started after the page loaded is caught by the backend', (
    tester,
  ) async {
    final devices = _Devices(refuseUnregister: true);
    await _openManagement(tester, devices);
    await tester.tap(find.text('Unregister Device').last);
    await tester.pumpAndSettle();
    expect(find.text('Stop the Job First'), findsOneWidget);
    expect(find.text('Device Management'), findsOneWidget);
  });
}
