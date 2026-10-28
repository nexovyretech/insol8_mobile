import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/device_setup_data.dart';
import 'package:insol8_mobile/models/subscription_plan.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/api_onboarding_repository.dart';

typedef _Call = ({String method, String path, Map<String, dynamic>? body});

// Records each request and answers with the backend's { success, data } shape.
(ApiOnboardingRepository, List<_Call>) _repository(
  Object? Function(_Call call) respond, {
  int status = 200,
}) {
  final calls = <_Call>[];
  final client = MockClient((request) async {
    final call = (
      method: request.method,
      path: request.url.path,
      body: request.body.isEmpty
          ? null
          : jsonDecode(request.body) as Map<String, dynamic>,
    );
    calls.add(call);
    expect(request.headers['authorization'], 'Bearer test-token');
    final data = respond(call);
    return http.Response(
      jsonEncode(
        status < 300
            ? {'success': true, 'data': data}
            : {'success': false, 'error': data},
      ),
      status,
    );
  });
  final api = ApiClient(
    client: client,
    baseUrl: 'https://api.test',
    accessToken: () async => 'test-token',
  );
  return (ApiOnboardingRepository(apiClient: api), calls);
}

void main() {
  test('reads plans with prices in pesos and their plan limits', () async {
    final (repo, calls) = _repository(
      (_) => {
        'plans': [
          {
            'id': 'basic',
            'name': 'Basic tier',
            'amount': 25000,
            'description': 'For single laundry shops.',
            'features': ['Device monitoring'],
            'entitlements': {'maxBranches': 1, 'assignManagers': false},
          },
          {
            'id': 'organization',
            'name': 'Organization tier',
            'amount': 50000,
            'description': 'For multi-branch businesses.',
            'features': ['Multiple branch registration'],
            'entitlements': {'maxBranches': null, 'assignManagers': true},
          },
        ],
      },
    );
    final plans = await repo.fetchSubscriptionPlans();
    expect(calls.single.path, '/billing/plans');
    expect(plans.map((plan) => plan.id), ['basic', 'organization']);
    expect(plans[0].price, 250);
    expect(plans[0].maxBranches, 1);
    expect(plans[0].canAssignManagers, isFalse);
    expect(plans[1].price, 500);
    expect(plans[1].maxBranches, isNull);
    expect(plans[1].canAssignManagers, isTrue);
  });

  test('starts checkout with the API plan id and payment method', () async {
    final (repo, calls) = _repository(
      (_) => {
        'referenceNumber': 'INSOL8-ref-1',
        'checkoutUrl': 'https://checkout.paymongo.test/cs_1',
        'paymentStatus': 'pending',
      },
    );
    final session = await repo.createCheckoutSession(
      planId: 'organization',
      paymentMethod: SubscriptionPaymentMethod.maya,
    );
    expect(calls.single.method, 'POST');
    expect(calls.single.path, '/billing/checkout');
    expect(calls.single.body, {
      'subscriptionPlanId': 'organization',
      'paymentMethod': 'maya',
    });
    expect(session.reference, 'INSOL8-ref-1');
    expect(
      session.checkoutUrl.toString(),
      'https://checkout.paymongo.test/cs_1',
    );
  });

  test('treats a checkout without a payment page as a failure', () async {
    final (repo, _) = _repository((_) => {'referenceNumber': 'INSOL8-ref-1'});
    await expectLater(
      repo.createCheckoutSession(
        planId: 'basic',
        paymentMethod: SubscriptionPaymentMethod.gcash,
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('reports a payment as confirmed only for its own reference', () async {
    final (repo, calls) = _repository(
      (_) => {
        'onboarding': {'userSub': 'u1', 'primaryBranchId': 'branch-1'},
        'status': {
          'complete': false,
          'missingSteps': ['device_registration'],
          'subscription': {
            'status': 'active',
            'activePlanId': 'basic',
            'currentPeriodEnd': '2026-11-28T00:00:00.000Z',
            'lastPaidReference': 'INSOL8-ref-1',
          },
        },
      },
    );
    final status = await repo.fetchOnboardingStatus();
    expect(calls.single.path, '/onboarding');
    expect(status.isPaid('INSOL8-ref-1'), isTrue);
    expect(status.isPaid('INSOL8-other'), isFalse);
    expect(status.primaryBranchId, 'branch-1');
    expect(status.missingSteps, ['device_registration']);
    expect(status.currentPeriodEnd, DateTime.utc(2026, 11, 28));
  });

  test('creates a branch and returns its id', () async {
    final (repo, calls) = _repository(
      (_) => {'branchId': '6f1c2d3e-4a5b-4c6d-8e9f-0a1b2c3d4e5f'},
    );
    final id = await repo.createBranch(
      const BranchSetupData(
        name: 'Main Branch',
        address: '12 Rizal St',
        managerOption: BranchManagerOption.newManager,
        managerFirstName: 'Ana',
        managerLastName: 'Cruz',
      ),
    );
    expect(id, '6f1c2d3e-4a5b-4c6d-8e9f-0a1b2c3d4e5f');
    expect(calls.single.path, '/branches');
    expect(calls.single.body, {
      'name': 'Main Branch',
      'storeAddress': '12 Rizal St',
      'managerOption': 'newManager',
      'managerFirstName': 'Ana',
      'managerLastName': 'Cruz',
    });
  });

  test('sends no manager names when the owner manages the branch', () async {
    final (repo, calls) = _repository((_) => {'branchId': 'b'});
    await repo.createBranch(
      const BranchSetupData(
        name: 'Main',
        address: '1 Road',
        managerOption: BranchManagerOption.myself,
        managerFirstName: 'ignored',
      ),
    );
    expect(calls.single.body, {
      'name': 'Main',
      'storeAddress': '1 Road',
      'managerOption': 'myself',
    });
  });

  test(
    'checks a device code, then links it with its name and branch',
    () async {
      final (repo, calls) = _repository((_) => {'deviceId': 'DRYER-0001'});
      await repo.pairDevice(
        const DevicePairingRequest(deviceCode: 'DRYER-0001'),
      );
      await repo.configureDevice(
        const DeviceSetupData(
          deviceCode: 'DRYER-0001',
          deviceName: 'Front dryer',
          branchId: 'branch-1',
        ),
      );
      expect(calls[0].path, '/devices/verify');
      expect(calls[0].body, {'deviceCode': 'DRYER-0001'});
      expect(calls[1].path, '/devices');
      expect(calls[1].body, {
        'deviceCode': 'DRYER-0001',
        'deviceName': 'Front dryer',
        'branchId': 'branch-1',
      });
    },
  );

  test('asks the backend to confirm a checkout with PayMongo', () async {
    final (repo, calls) = _repository(
      (call) => {
        'referenceNumber': 'INSOL8-ref-1',
        'paymentStatus': call.path.contains('ref-1') ? 'paid' : 'pending',
      },
    );
    expect(await repo.confirmPayment('INSOL8-ref-1'), isTrue);
    expect(await repo.confirmPayment('INSOL8-ref-2'), isFalse);
    expect(calls.first.method, 'POST');
    expect(calls.first.path, '/billing/checkout/INSOL8-ref-1/confirm');
  });

  test('passes backend error codes through', () async {
    final (repo, _) = _repository(
      (_) => {'code': 'DEVICE_UNAVAILABLE', 'message': 'Taken.'},
      status: 409,
    );
    await expectLater(
      repo.verifyDevice(const DeviceVerificationRequest(deviceCode: 'DRYER-1')),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.code, 'code', 'DEVICE_UNAVAILABLE'),
      ),
    );
  });
}
