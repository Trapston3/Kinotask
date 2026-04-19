import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/alarm_coordinator.dart';
import 'screens/alarm_captcha_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class ProductivityApp extends StatelessWidget {
  const ProductivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinotask',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
      home: const SplashScreen(),
    );
  }
}
