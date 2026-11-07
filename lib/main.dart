import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';

void main() {
  runApp(const RsuApp());
}

class RsuApp extends StatelessWidget {
  const RsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RSU',
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
