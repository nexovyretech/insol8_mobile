import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/branch_data.dart';
import 'package:insol8_mobile/models/manager_data.dart';
import 'package:insol8_mobile/pages/settings/managers/add_manager_page.dart';
import 'package:insol8_mobile/pages/settings/managers/manager_access_page.dart';
import 'package:insol8_mobile/pages/settings/managers/manager_management_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/branch_repository.dart';
import 'package:insol8_mobile/theme/app_colors.dart';

typedef _Update = ({String branchId, String? firstName, String? lastName});

class _FakeBranchRepository implements BranchRepository {
  _FakeBranchRepository(this.branches);

  final List<BranchData> branches;
  final updates = <_Update>[];
  Object? updateError;

  @override
  Future<List<BranchData>> fetchBranches() async => branches;

  @override
  Future<void> createBranch(BranchData branch) async {}

  @override
  Future<void> updateBranchManager({
    required String branchId,
    required String? firstName,
    required String? lastName,
  }) async {
    if (updateError != null) throw updateError!;
    updates.add((branchId: branchId, firstName: firstName, lastName: lastName));
  }
}

BranchData _branch(
  String id,
  String name, {
  String? firstName,
  String? lastName,
  String? email,
  String? status,
}) => BranchData(
  id: id,
  name: name.toUpperCase(),
  address: '$name Rd.',
  managerName: firstName == null ? 'You' : '$firstName $lastName',
  dryerCount: 0,
  activeCycles: 0,
  isOpen: false,
  managerOption: firstName == null ? 'myself' : 'newManager',
  managerFirstName: firstName,
  managerLastName: lastName,
  managerEmail: email,
  managerStatus: status,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pumpAndSettle();
}

Finder _field(String hint) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == hint,
);

void main() {
  testWidgets('lists managers grouped from branch records', (tester) async {
    final repo = _FakeBranchRepository([
      _branch(
        'b1',
        'Caloocan Branch',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'janedoe@email.com',
        status: 'active',
      ),
      _branch(
        'b2',
        'Manila Branch',
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'juandelacruz@email.com',
        status: 'invitation_pending',
      ),
      _branch('b3', 'Quezon City Branch'),
    ]);
    await _pump(tester, ManagerManagementPage(branchRepository: repo));

    expect(find.text('Manager Management'), findsOneWidget);
    expect(
      find.text('Manage your branch and their access permissions.'),
      findsOneWidget,
    );
    expect(find.text('Add Manager'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('janedoe@email.com'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Caloocan Branch'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('juandelacruz@email.com'), findsOneWidget);
    expect(find.text('Invitation Pending'), findsOneWidget);
    expect(find.text('Manila Branch'), findsOneWidget);
    // Owner-managed branches are not shown as separate managers.
    expect(find.text('You'), findsNothing);

    // First-page cards now use the shared Settings frame: white + soft shadow.
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final decoration = widget.decoration! as BoxDecoration;
        return decoration.color == AppColors.surface &&
            decoration.borderRadius == BorderRadius.circular(16) &&
            decoration.boxShadow?.isNotEmpty == true;
      }),
      findsNWidgets(2),
    );
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('edit icon and Add Manager button are tappable', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeBranchRepository([
      _branch(
        'b1',
        'Caloocan Branch',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'janedoe@email.com',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ManagerManagementPage(branchRepository: repo),
        routes: {
          AppRoutes.managerAccess: (_) => const Text('Access page'),
          AppRoutes.addManager: (_) => const Text('Add page'),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit Jane Doe'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit Jane Doe'));
    await tester.pumpAndSettle();
    expect(find.text('Access page'), findsOneWidget);

    Navigator.of(tester.element(find.text('Access page'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Manager'));
    await tester.pumpAndSettle();
    expect(find.text('Add page'), findsOneWidget);
  });

  testWidgets('manager access saves branch assignment changes', (tester) async {
    final repo = _FakeBranchRepository([
      _branch('b1', 'Caloocan Branch', firstName: 'Jane', lastName: 'Doe'),
      _branch('b2', 'Manila Branch'),
    ]);
    final manager = ManagerData(
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'janedoe@email.com',
      status: ManagerStatus.active,
      branchIds: const ['b1'],
      branchNames: const ['Caloocan Branch'],
    );
    await _pump(
      tester,
      ManagerAccessPage(manager: manager, branchRepository: repo),
    );

    expect(find.text('Manager Access'), findsOneWidget);
    expect(find.text('Account Status'), findsOneWidget);
    expect(find.text('Branch Assignments'), findsOneWidget);
    expect(
      find.text(
        'Assign this manager to one or more branches. Each branch can have '
        'only one assigned manager.',
      ),
      findsOneWidget,
    );
    expect(find.text('Caloocan Branch'), findsOneWidget);
    expect(find.text('Manila Branch'), findsOneWidget);

    // Profile, status, and branch list use the shared Settings frame.
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final decoration = widget.decoration! as BoxDecoration;
        return decoration.color == AppColors.surface &&
            decoration.borderRadius == BorderRadius.circular(16) &&
            decoration.boxShadow?.isNotEmpty == true;
      }),
      findsNWidgets(3),
    );

    // Check icons use the Figma orange outline and a visible white check.
    for (final checkbox in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
      expect(checkbox.side?.color, const Color(0xFFD97247));
      expect(checkbox.checkColor, Colors.white);
    }

    // Uncheck the current branch, then check the other one.
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(repo.updates, [
      (branchId: 'b1', firstName: null, lastName: null),
      (branchId: 'b2', firstName: 'Jane', lastName: 'Doe'),
    ]);
  });

  testWidgets('add manager assigns the entered name to chosen branches', (
    tester,
  ) async {
    final repo = _FakeBranchRepository([
      _branch('b1', 'Caloocan Branch'),
      _branch('b2', 'Quezon City Branch'),
    ]);
    await _pump(tester, AddManagerPage(branchRepository: repo));

    expect(find.text('Create manager account'), findsOneWidget);
    expect(find.text('Manager Details'), findsOneWidget);
    expect(find.text('Account Access'), findsOneWidget);
    expect(find.text('Account Credentials'), findsOneWidget);
    expect(find.text('Quezon City Branch'), findsOneWidget);

    await tester.enterText(_field('First name'), 'Juan');
    await tester.enterText(_field('Last name'), 'Dela Cruz');
    await tester.enterText(_field('Email address'), 'juan@example.com');
    // The first branch is checked by default, matching the Figma frame.
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(repo.updates, [
      (branchId: 'b1', firstName: 'Juan', lastName: 'Dela Cruz'),
    ]);
  });

  testWidgets('shows the backend reason when adding a manager is rejected', (
    tester,
  ) async {
    final repo = _FakeBranchRepository([_branch('b1', 'Caloocan Branch')])
      ..updateError = const ApiException(
        403,
        'PLAN_FEATURE_REQUIRED',
        'Assigning a branch manager requires the Organization plan.',
      );
    await _pump(tester, AddManagerPage(branchRepository: repo));

    await tester.enterText(_field('First name'), 'Juan');
    await tester.enterText(_field('Last name'), 'Dela Cruz');
    await tester.enterText(_field('Email address'), 'juan@example.com');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(
      find.text('Assigning a branch manager requires the Organization plan.'),
      findsOneWidget,
    );
  });

  test('groups multiple branches under one manager', () {
    final managers = ManagerData.fromBranches([
      _branch(
        'b1',
        'Caloocan Branch',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'janedoe@email.com',
      ),
      _branch(
        'b2',
        'Manila Branch',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'janedoe@email.com',
      ),
    ]);

    expect(managers, hasLength(1));
    expect(managers.single.name, 'Jane Doe');
    expect(managers.single.branchIds, ['b1', 'b2']);
    expect(managers.single.branchNames, ['Caloocan Branch', 'Manila Branch']);
    expect(managers.single.status, ManagerStatus.active);
  });
}
