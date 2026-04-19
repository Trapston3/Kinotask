import 'dart:math';

import 'package:flutter/material.dart';

/// A particle-burst confetti overlay that fires from the left and right screen
/// edges. Obtain a [GlobalKey<ConfettiOverlayState>] and call [fire()] after
/// the pencil-scratch completion animation finishes.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 1400);
  static const int _particleCount = 50;
  static const double _durationSeconds = 1.4;

  static const List<Color> _palette = [
    Color(0xFF007AFF),
    Color(0xFF5AC8FA),
    Color(0xFF34C759),
    Color(0xFFFFD60A),
    Color(0xFFFF9F0A),
    Colors.white,
    Color(0xFFBF5AF2),
  ];

  late final AnimationController _controller;
  final Random _rng = Random();
  List<_Particle> _particles = [];
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _particles = []);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trigger the confetti burst.
  void fire() {
    _screenSize = MediaQuery.of(context).size;
    _particles = List.generate(_particleCount, (_) => _spawnParticle());
    _controller.forward(from: 0);
  }

  _Particle _spawnParticle() {
    final fromLeft = _rng.nextBool();
    return _Particle(
      x: fromLeft ? -8.0 : _screenSize.width + 8.0,
      y: _screenSize.height * (0.18 + _rng.nextDouble() * 0.52),
      vx: (fromLeft ? 1 : -1) * (120 + _rng.nextDouble() * 300),
      vy: -90 + _rng.nextDouble() * 70,
      size: 4 + _rng.nextDouble() * 5,
      color: _palette[_rng.nextInt(_palette.length)],
      rotation: _rng.nextDouble() * pi * 2,
      rotationSpeed: (_rng.nextDouble() - 0.5) * 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(
          particles: _particles,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });

  final double x, y, vx, vy, size, rotation, rotationSpeed;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  final List<_Particle> particles;
  final double progress;

  static const double _gravity = 620.0;

  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = progress * ConfettiOverlayState._durationSeconds;
    final opacity = (1.0 - progress * progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final px = p.x + p.vx * elapsed;
      final py = p.y + p.vy * elapsed + 0.5 * _gravity * elapsed * elapsed;
      final s = p.size * (1.0 - progress * 0.35).clamp(0.5, 1.0);
      final angle = p.rotation + p.rotationSpeed * elapsed;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(angle);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: s,
            height: s * 0.55,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
