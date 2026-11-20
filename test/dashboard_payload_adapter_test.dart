import 'package:flutter_test/flutter_test.dart';

import 'package:insol8_mobile/models/dashboard_data.dart';
import 'package:insol8_mobile/services/dashboard_payload_adapter.dart';

const _canonicalPayload = <String, dynamic>{
  'loadsDriedToday': 18,
  'registeredUnits': 14,
  'activeBranches': 3,
  'totalBranches': 3,
  'energySavedKwh': 12,
  'energySavingsEstimatePhp': 150,
  'attentionItems': <dynamic>[],
};

void main() {
  const adapter = DashboardPayloadAdapter();

  test('old payloads keep the Figma design defaults', () {
    final data = adapter.map(_canonicalPayload);

    expect(data.runningDryers, 2);
    expect(data.readyToDry, 4);
    expect(data.moneyEarnedTodayPhp, 2450);
    expect(data.dryingJobs, same(defaultDashboardDryingJobs));
    expect(data.branchActivity, same(defaultDashboardBranchActivity));
  });

  test('new backend keys are used when present', () {
    final data = adapter.map(<String, dynamic>{
      ..._canonicalPayload,
      'runningDryers': 5,
      'readyToDry': 7,
      'moneyEarnedTodayPhp': 3210,
      'dryingJobs': <dynamic>[
        <String, dynamic>{
          'dryerName': 'DRYER 09',
          'loadKg': 4.2,
          'remainingMinutes': 18,
          'status': 'Running',
        },
      ],
      'branchActivity': <dynamic>[
        <String, dynamic>{
          'number': 4,
          'name': 'Branch 4',
          'location': 'Makati',
          'time': '10:10 AM',
        },
      ],
    });

    expect(data.runningDryers, 5);
    expect(data.readyToDry, 7);
    expect(data.moneyEarnedTodayPhp, 3210);
    expect(data.dryingJobs.single.dryerName, 'DRYER 09');
    expect(data.branchActivity.single.location, 'Makati');
  });

  test('common backend aliases are bridged into the UI model', () {
    final data = adapter.map(<String, dynamic>{
      'loadsToday': 7,
      'deviceCount': 10,
      'activeBranches': 1,
      'totalBranches': 2,
      'energySaved': 4.5,
      'energySavingsEstimate': 50,
      'alerts': <dynamic>[
        <String, dynamic>{
          'id': 'DRYER-1',
          'name': 'Dryer 1',
          'description': 'Unit has low battery',
          'kind': 'battery',
        },
      ],
      'dryingNow': 1,
      'availableDryers': 3,
      'earningsTodayPhp': 999,
      'currentDryingJobs': <dynamic>[
        <String, dynamic>{
          'name': 'DRYER 01',
          'load': 2.5,
          'remaining': 10,
          'state': 'Running',
        },
      ],
      'firstRecordedJobs': <dynamic>[
        <String, dynamic>{
          'index': 1,
          'branchName': 'Main',
          'city': 'Cebu',
          'recordedAt': '7:30 AM',
        },
      ],
    });

    expect(data.loadsDriedToday, 7);
    expect(data.registeredUnits, 10);
    expect(data.energySavedKwh, 4.5);
    expect(data.attentionItems.single.type, DashboardAttentionType.battery);
    expect(data.attentionItems.single.deviceName, 'Dryer 1');
    expect(data.runningDryers, 1);
    expect(data.readyToDry, 3);
    expect(data.moneyEarnedTodayPhp, 999);
    expect(data.dryingJobs.single.loadKg, 2.5);
    expect(data.branchActivity.single.name, 'Main');
    expect(data.branchActivity.single.time, '7:30 AM');
  });

  test('missing original fields still fail clearly', () {
    expect(
      () => adapter.map(<String, dynamic>{'loadsDriedToday': 1}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('registeredUnits'),
        ),
      ),
    );
  });
}
