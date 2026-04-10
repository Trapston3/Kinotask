import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../services/haptics_service.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.tasks;
    final haptics = context.read<HapticsService>();
    final theme = Theme.of(context);

    if (!taskProvider.isReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return CustomScrollView(
      key: const ValueKey<String>('screen-root-Tasks'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar.large(
          pinned: true,
          stretch: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Tasks',
            style: theme.textTheme.headlineLarge,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
          sliver: SliverList.list(
            children: [
              Text(
                'Your next actions stay oversized, thumb-friendly, and easy to scan from the lower half of the screen.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (tasks.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No tasks yet. Use the big add button to capture your next priority.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              for (final task in tasks) ...[
                TaskCard(
                  task: task,
                  hapticsService: haptics,
                  onToggleComplete: () {
                    taskProvider.toggleTaskCompletion(task.id);
                  },
                  onDelete: () {
                    taskProvider.deleteTask(task.id);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
