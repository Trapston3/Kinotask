import 'package:flutter/material.dart';

class PencilScratchText extends StatefulWidget {
  const PencilScratchText({
    super.key,
    required this.text,
    required this.style,
    required this.isCompleted,
    this.onScratchComplete,
  });

  static const Duration animationDuration = Duration(milliseconds: 450);

  final String text;
  final TextStyle style;
  final bool isCompleted;
  final VoidCallback? onScratchComplete;

  @override
  State<PencilScratchText> createState() => _PencilScratchTextState();
}

class _PencilScratchTextState extends State<PencilScratchText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PencilScratchText.animationDuration,
      value: widget.isCompleted ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant PencilScratchText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isCompleted && widget.isCompleted) {
      _controller.forward(from: 0);
      void onFinished(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onScratchComplete?.call();
          });
        }
      }
      _controller.addStatusListener(onFinished);
    } else if (oldWidget.isCompleted && !widget.isCompleted) {
      _controller.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PencilScratchPainter(
            progress: _controller.value,
            color: widget.style.color ?? Theme.of(context).colorScheme.onSurface,
          ),
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}

class _PencilScratchPainter extends CustomPainter {
  const _PencilScratchPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    final graphite = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.4;

    final strokes = <List<Offset>>[
      [
        Offset(0, size.height * 0.38),
        Offset(size.width * 0.35, size.height * 0.56),
        Offset(size.width * 0.72, size.height * 0.30),
        Offset(size.width, size.height * 0.52),
      ],
      [
        Offset(0, size.height * 0.62),
        Offset(size.width * 0.32, size.height * 0.30),
        Offset(size.width * 0.67, size.height * 0.66),
        Offset(size.width, size.height * 0.40),
      ],
      [
        Offset(0, size.height * 0.50),
        Offset(size.width * 0.42, size.height * 0.46),
        Offset(size.width * 0.78, size.height * 0.58),
        Offset(size.width, size.height * 0.48),
      ],
    ];

    for (var index = 0; index < strokes.length; index++) {
      final start = index * 0.18;
      final localProgress = ((progress - start) / (1 - start)).clamp(0.0, 1.0);
      if (localProgress <= 0) {
        continue;
      }

      final path = Path()..moveTo(strokes[index].first.dx, strokes[index].first.dy);
      for (final point in strokes[index].skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      final metric = path.computeMetrics().first;
      final visiblePath = metric.extractPath(0, metric.length * localProgress);
      canvas.drawPath(visiblePath, graphite);
      canvas.drawPath(visiblePath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PencilScratchPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
