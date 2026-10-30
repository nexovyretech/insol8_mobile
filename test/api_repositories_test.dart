import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:insol8_mobile/models/analytics_data.dart';
import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/services/api_branch_repository.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/api_device_repository.dart';
import 'package:insol8_mobile/services/api_insights_repository.dart';
import 'package:insol8_mobile/services/subscription_repository.dart';

typedef _Call = ({String method, String path, Map<String, dynamic>? body});

// Records each request and answers with the backend's { success, data } shape.
(ApiClient, List<_Call>) _api(Object? Function(_Call call) respond) {
  final calls = <_Call>[];
  final client = MockClient((request) async {
    final call = (
      method: request.method,
      path: request.url.hasQuery
          ? '${request.url.path}?${request.url.query}'
          : request.url.path,
      body: request.body.isEmpty
          ? null
          : jsonDecode(request.body) as Map<String, dynamic>,
    );
    calls.add(call);
    return http.Response(
      jsonEncode({'success': true, 'data': respond(call)}),
      200,
    );
  });
  return (
    ApiClient(
      client: client,
      baseUrl: 'https://api.test',
      accessToken: () async => 'test-token',
    ),
    calls,
  );
}

const _branchId = '6f1c2d3e-4a5b-4c6d-8e9f-0a1b2c3d4e5f';
final _now = DateTime.parse('2026-10-29T04:00:00Z');

Map<String, dynamic> _device({
  String id = 'DRYER-0001',
  bool online = true,
  String? sessionId,
  Map<String, dynamic>? lastReading,
}) => {
  'deviceId': id,
  'displayName': 'Dryer 1',
  'branchId': _branchId,
  'status': 'claimed',
  'activeSessionId': sessionId,
  'activeSessionStartedAt': sessionId == null ? null : '2026-10-29T03:42:00Z',
  'online': online,
  'lastSeenAt': '2026-10-29T03:59:30Z',
  'lastReading': lastReading,
  'batteryPercent': null,
  'thermalChargePercent': null,
};

void main() {
  group('ApiDeviceRepository', () {
    test('starts a job with its load and reads each dryer\'s limit', () async {
      final (api, calls) = _api(
        (call) => call.path == '/devices'
            ? [
                {..._device(), 'maxLoadKg': 8},
                _device(id: 'DRYER-0002'),
              ]
            : {'sessionId': 's1'},
      );
      final repository = ApiDeviceRepository(apiClient: api);
      final devices = await repository.fetchDevices();
      expect(devices.map((device) => device.maxLoadKg), [8, 8]);

      await repository.startDryingCycle(
        deviceId: 'DRYER-0001',
        settings: const DeviceCycleSettings(
          fabricType: 'Cotton',
          runtimeMinutes: 30,
          loadKg: 6.5,
        ),
      );
      expect(calls.last.method, 'POST');
      expect(calls.last.path, '/sessions');
      expect(calls.last.body, {
        'deviceId': 'DRYER-0001',
        'fabricType': 'Cotton',
        'runtimeMinutes': 30,
        'loadKg': 6.5,
      });
    });

    test('maps the device list, including status and cycle time', () async {
      final (api, calls) = _api(
        (_) => [
          _device(sessionId: 's1', lastReading: {'temperatureC': 58.4}),
          _device(id: 'DRYER-0002'),
          _device(id: 'DRYER-0003', online: false),
        ],
      );
      final devices = await ApiDeviceRepository(
        apiClient: api,
        clock: () => _now,
      ).fetchDevices();
      expect(calls.single.path, '/devices');
      expect(devices.map((device) => device.status), [
        DeviceStatus.active,
        DeviceStatus.idle,
        DeviceStatus.offline,
      ]);
      expect(devices.first.temperatureCelsius, 58.4);
      expect(devices.first.cycleDuration, '18mins');
      expect(devices.first.batteryPercent, isNull);
      expect(devices[1].temperatureCelsius, isNull);
      expect(devices[1].cycleDuration, '0min');
    });

    test('combines the device, its running session and its history', () async {
      final (api, calls) = _api(
        (call) => switch (call.path) {
          '/devices/DRYER-0001' => _device(
            sessionId: 's1',
            lastReading: {'temperatureC': 61},
          ),
          '/sessions/s1' => {
            'sessionId': 's1',
            'status': 'running',
            'startedAt': '2026-10-29T03:42:00Z',
            'fabricType': 'Cotton',
            'runtimeMinutes': 45,
            'loadKg': 6.5,
            'timeRemainingMinutes': 27,
            'energySavedKWh': null,
          },
          _ => [
            {
              'sessionId': 's0',
              'fabricType': null,
              'startedAt': '2026-10-28T01:00:00Z',
              'endedAt': '2026-10-28T02:00:00Z',
              'durationSec': 3600,
              'avgTemperatureC': 57.5,
            },
            {
              'sessionId': 's-old',
              'fabricType': 'Heavy',
              'startedAt': '2026-09-01T01:00:00Z',
              'endedAt': '2026-09-01T02:30:00Z',
              'durationSec': 5400,
              'avgTemperatureC': null,
            },
          ],
        },
      );
      final details = await ApiDeviceRepository(
        apiClient: api,
        clock: () => _now,
      ).fetchDeviceDetails('DRYER-0001');
      expect(calls.map((call) => call.path), [
        '/devices/DRYER-0001',
        '/sessions/s1',
        '/sessions?deviceId=DRYER-0001',
      ]);
      expect(details.isActive, isTrue);
      expect(details.sessionId, 's1');
      expect(details.chamberTemperatureCelsius, 61);
      expect(details.loadCapacityKg, 6.5);
      expect(details.timeRemainingMinutes, 27);
      expect(details.fabricType, 'Cotton');
      expect(details.runtimeMinutes, 45);
      expect(details.energySavedKwh, isNull);
      expect(details.thermalChargePercent, isNull);
      expect(details.history.map((record) => record.period), [
        DeviceHistoryPeriod.pastSevenDays,
        DeviceHistoryPeriod.pastMonths,
      ]);
      expect(details.history.first.temperatureCelsius, 57.5);
      expect(details.history.first.durationMinutes, 60);
      expect(details.history.last.time, 'Sep 1');
    });

    test('an idle device has no session to load', () async {
      final (api, calls) = _api(
        (call) => call.path.startsWith('/sessions') ? [] : _device(),
      );
      final details = await ApiDeviceRepository(apiClient: api)
          .fetchDeviceDetails('DRYER-0001');
      expect(calls.map((call) => call.path), [
        '/devices/DRYER-0001',
        '/sessions?deviceId=DRYER-0001',
      ]);
      expect(details.isActive, isFalse);
      expect(details.timeStarted, '—');
      expect(details.chamberTemperatureCelsius, isNull);
      expect(details.energySavedKwh, isNull);
    });

    test(
      'shows the energy saved the dryer last reported, without a session',
      () async {
        final (api, _) = _api(
          (call) => call.path.startsWith('/sessions')
              ? []
              : _device(
                  lastReading: {'temperatureC': 31.2, 'energySavedKWh': 0.527},
                ),
        );
        final details = await ApiDeviceRepository(apiClient: api)
            .fetchDeviceDetails('DRYER-0001');
        expect(details.chamberTemperatureCelsius, 31.2);
        expect(details.energySavedKwh, 0.527);
      },
    );

    test('renames, reassigns by branch name, and unregisters', () async {
      final (api, calls) = _api(
        (call) => call.path == '/branches'
            ? [
                {'branchId': _branchId, 'name': 'Camarin'},
              ]
            : _device(),
      );
      final repository = ApiDeviceRepository(apiClient: api);
      await repository.updateDeviceName(deviceId: 'DRYER-0001', name: 'Front');
      await repository.updateDeviceBranch(
        deviceId: 'DRYER-0001',
        branchName: 'Camarin',
      );
      await repository.unregisterDevice('DRYER-0001');
      // Lists, not records: records compare the request bodies by identity.
      expect(calls.map((call) => [call.method, call.path, call.body]), [
        [
          'PUT',
          '/devices/DRYER-0001',
          {'displayName': 'Front'},
        ],
        ['GET', '/branches', null],
        [
          'PUT',
          '/devices/DRYER-0001',
          {'branchId': _branchId},
        ],
        ['DELETE', '/devices/DRYER-0001', null],
      ]);
      await expectLater(
        repository.updateDeviceBranch(
          deviceId: 'DRYER-0001',
          branchName: 'Gone',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('management details name the current branch', () async {
      final (api, _) = _api(
        (call) => call.path == '/branches'
            ? [
                {'branchId': _branchId, 'name': 'Camarin'},
                {'branchId': 'other', 'name': 'Bagumbong'},
              ]
            : _device(),
      );
      final details = await ApiDeviceRepository(apiClient: api)
          .fetchManagementDetails(
            const DeviceData(
              id: 'DRYER-0001',
              name: 'Dryer 1',
              status: DeviceStatus.idle,
              temperatureCelsius: null,
              batteryPercent: null,
              cycleDuration: '0min',
              lastUpdated: '',
            ),
          );
      expect(details.currentBranch, 'Camarin');
      expect(details.availableBranches, ['Camarin', 'Bagumbong']);
      expect(details.serialId, 'DRYER-0001');
      expect(details.modelType, isNull);
      expect(details.pcmReservePercent, isNull);
    });
  });

  test('dashboard reads GET /dashboard as-is', () async {
    final (api, calls) = _api(
      (_) => {
        'loadsDriedToday': 3,
        'registeredUnits': 2,
        'activeBranches': 1,
        'totalBranches': 2,
        'energySavedKwh': 3,
        'energySavingsEstimatePhp': 24,
        'attentionItems': [
          {
            'deviceId': 'DRYER-0002',
            'deviceName': 'Dryer 2',
            'message': 'Unit has lost a connection',
            'type': 'connection',
          },
        ],
      },
    );
    final dashboard = await ApiDashboardRepository(apiClient: api)
        .fetchDashboard();
    expect(calls.single.path, '/dashboard');
    expect(dashboard.loadsDriedToday, 3);
    expect(dashboard.energySavingsEstimatePhp, 24);
    expect(dashboard.attentionItems.single.deviceName, 'Dryer 2');
  });

  test(
    'analytics sends the period and tolerates a missing heat split',
    () async {
      final (api, calls) = _api(
        (_) => {
          'loadsDried': 0,
          'averageDryingHours': 0,
          'moneySavedPhp': 0,
          'energySavedKwh': 0,
          'loadsByHour': List.filled(10, 0),
          'solarHeatPercent': null,
          'backupHeatPercent': null,
          'dryingTimeByPeriod': [
            {'label': 'Midday', 'minutes': 0},
            {'label': 'Other', 'minutes': 0},
          ],
          'dryerComparisons': [],
        },
      );
      final analytics = await ApiAnalyticsRepository(
        apiClient: api,
      ).fetchAnalytics(period: AnalyticsPeriod.thisWeek, branchId: _branchId);
      expect(
        calls.single.path,
        '/analytics?period=thisWeek&branchId=$_branchId',
      );
      expect(analytics.solarHeatPercent, isNull);
      expect(analytics.loadsByHour, hasLength(10));
    },
  );

  group('ApiBranchRepository', () {
    test(
      'counts each branch\'s dryers, running cycles and open state',
      () async {
        final (api, _) = _api(
          (call) => call.path == '/branches'
              ? [
                  {
                    'branchId': _branchId,
                    'name': 'Camarin',
                    'storeAddress': 'Camarin Rd.',
                    'managerOption': 'newManager',
                    'managerFirstName': 'Jane',
                    'managerLastName': 'Doe',
                  },
                  {
                    'branchId': 'empty',
                    'name': 'Bagumbong',
                    'storeAddress': 'Bagumbong Rd.',
                    'managerOption': 'myself',
                  },
                ]
              : [
                  _device(sessionId: 's1'),
                  _device(id: 'DRYER-0002', online: false),
                ],
        );
        final branches = await ApiBranchRepository(apiClient: api)
            .fetchBranches();
        expect(branches.first.name, 'CAMARIN');
        expect(branches.first.managerName, 'Jane Doe');
        expect(branches.first.dryerCount, 2);
        expect(branches.first.activeCycles, 1);
        expect(branches.first.isOpen, isTrue);
        expect(branches.first.deviceIds, ['DRYER-0001', 'DRYER-0002']);
        expect(branches.last.dryerCount, 0);
        expect(branches.last.isOpen, isFalse);
        expect(branches.last.managerName, 'You');
      },
    );

    test('creates a branch from what the user entered', () async {
      final (api, calls) = _api((_) => {'branchId': _branchId});
      await ApiBranchRepository(apiClient: api).createBranch(
        const BranchData(
          id: 'local',
          name: 'CAMARIN',
          address: 'Camarin Rd.',
          managerName: 'Me',
          dryerCount: 0,
          activeCycles: 0,
          isOpen: true,
          setup: BranchSetupData(
            name: 'Camarin',
            address: 'Camarin Rd.',
            managerOption: BranchManagerOption.myself,
          ),
        ),
      );
      expect(calls.single.body, {
        'name': 'Camarin',
        'storeAddress': 'Camarin Rd.',
        'managerOption': 'myself',
      });
    });
  });

  group('ApiSubscriptionRepository', () {
    test('reads the paid plan from GET /onboarding', () async {
      final (api, calls) = _api(
        (_) => {
          'onboarding': const <String, dynamic>{},
          'status': {
            'subscription': {
              'status': 'active',
              'activePlanId': 'organization',
            },
          },
        },
      );
      final planId = await ApiSubscriptionRepository(apiClient: api)
          .fetchActivePlanId();
      expect(calls.single.path, '/onboarding');
      expect(planId, SubscriptionPlanIds.organization);
    });

    test('is null while the plan is unpaid', () async {
      final (api, _) = _api(
        (_) => {
          'status': {
            'subscription': {
              'status': 'pending_payment',
              'selectedPlanId': 'organization',
              'activePlanId': null,
            },
          },
        },
      );
      expect(
        await ApiSubscriptionRepository(apiClient: api).fetchActivePlanId(),
        isNull,
      );
    });
  });
}
