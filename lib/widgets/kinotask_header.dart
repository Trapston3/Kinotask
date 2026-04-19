import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class KinotaskHeader extends StatelessWidget {
  const KinotaskHeader(this.title, {super.key, this.heroTag});

  final String title;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();

    Widget text = ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppTheme.accentBlue, Color(0xFFB0D4FF), Colors.white],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Colors.white, // base color, overridden by shader
            ),
      ),
    );

    if (heroTag != null) {
      text = Hero(tag: heroTag!, child: Material(type: MaterialType.transparency, child: text));
    }

    return text
        .animate()
        .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
        .slideX(begin: -0.04, end: 0, duration: 500.ms, curve: Curves.easeOutExpo);
  }
}
