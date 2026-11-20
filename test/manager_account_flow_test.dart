import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insol8_mobile/models/branch_setup_data.dart';
import 'package:insol8_mobile/models/manager_account_data.dart';
import 'package:insol8_mobile/pages/onboarding/branch_setup_step.dart';
import 'package:insol8_mobile/pages/onboarding/manager_account_step.dart';

Finder _field(String hint) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == hint,
);

/// The email/mobile toggle is one TextButton with a black prefix and an orange
/// method name, matching the screenshot's two-color label.
List<String?> _toggleWords(WidgetTester tester) {
  final text = tester.widget<Text>(
    find.descendant(
      of: find.byKey(const Key('manager-contact-toggle')),
      matching: find.byType(Text),
    ),
  );
  final spans = (text.textSpan! as TextSpan).children!;
  return [(spans.first as TextSpan).text, (spans.last as TextSpan).text];
}

void main() {
  group('ManagerAccountData', () {
    test(
      'keeps the displayed contact and sends a normalized mobile number',
      () {
        const email = ManagerAccountData(
          firstName: 'John',
          lastName: 'Doe',
          contactMethod: ManagerContactMethod.email,
          contact: 'JohnDoe@gmail.com',
        );
        expect(email.fullName, 'John Doe');
        expect(email.displayContact, 'JohnDoe@gmail.com');
        expect(email.toJson(), {
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'JohnDoe@gmail.com',
        });

        const mobile = ManagerAccountData(
          firstName: 'John',
          lastName: 'Doe',
          contactMethod: ManagerContactMethod.mobile,
          contact: '912 345 6789',
        );
        expect(mobile.displayContact, '912 345 6789');
        expect(mobile.mobileNumber, '+639123456789');
        expect(mobile.toJson()['mobileNumber'], '+639123456789');
      },
    );

    test('branch payload carries only backend-supported manager fields', () {
      final data = BranchSetupData(
        name: 'Caloocan Branch',
        address: 'Camarin, Caloocan City',
        managerOption: BranchManagerOption.newManager,
        managerFirstName: 'John',
        managerLastName: 'Doe',
        managerEmail: 'johndoe@gmail.com',
      );

      expect(data.toJson(), {
        'name': 'Caloocan Branch',
        'storeAddress': 'Camarin, Caloocan City',
        'managerOption': 'newManager',
        'managerFirstName': 'John',
        'managerLastName': 'Doe',
      });
    });
  });

  testWidgets('manager account screen matches the screenshot and toggles '
      'between email and mobile', (tester) async {
    final first = TextEditingController();
    final last = TextEditingController();
    final email = TextEditingController();
    final mobile = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isEmail = true;
    var created = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => OnboardingManagerAccountStep(
              onBack: () {},
              formKey: formKey,
              firstNameController: first,
              lastNameController: last,
              emailController: email,
              mobileController: mobile,
              isEmail: isEmail,
              onContactMethodChanged: (value) =>
                  setState(() => isEmail = value),
              onFieldChanged: () => setState(() {}),
              onCreateAccount: () => created++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Branch Setup'), findsOneWidget);
    expect(find.text('Create manager account'), findsOneWidget);
    expect(
      find.text(
        'Create an account your branch manager can sign in with. They will '
        'set their own password from the invitation.',
      ),
      findsOneWidget,
    );
    expect(find.text('Manager Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(_toggleWords(tester), ['Or you can sign up with ', 'mobile number']);
    expect(find.text('Account Credentials'), findsOneWidget);
    expect(
      find.text(
        'The manager will receive an invitation to set up their password.',
      ),
      findsOneWidget,
    );
    expect(find.text('Create Account'), findsOneWidget);

    await tester.tap(find.byKey(const Key('manager-contact-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(_toggleWords(tester), ['Or you can sign up with ', 'email']);

    await tester.enterText(_field('First name'), 'John');
    await tester.pumpAndSettle();
    await tester.enterText(_field('Last name'), 'Doe');
    await tester.pumpAndSettle();
    await tester.enterText(_field('Mobile number'), '912 345 6789');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(created, 1);
  });

  testWidgets('branch setup shows the created manager instead of name fields', (
    tester,
  ) async {
    final branchName = TextEditingController(text: 'Caloocan Branch');
    final branchAddress = TextEditingController(text: 'Camarin, Caloocan City');
    var finished = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingBranchSetupStep(
            onBack: () {},
            formKey: GlobalKey<FormState>(),
            branchNameController: branchName,
            branchAddressController: branchAddress,
            managerOption: BranchManagerOption.newManager,
            managerAccount: const ManagerAccountData(
              firstName: 'John',
              lastName: 'Doe',
              contactMethod: ManagerContactMethod.email,
              contact: 'JohnDoe@gmail.com',
            ),
            isSaving: false,
            onManagerOptionChanged: (_) {},
            onFieldChanged: () {},
            onAddManager: () {},
            onFinish: () => finished++,
          ),
        ),
      ),
    );

    expect(find.text('Assign Manager'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('JohnDoe@gmail.com'), findsOneWidget);
    expect(_field('First name'), findsNothing);
    expect(_field('Last name'), findsNothing);

    await tester.tap(find.text('Finish Setup'));
    await tester.pumpAndSettle();
    expect(finished, 1);
  });
}
