import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/haptics_service.dart';
import 'pencil_scratch_text.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.hapticsService,
    required this.onToggleComplete,
    required this.onDelete,
  });

  final Task task;
  final HapticsService hapticsService;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  static const double _dismissThreshold = 0.35;
  bool _hasTriggeredDismissTick = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = _priorityColor(widget.task.priority);
    final cardOpacity = widget.task.isCompleted ? 0.58 : 1.0;
    final textStyle = theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: widget.task.isCompleted
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurface,
        ) ??
        const TextStyle();

    return Dismissible(
      key: ValueKey<String>('task-dismissible-${widget.task.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {
        DismissDirection.endToStart: _dismissThreshold,
      },
      onUpdate: (details) {
        final crossedThreshold = details.progress >= _dismissThreshold;
        if (crossedThreshold && !_hasTriggeredDismissTick) {
          _hasTriggeredDismissTick = true;
          unawaited(widget.hapticsService.playDismissThresholdTick());
        } else if (!crossedThreshold) {
          _hasTriggeredDismissTick = false;
        }
      },
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      child: AnimatedOpacity(
        key: ValueKey<String>('task-opacity-${widget.task.id}'),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        opacity: cardOpacity,
        child: Card(
          child: InkWell(
            key: ValueKey<String>('task-surface-${widget.task.id}'),
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              final wasCompleted = widget.task.isCompleted;
              widget.onToggleComplete();
              if (!wasCompleted) {
                unawaited(widget.hapticsService.playTaskScratchPattern());
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TaskStatusGlyph(
                    isCompleted: widget.task.isCompleted,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: priorityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.task.priority.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: priorityColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (widget.task.alarmDateTime != null) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.alarm_rounded,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        PencilScratchText(
                          key: ValueKey<String>('task-scratch-${widget.task.id}'),
                          text: widget.task.title,
                          style: textStyle,
                          isCompleted: widget.task.isCompleted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

class _TaskStatusGlyph extends StatelessWidget {
  const _TaskStatusGlyph({
    required this.isCompleted,
  });

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? theme.colorScheme.primary : Colors.transparent,
        border: Border.all(
          color:
              isCompleted ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check_rounded,
        size: 20,
        color: isCompleted ? Colors.white : Colors.transparent,
      ),
    );
  }
}
