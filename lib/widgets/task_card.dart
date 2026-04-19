import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/haptics_service.dart';
import '../theme/app_theme.dart';
import 'pencil_scratch_text.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.hapticsService,
    required this.onToggleComplete,
    required this.onDelete,
    this.onCelebrate,
  });

  final Task task;
  final HapticsService hapticsService;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback? onCelebrate;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  static const double _dismissThreshold = 0.35;
  bool _hasTriggeredDismissTick = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<String>('task-dismissible-${widget.task.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {
        DismissDirection.endToStart: _dismissThreshold,
      },
      onUpdate: (details) {
        final crossed = details.progress >= _dismissThreshold;
        if (crossed && !_hasTriggeredDismissTick) {
          _hasTriggeredDismissTick = true;
          unawaited(widget.hapticsService.playDismissThresholdTick());
        } else if (!crossed) {
          _hasTriggeredDismissTick = false;
        }
      },
      onDismissed: (_) {
        unawaited(widget.hapticsService.vibrateRamping());
        widget.onDelete();
      },
      background: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.islandRadius),
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          color: AppTheme.destructiveRed.withValues(alpha: 0.85),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
      ),
      child: AnimatedOpacity(
        key: ValueKey<String>('task-opacity-${widget.task.id}'),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        opacity: widget.task.isCompleted ? 0.55 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.islandSurface,
            borderRadius: BorderRadius.circular(AppTheme.islandRadius),
          ),
          child: InkWell(
            key: ValueKey<String>('task-surface-${widget.task.id}'),
            borderRadius: BorderRadius.circular(AppTheme.islandRadius),
            onTap: () {
              final wasCompleted = widget.task.isCompleted;
              widget.onToggleComplete();
              if (!wasCompleted) {
                unawaited(widget.hapticsService.playTaskScratchPattern());
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _TaskCheckbox(isCompleted: widget.task.isCompleted),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PencilScratchText(
                          key: ValueKey<String>(
                            'task-scratch-${widget.task.id}',
                          ),
                          text: widget.task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.task.isCompleted
                                ? AppTheme.subtleGrey
                                : Colors.white,
                          ),
                          isCompleted: widget.task.isCompleted,
                          onScratchComplete: widget.onCelebrate,
                        ),
                        const SizedBox(height: 6),
                        _buildSubtitle(),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppTheme.subtleGrey,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    if (widget.task.isCompleted) {
      return const Text(
        'Completed today',
        style: TextStyle(color: AppTheme.subtleGrey, fontSize: 13),
      );
    }

    final priorityColor = _priorityColor(widget.task.priority);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.task.priority.label,
            style: TextStyle(
              color: priorityColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (widget.task.alarmDateTime != null) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.alarm_rounded,
            size: 14,
            color: AppTheme.subtleGrey,
          ),
          const SizedBox(width: 4),
          Text(
            _formatAlarmTime(),
            style: const TextStyle(
              color: AppTheme.subtleGrey,
              fontSize: 12,
            ),
          ),
        ],
        if (widget.task.isRecurring) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.repeat_rounded,
            size: 14,
            color: AppTheme.accentBlue,
          ),
        ],
      ],
    );
  }

  String _formatAlarmTime() {
    final dt = widget.task.alarmDateTime;
    if (dt == null) return '';
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inHours < 1) return '${diff.inMinutes}m left';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    return '${diff.inDays}d left';
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(0xFF34C759);
      case TaskPriority.medium:
        return const Color(0xFF007AFF);
      case TaskPriority.high:
        return const Color(0xFFFF9F0A);
    }
  }
}

class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? AppTheme.accentBlue : Colors.transparent,
        border: Border.all(
          color: isCompleted ? AppTheme.accentBlue : AppTheme.islandBorder,
          width: 2,
        ),
      ),
      child: isCompleted
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}
