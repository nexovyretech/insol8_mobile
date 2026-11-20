import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/manager_auth_args.dart';
import 'package:insol8_mobile/pages/auth/manager_auth_page.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/theme/app_theme.dart';

Finder _field(String hint) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == hint,
);

Future<void> _pumpActivationPage(
  WidgetTester tester, {
  Map<String, WidgetBuilder> routes = const {},
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: ManagerAuthPage(
        args: const ManagerAuthArgs(
          contact: 'jhondoe@email.com',
          isEmail: true,
        ),
      ),
      routes: routes,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _goToUsernameStep(WidgetTester tester) async {
  await tester.enterText(_field('Enter your password'), 'Passw0rd!');
  await tester.enterText(_field('Confirm your password'), 'Passw0rd!');
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('manager invitation creates a password then a username', (
    tester,
  ) async {
    await _pumpActivationPage(
      tester,
      routes: {AppRoutes.login: (_) => const Text('Login page')},
    );

    expect(find.text('Welcome to InSOL8!'), findsOneWidget);
    expect(
      find.textContaining('Your branch owner has invited you'),
      findsOneWidget,
    );
    expect(find.text('Create a password'), findsOneWidget);
    expect(
      find.text('Create a password comprising a minimum 8 letters or digits'),
      findsOneWidget,
    );
    expect(_field('Enter your password'), findsOneWidget);
    expect(_field('Confirm your password'), findsOneWidget);

    final continueButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    await _goToUsernameStep(tester);

    expect(find.text('Create username'), findsOneWidget);
    expect(
      find.textContaining('Choose a username. You can update it'),
      findsOneWidget,
    );
    expect(_field('Enter a username'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);

    final createButton = find.widgetWithText(FilledButton, 'Create Account');
    expect(tester.widget<FilledButton>(createButton).onPressed, isNull);

    await tester.enterText(_field('Enter a username'), 'jhondoe123');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(createButton).onPressed, isNotNull);

    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Preview only: manager account setup is waiting for the backend.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(SnackBarAction, 'Go to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Login page'), findsOneWidget);
  });

  testWidgets('back and sign in links navigate correctly', (tester) async {
    await _pumpActivationPage(
      tester,
      routes: {AppRoutes.login: (_) => const Text('Login page')},
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Login page'), findsOneWidget);

    Navigator.of(tester.element(find.text('Login page'))).pop();
    await tester.pumpAndSettle();

    await _goToUsernameStep(tester);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Create a password'), findsOneWidget);
    expect(find.text('Create username'), findsNothing);
  });

  test('invitation args accept a map or a plain contact string', () {
    final fromMap = ManagerAuthArgs.from({
      'contact': 'jhondoe@email.com',
      'isEmail': true,
    });
    expect(fromMap.contact, 'jhondoe@email.com');
    expect(fromMap.isEmail, isTrue);

    final fromMobile = ManagerAuthArgs.from('+639123456789');
    expect(fromMobile.contact, '+639123456789');
    expect(fromMobile.isEmail, isFalse);
  });
}
