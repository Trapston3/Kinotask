import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/focus_provider.dart';
import '../providers/standalone_alarm_provider.dart';
import '../services/haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/squircle_toggle.dart';

// ═══════════════════════════════════════════════════════════════════════
// Focus & Time Screen – pill-segmented [Alarm | Stopwatch | Timer]
// Now scrollable, with custom duration input and functional alarms.
// ═══════════════════════════════════════════════════════════════════════

class FocusTimeScreen extends StatefulWidget {
  const FocusTimeScreen({super.key});

  @override
  State<FocusTimeScreen> createState() => _FocusTimeScreenState();
}

class _FocusTimeScreenState extends State<FocusTimeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
            child: Text(
              'Focus',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: AppTheme.accentBlue,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
                .slideX(
                    begin: -0.04,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOutExpo),
          ),
          const SizedBox(height: 24),

          // ── Segment controller ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _PillSegmentedControl(
              labels: const ['Alarm', 'Stopwatch', 'Timer'],
              selectedIndex: context.watch<FocusProvider>().selectedSegment,
              onChanged: (i) => context.read<FocusProvider>().setSegment(i),
            )
                .animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeOutExpo)
                .slideY(
                    begin: -0.03,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 16),

          // ── Active section (scrollable) ────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Builder(
                builder: (context) {
                  final segment = context.watch<FocusProvider>().selectedSegment;
                  if (segment == 0) return const _AlarmSection(key: ValueKey('alarm'));
                  if (segment == 1) return const _StopwatchSection(key: ValueKey('stopwatch'));
                  return const _TimerSection(key: ValueKey('timer'));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Pill-shaped segmented control
// ═══════════════════════════════════════════════════════════════════════

class _PillSegmentedControl extends StatelessWidget {
  const _PillSegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.islandSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              // ── Animated Selection Pill ──────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: selectedIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              // ── Tab Items ──────────────────────────────────────────────
              Row(
                children: List.generate(labels.length, (i) {
                  final isSelected = i == selectedIndex;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.read<HapticsService>().lightTick();
                      onChanged(i);
                    },
                    child: SizedBox(
                      width: tabWidth,
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.accentBlue : AppTheme.subtleGrey,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Timer section – glassmorphic ring + tappable duration + presets
// ═══════════════════════════════════════════════════════════════════════

class _TimerSection extends StatelessWidget {
  const _TimerSection({super.key});

  static const List<_Preset> _presets = [
    _Preset(label: '5m', seconds: 5 * 60),
    _Preset(label: '15m', seconds: 15 * 60),
    _Preset(label: '25m', seconds: 25 * 60),
    _Preset(label: '45m', seconds: 45 * 60),
    _Preset(label: '60m', seconds: 60 * 60),
  ];

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        children: [
          const SizedBox(height: 24),
          ValueListenableBuilder<int>(
            valueListenable: focus.timerRemainingNotifier,
            builder: (context, remaining, child) {
              final progress = focus.timerTotal > 0 ? remaining / focus.timerTotal : 1.0;
              final m = (remaining ~/ 60).toString().padLeft(2, '0');
              final s = (remaining % 60).toString().padLeft(2, '0');
              final display = '$m:$s';
              return _GlassmorphicRing(
                progress: progress,
                size: 200,
                ringColor: AppTheme.accentBlue,
                child: GestureDetector(
                  onTap: focus.timerRunning ? null : () => _pickDuration(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        display,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        focus.timerRunning ? 'DEEP WORK' : 'TAP TO SET',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.subtleGrey,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Presets ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _presets.map((p) {
              final isActive = focus.timerTotal == p.seconds;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: focus.timerRunning
                      ? null
                      : () => focus.setTimerDuration(p.seconds),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.accentBlue.withValues(alpha: 0.2)
                          : AppTheme.islandSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: isActive
                          ? Border.all(color: AppTheme.accentBlue, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      p.label,
                      style: TextStyle(
                        color:
                            isActive ? AppTheme.accentBlue : AppTheme.subtleGrey,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),

          // ── Controls ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  icon: focus.timerRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap: focus.toggleTimer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ControlButton(
                  icon: Icons.refresh_rounded,
                  onTap: focus.resetTimer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickDuration(BuildContext context) {
    final focus = context.read<FocusProvider>();
    Duration initialDuration = Duration(seconds: focus.timerTotal);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return SizedBox(
              height: 320,
              child: Column(
                children: [
                  const Text(
                    'Set Timer Duration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hms,
                      initialTimerDuration: initialDuration,
                      onTimerDurationChanged: (d) {
                        initialDuration = d;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final seconds = initialDuration.inSeconds;
                          if (seconds > 0) {
                            focus.setTimerDuration(seconds);
                          }
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Set'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Preset {
  const _Preset({required this.label, required this.seconds});
  final String label;
  final int seconds;
}

// ═══════════════════════════════════════════════════════════════════════
// Stopwatch section
// ═══════════════════════════════════════════════════════════════════════

class _StopwatchSection extends StatelessWidget {
  const _StopwatchSection({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            focus.stopwatchDisplay,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w200,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),

          // ── Controls ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  icon: focus.stopwatchRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap: focus.toggleStopwatch,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ControlButton(
                  icon: Icons.flag_rounded,
                  onTap: focus.lapStopwatch,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ControlButton(
                  icon: Icons.refresh_rounded,
                  onTap: focus.resetStopwatch,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Laps ────────────────────────────────────────────────
          if (focus.laps.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.islandSurface,
                borderRadius: BorderRadius.circular(AppTheme.islandRadius),
              ),
              child: Column(
                children: [
                  for (var i = focus.laps.length - 1; i >= 0; i--) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lap ${i + 1}',
                            style: const TextStyle(
                              color: AppTheme.subtleGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            focus.fmtLap(focus.laps[i]),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i > 0)
                      const Divider(color: AppTheme.islandBorder, height: 1),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Alarm section — functional CRUD from StandaloneAlarmProvider
// ═══════════════════════════════════════════════════════════════════════

class _AlarmSection extends StatelessWidget {
  const _AlarmSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StandaloneAlarmProvider>();
    final alarms = provider.alarms;

    if (alarms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.islandSurface,
              borderRadius: BorderRadius.circular(AppTheme.islandRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.alarm_rounded,
                  size: 64,
                  color: AppTheme.accentBlue.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Alarms',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to create your first alarm.',
                  style: TextStyle(color: AppTheme.subtleGrey, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      itemCount: alarms.length,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final alarm = alarms[index];
        return Dismissible(
          key: ValueKey(alarm.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => provider.deleteAlarm(alarm.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: AppTheme.destructiveRed.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppTheme.islandRadius),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.islandSurface,
              borderRadius: BorderRadius.circular(AppTheme.islandRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm.timeDisplay,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w200,
                          color: alarm.enabled
                              ? Colors.white
                              : AppTheme.subtleGrey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alarm.label.isNotEmpty
                            ? alarm.label
                            : alarm.repeatLabel,
                        style: const TextStyle(
                          color: AppTheme.subtleGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSquircleToggle(
                  value: alarm.enabled,
                  onChanged: (_) => provider.toggleAlarm(alarm.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Shared: Glassmorphic Ring
// ═══════════════════════════════════════════════════════════════════════

class _GlassmorphicRing extends StatelessWidget {
  const _GlassmorphicRing({
    required this.progress,
    required this.size,
    required this.ringColor,
    required this.child,
  });

  final double progress;
  final double size;
  final Color ringColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Glass backdrop ──────────────────────────────────────
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.islandSurface.withValues(alpha: 0.6),
              border: Border.all(
                color: AppTheme.islandBorder.withValues(alpha: 0.3),
              ),
            ),
          ),

          // ── Ambient glow ───────────────────────────────────────
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.08),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),

          // ── Progress arc ───────────────────────────────────────
          RepaintBoundary(
            child: CustomPaint(
              size: Size(size, size),
              painter: _ProgressRingPainter(
                progress: progress,
                color: ringColor,
              ),
            ),
          ),

          // ── Centre content ─────────────────────────────────────
          child,
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;
  static const double _strokeWidth = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════
// Shared: Control Button
// ═══════════════════════════════════════════════════════════════════════

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.islandSurface,
      borderRadius: BorderRadius.circular(AppTheme.islandRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.islandRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Icon(icon, color: AppTheme.accentBlue, size: 32),
        ),
      ),
    );
  }
}
