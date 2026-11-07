import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/api/conductor_api.dart';
import 'features/auth/presentation/login_screen.dart';

void main() {
  runApp(const RsuApp());
}

class RsuApp extends StatelessWidget {
  const RsuApp({super.key, this.api});
  final ConductorApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RSU',
      theme: AppTheme.light,
      home: LoginScreen(api: api),
    );
  }
}
