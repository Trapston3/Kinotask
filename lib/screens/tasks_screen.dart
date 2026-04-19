import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../services/haptics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/kanban_board.dart';
import '../widgets/kinotask_header.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final GlobalKey<ConfettiOverlayState> _confettiKey = GlobalKey();
  int _viewMode = 0; // 0 = List, 1 = Board

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.tasks;
    final haptics = context.read<HapticsService>();
    final theme = Theme.of(context);

    if (!taskProvider.isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header + pill toggle ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: KinotaskHeader('Tasks'),
                    ),
                    _ViewToggle(
                      selectedIndex: _viewMode,
                      onChanged: (i) => setState(() => _viewMode = i),
                    ),
                  ],
                ),
              ),

              // ── Content ─────────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutExpo,
                  child: _viewMode == 0
                      ? _buildListView(
                          key: const ValueKey('listView'),
                          tasks: tasks,
                          haptics: haptics,
                          taskProvider: taskProvider,
                          theme: theme,
                        )
                      : KanbanBoard(key: const ValueKey('boardView')),
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: ConfettiOverlay(key: _confettiKey),
        ),
      ],
    );
  }

  Widget _buildListView({
    Key? key,
    required List tasks,
    required HapticsService haptics,
    required TaskProvider taskProvider,
    required ThemeData theme,
  }) {
    return CustomScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
          sliver: SliverList.list(
            children: [
              if (tasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.islandSurface,
                    borderRadius: BorderRadius.circular(
                      AppTheme.islandRadius,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt_rounded,
                        size: 48,
                        color: AppTheme.subtleGrey.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap + to capture your next priority.',
                        style: TextStyle(color: AppTheme.subtleGrey),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
              for (var i = 0; i < tasks.length; i++) ...[
                TaskCard(
                  task: tasks[i],
                  hapticsService: haptics,
                  onToggleComplete: () {
                    taskProvider.toggleTaskCompletion(tasks[i].id);
                  },
                  onDelete: () {
                    taskProvider.deleteTask(tasks[i].id);
                  },
                  onCelebrate: () {
                    _confettiKey.currentState?.fire();
                  },
                )
                    .animate(delay: Duration(milliseconds: 60 * i))
                    .fadeIn(
                        duration: 400.ms, curve: Curves.easeOutExpo)
                    .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// View Toggle — [List | Board] pill
// ═══════════════════════════════════════════════════════════════════════

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _labels = ['List', 'Board'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.islandSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_labels.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accentBlue.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                _labels[i],
                style: TextStyle(
                  color: selected ? AppTheme.accentBlue : AppTheme.subtleGrey,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOutExpo)
        .slideX(
            begin: 0.05,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutBack);
  }
}
