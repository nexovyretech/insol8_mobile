import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/pages/devices/device_detail_page.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/device_repository.dart';
import 'package:insol8_mobile/services/live_telemetry.dart';

class _SignedIn extends UnconfiguredAuthRepository {
  @override
  Future<bool> hasActiveSession() async => true;
}

// Counts detail loads so the test can tell a live update from a page reload.
// The page calls nothing else on the repository here.
class _CountingDevices implements DeviceRepository {
  int loads = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<DeviceDetailData> fetchDeviceDetails(String deviceId) async {
    loads += 1;
    return const DeviceDetailData(
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
  }
}

class _FakeLive implements LiveTelemetrySource {
  final controller = StreamController<LiveTelemetryBatch>();

  @override
  Stream<LiveTelemetryBatch> watch(String deviceId) => controller.stream;
}

LiveTelemetryBatch _message(String? sessionId, double celsius, double saved) =>
    LiveTelemetryBatch(
      deviceId: 'INSOL8_01',
      sessionId: sessionId,
      readings: [
        {
          'recordedAt': '2026-10-29T00:00:00Z',
          'temperatureC': celsius,
          'energySavedKWh': saved,
        },
      ],
    );

void main() {
  testWidgets(
    'live messages update temperature and energy saved without reloading',
    (tester) async {
      final devices = _CountingDevices();
      final live = _FakeLive();
      await tester.pumpWidget(
        MaterialApp(
          home: DeviceDetailPage(
            device: const DeviceData(
              id: 'INSOL8_01',
              name: 'Real Dryer',
              status: DeviceStatus.idle,
              temperatureCelsius: 31,
              batteryPercent: null,
              cycleDuration: '0min',
              lastUpdated: '',
            ),
            authRepository: _SignedIn(),
            deviceRepository: devices,
            liveTelemetry: live,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('31°C'), findsOneWidget);
      expect(find.text('0.50kWh'), findsOneWidget);

      // The dryer keeps reporting a session the backend did not start; that
      // alone must not reload the page on every message.
      for (final (celsius, saved) in [(32.5, 0.527), (33.0, 0.531)]) {
        live.controller.add(_message('job-8f2a', celsius, saved));
        await tester.pumpAndSettle();
      }
      expect(find.text('33°C'), findsOneWidget);
      expect(find.text('0.53kWh'), findsOneWidget);
      expect(devices.loads, 1);

      // A change of session between messages (a cycle started) reloads.
      live.controller.add(_message('new-session', 34, 0));
      await tester.pumpAndSettle();
      expect(devices.loads, 2);

      await live.controller.close();
    },
  );
}
