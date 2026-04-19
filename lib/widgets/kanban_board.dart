import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/haptics_service.dart';
import '../theme/app_theme.dart';

/// Kanban board with 3 drag-and-drop columns: To Do, In Progress, Done.
class KanbanBoard extends StatelessWidget {
  const KanbanBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      children: [
        _KanbanColumn(
          title: 'To Do',
          status: 'To Do',
          color: AppTheme.accentBlue,
          icon: Icons.radio_button_unchecked,
        ),
        const SizedBox(width: 12),
        _KanbanColumn(
          title: 'In Progress',
          status: 'In Progress',
          color: const Color(0xFFFF9F0A),
          icon: Icons.timelapse_rounded,
        ),
        const SizedBox(width: 12),
        _KanbanColumn(
          title: 'Done',
          status: 'Done',
          color: const Color(0xFF34C759),
          icon: Icons.check_circle_rounded,
        ),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.title,
    required this.status,
    required this.color,
    required this.icon,
  });

  final String title;
  final String status;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = switch (status) {
      'To Do' => provider.todoTasks,
      'In Progress' => provider.inProgressTasks,
      'Done' => provider.doneTasks,
      _ => <Task>[],
    };

    return SizedBox(
      width: 280,
      child: DragTarget<Task>(
        onAcceptWithDetails: (details) {
          provider.updateTaskStatus(details.data.id, status);
          context.read<HapticsService>().subtleClick();
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHovering
                  ? color.withValues(alpha: 0.08)
                  : AppTheme.islandSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isHovering
                    ? color.withValues(alpha: 0.6)
                    : AppTheme.islandBorder.withValues(alpha: 0.3),
                width: isHovering ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                // ── Column header ─────────────────────────────────
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Task list ─────────────────────────────────────
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            'Drop tasks here',
                            style: TextStyle(
                              color: AppTheme.subtleGrey.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: tasks.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final task = tasks[i];
                            return LongPressDraggable<Task>(
                              data: task,
                              feedback: _DragFeedback(task: task, color: color),
                              childWhenDragging: Opacity(
                                opacity: 0.25,
                                child: _MiniTaskCard(task: task, color: color),
                              ),
                              child: _MiniTaskCard(task: task, color: color)
                                  .animate(
                                      delay: Duration(milliseconds: 60 * i))
                                  .fadeIn(
                                    duration: 400.ms,
                                    curve: Curves.easeOutExpo,
                                  )
                                  .slideY(
                                    begin: 0.08,
                                    end: 0,
                                    duration: 400.ms,
                                    curve: Curves.easeOutBack,
                                  ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Mini Task Card (compact card for board columns)
// ═══════════════════════════════════════════════════════════════════════

class _MiniTaskCard extends StatelessWidget {
  const _MiniTaskCard({required this.task, required this.color});

  final Task task;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.pitchBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.islandBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
              color: task.isCompleted ? AppTheme.subtleGrey : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _priorityColor(task.priority).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.priority.label,
                  style: TextStyle(
                    color: _priorityColor(task.priority),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.high => const Color(0xFFFF453A),
        TaskPriority.medium => const Color(0xFFFF9F0A),
        TaskPriority.low => const Color(0xFF34C759),
      };
}

// ═══════════════════════════════════════════════════════════════════════
// Drag Feedback (floating card under finger)
// ═══════════════════════════════════════════════════════════════════════

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.task, required this.color});

  final Task task;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.islandSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          task.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
