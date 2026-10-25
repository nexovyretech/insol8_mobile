import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insol8_mobile/amplifyconfiguration.dart';
import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/cognito_auth_repository.dart';
import 'package:insol8_mobile/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AuthRepository authRepository = await _configureAuth()
      ? CognitoAuthRepository()
      : UnconfiguredAuthRepository();
  final initialRoute = await authRepository.hasActiveSession()
      ? AppRoutes.home
      : AppRoutes.getStarted;

  runApp(
    ProviderScope(
      child: Insol8App(
        authRepository: authRepository,
        initialRoute: initialRoute,
      ),
    ),
  );
}

Future<bool> _configureAuth() async {
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(jsonEncode(amplifyConfig.toJson()));
    safePrint('Amplify initialized successfully.');
    return true;
  } on AmplifyAlreadyConfiguredException {
    return true;
  } on Exception catch (error) {
    safePrint('Could not initialize Amplify: $error');
    return false;
  }
}

class Insol8App extends StatelessWidget {
  const Insol8App({
    super.key,
    required this.authRepository,
    required this.initialRoute,
  });

  final AuthRepository authRepository;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'inSOL8',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      routes: AppRoutes.build(authRepository),
    );
  }
}
