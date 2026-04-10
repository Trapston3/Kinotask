import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/alarm_coordinator.dart';
import 'screens/alarm_captcha_screen.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

class ProductivityApp extends StatelessWidget {
  const ProductivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: (context, child) {
        final session = context.watch<AlarmCoordinator>().activeSession;

        return Stack(
          children: [
            // ignore: use_null_aware_elements
            if (child != null) child,
            if (session != null)
              Positioned.fill(
                child: AlarmCaptchaScreen(session: session),
              ),
          ],
        );
      },
      home: const AppShell(),
    );
  }
}
