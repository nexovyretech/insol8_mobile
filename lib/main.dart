import 'package:flutter/material.dart';

import 'package:insol8_mobile/routes/app_routes.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/theme/app_theme.dart';

void main() {
  runApp(const Insol8App());
}

class Insol8App extends StatelessWidget {
  const Insol8App({super.key});

  static final _authRepository = UnconfiguredAuthRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'inSOL8',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.getStarted,
      routes: AppRoutes.build(_authRepository),
    );
  }
}
