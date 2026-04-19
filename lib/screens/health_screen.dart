import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/health_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kinotask_header.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hp = context.watch<HealthProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: KinotaskHeader('Health'),
                  ),
                  if (hp.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppTheme.subtleGrey),
                      onPressed: hp.fetchData,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hp.hasPermission
                    ? 'Live from Samsung Health'
                    : 'Sample data — tap refresh to connect',
                style:
                    const TextStyle(color: AppTheme.subtleGrey, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // ── Daily Goals island ────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.islandSurface,
                  borderRadius:
                      BorderRadius.circular(AppTheme.islandRadius),
                ),
                child: Column(
                  children: [
                    Text(
                      'Daily Goals',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _HealthRing(
                          progress: hp.stepsProgress,
                          color: const Color(0xFF34C759),
                          size: 100,
                          icon: Icons.directions_walk_rounded,
                          value: hp.stepsDisplay,
                          label: 'Steps',
                        ),
                        _HealthRing(
                          progress: hp.sleepProgress,
                          color: const Color(0xFFBF5AF2),
                          size: 100,
                          icon: Icons.bedtime_rounded,
                          value: hp.sleepDisplay,
                          label: 'Sleep',
                          onTap: () => _showSleepOverride(context, hp),
                        ),
                        _HealthRing(
                          progress: hp.waterProgress,
                          color: const Color(0xFF5AC8FA),
                          size: 100,
                          icon: Icons.water_drop_rounded,
                          value: hp.waterDisplay,
                          label: 'Water',
                          onTap: () => _showWaterOverride(context, hp),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOutExpo)
                  .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOutBack),
              const SizedBox(height: 16),

              // ── Detail metric cards ───────────────────────────────
              _MetricCard(
                title: 'Steps',
                value: hp.steps.toString(),
                goal: '${hp.stepsGoal} steps',
                progress: hp.stepsProgress,
                color: const Color(0xFF34C759),
                icon: Icons.directions_walk_rounded,
                detail: hp.stepsDetail,
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
                  .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutBack),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'Sleep',
                value: hp.sleepDisplay,
                goal: '8h target',
                progress: hp.sleepProgress,
                color: const Color(0xFFBF5AF2),
                icon: Icons.bedtime_rounded,
                detail: hp.sleepDetail,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
                  .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutBack),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'Hydration',
                value: '${hp.waterGlasses} glasses',
                goal: '${hp.waterGoal} glasses',
                progress: hp.waterProgress,
                color: const Color(0xFF5AC8FA),
                icon: Icons.water_drop_rounded,
                detail: hp.waterDetail,
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      color: Color(0xFF5AC8FA)),
                  onPressed: hp.logWater,
                  tooltip: 'Log a glass',
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
                  .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              const _ContributionGraph()
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
                  .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  void _showWaterOverride(BuildContext context, HealthProvider hp) {
    int selectedGoal = hp.waterGoal;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => Container(
        height: 250,
        color: AppTheme.islandSurface,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
                CupertinoButton(child: const Text('Save'), onPressed: () {
                  hp.setWaterGoal(selectedGoal);
                  Navigator.pop(ctx);
                }),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32.0,
                scrollController: FixedExtentScrollController(initialItem: selectedGoal - 1),
                onSelectedItemChanged: (int index) {
                  selectedGoal = index + 1;
                },
                children: List<Widget>.generate(30, (int index) {
                  return Center(child: Text('${index + 1} glasses', style: const TextStyle(color: Colors.white)));
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepOverride(BuildContext context, HealthProvider hp) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => Container(
        height: 250,
        color: AppTheme.islandSurface,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Log Sleep', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                CupertinoButton(onPressed: null, child: const Text('')), // Empty balance
              ],
            ),
            Expanded(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: Duration(minutes: hp.sleepMinutes.toInt() > 0 ? hp.sleepMinutes.toInt() : 480),
                onTimerDurationChanged: (Duration newDuration) {
                  // We update it directly because the user wants to "Log sleep" instantly if sensors missed it.
                  hp.logSleep(newDuration.inMinutes.toDouble());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Glassmorphic Health Ring (unchanged UI)
// ═══════════════════════════════════════════════════════════════════════

class _HealthRing extends StatelessWidget {
  const _HealthRing({
    required this.progress,
    required this.color,
    required this.size,
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final double progress;
  final Color color;
  final double size;
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.islandSurface.withValues(alpha: 0.6),
                  border: Border.all(color: color.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(progress: progress, color: color),
              ),
              Icon(icon, color: color, size: 28),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppTheme.subtleGrey, fontSize: 11)),
      ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
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
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════
// Detail Metric Card (now accepts optional trailing widget)
// ═══════════════════════════════════════════════════════════════════════

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.goal,
    required this.progress,
    required this.color,
    required this.icon,
    required this.detail,
    this.trailing,
  });

  final String title;
  final String value;
  final String goal;
  final double progress;
  final Color color;
  final IconData icon;
  final String detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.islandSurface,
        borderRadius: BorderRadius.circular(AppTheme.islandRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(goal,
                        style: const TextStyle(
                            color: AppTheme.subtleGrey, fontSize: 13)),
                  ],
                ),
              ),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Text(detail,
              style: const TextStyle(
                  color: AppTheme.subtleGrey, fontSize: 12)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Contribution Graph (Heatmap)
// ═══════════════════════════════════════════════════════════════════════

class _ContributionGraph extends StatelessWidget {
  const _ContributionGraph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.islandSurface,
        borderRadius: BorderRadius.circular(AppTheme.islandRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consistency',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 20),
          FutureBuilder<Box>(
            future: Hive.openBox('health_data'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              final box = snapshot.data!;

              // Generate 90 days backwards
              final now = DateTime.now();
              final days = List.generate(90, (index) {
                final d = now.subtract(Duration(days: 89 - index));
                final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                // Value is [0..1]
                final val = box.get('history_$dateStr', defaultValue: 0.0) as double;
                return MapEntry(d, val);
              });

              return _HeatmapGrid(days: days);
            },
          ),
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.days});
  final List<MapEntry<DateTime, double>> days;

  void _showTooltip(BuildContext context, DateTime date, double val) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[date.month - 1]} ${date.day}';
    final percentage = (val * 100).round();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.islandSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.subtleGrey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('$dateStr: $percentage% Goal Hit', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Metrics extracted securely from local sensor history.', style: TextStyle(color: AppTheme.subtleGrey, fontSize: 14)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // Always show the most recent days on the right.
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        direction: Axis.vertical,
        children: days.map((e) {
          final val = e.value;
          final color = val == 0 
            ? AppTheme.subtleGrey.withValues(alpha: 0.1) 
            : Color.lerp(const Color(0xFF193a70), AppTheme.accentBlue, val)!;
            
          return GestureDetector(
            onTap: () => _showTooltip(context, e.key, val),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ).animate().scale(delay: Random().nextInt(300).ms, duration: 400.ms, curve: Curves.easeOutBack),
          );
        }).toList(),
      ),
    );
  }
}
