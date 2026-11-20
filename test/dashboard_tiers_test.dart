import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insol8_mobile/models/dashboard_data.dart';
import 'package:insol8_mobile/pages/home/dashboard_widgets.dart';

const _data = DashboardData(
  loadsDriedToday: 18,
  registeredUnits: 14,
  activeBranches: 3,
  totalBranches: 3,
  energySavedKwh: 12,
  energySavingsEstimatePhp: 150,
  attentionItems: [],
);

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('Basic dashboard uses the Basic tier labels and order', (
    tester,
  ) async {
    await _pump(tester, const DashboardMetricGrid(data: _data));

    expect(find.text('Drying now'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Currently running'), findsOneWidget);
    expect(find.text('Ready to dry'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Available dryers'), findsOneWidget);
    expect(find.text('Loads dried today'), findsOneWidget);
    expect(find.text('18 loads, up from yesterday'), findsOneWidget);
    expect(find.text('12 kWh saved, about ₱150.00'), findsOneWidget);
    expect(find.text('Registered units'), findsNothing);
  });

  testWidgets('Org dashboard uses the Organization tier labels', (
    tester,
  ) async {
    await _pump(
      tester,
      const DashboardMetricGrid(data: _data, organizationPlan: true),
    );

    expect(find.text('Energy saved today'), findsOneWidget);
    expect(find.text('12 kWh saved in all branches'), findsOneWidget);
    expect(find.text('Money earned today'), findsOneWidget);
    expect(find.text('₱2,450'), findsOneWidget);
    expect(find.text('All Branches'), findsOneWidget);
    expect(find.text('Active branches'), findsOneWidget);
    expect(find.text('3 of 3'), findsOneWidget);
    expect(find.text('Open branches'), findsOneWidget);
    expect(find.text('Loads dried today'), findsOneWidget);
    expect(find.text('Ready to dry'), findsNothing);
  });

  testWidgets('Quick action and tier lists match the screenshots', (
    tester,
  ) async {
    await _pump(
      tester,
      Column(
        children: [
          DashboardQuickActions(onAddJob: () {}),
          DashboardDryingJobList(jobs: defaultDashboardDryingJobs),
          DashboardBranchList(branches: defaultDashboardBranchActivity),
        ],
      ),
    );

    expect(find.text('New drying job'), findsOneWidget);
    expect(find.text('Create a new drying session'), findsOneWidget);
    expect(find.byIcon(Icons.sunny), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.text('Load: 3.4 kg • Remaining: 25 min'), findsOneWidget);
    expect(find.text('Load: 2.8 kg • Remaining: 12 min'), findsOneWidget);
    expect(find.text('Caloocan'), findsOneWidget);
    expect(find.text('Quezon City'), findsOneWidget);
    expect(find.text('8:15 AM'), findsOneWidget);
    expect(find.text('9:02 AM'), findsOneWidget);
  });

  testWidgets('Needs Attention uses the screenshot labels without dividers', (
    tester,
  ) async {
    await _pump(
      tester,
      DashboardAttentionList(
        items: const [
          DashboardAttentionItem(
            deviceId: '02',
            deviceName: 'Dryer Unit 02',
            message: 'Unit has lost a connection',
            type: DashboardAttentionType.connection,
          ),
          DashboardAttentionItem(
            deviceId: '14',
            deviceName: 'Dryer Unit 14',
            message: 'Unit has low battery',
            type: DashboardAttentionType.battery,
          ),
        ],
      ),
    );

    expect(find.text('DRYER UNIT 02'), findsOneWidget);
    expect(find.text('Unit has lost a connection'), findsOneWidget);
    expect(find.text('DRYER UNIT 14'), findsOneWidget);
    expect(find.text('Unit has low battery'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Divider), findsNothing);
  });
}
