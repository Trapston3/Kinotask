import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import 'app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) => const AppShell(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Structural 'K' Logo
            SizedBox(
              width: 80,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back pillar
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      width: 16,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Angled upper arm
                  Positioned(
                    left: 30,
                    top: 15,
                    child: Transform.rotate(
                      angle: 0.8,
                      child: Container(
                        width: 16,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Angled lower arm
                  Positioned(
                    left: 30,
                    bottom: 15,
                    child: Transform.rotate(
                      angle: -0.8,
                      child: Container(
                        width: 16,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .scaleXY(begin: 0.0, end: 1.2, duration: 600.ms, curve: Curves.easeOutBack)
            .then(delay: 100.ms)
            .scaleXY(end: 1 / 1.2, duration: 400.ms, curve: Curves.easeOut),
            
            const SizedBox(height: 24),
            
            const Text(
              'Kinotask',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            )
            .animate()
            .fadeIn(delay: 500.ms, duration: 800.ms)
            .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 800.ms, curve: Curves.easeOutExpo),
          ],
        ),
      ),
    );
  }
}
