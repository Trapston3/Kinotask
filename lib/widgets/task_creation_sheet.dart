import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';

class TaskCreationSheet extends StatefulWidget {
  const TaskCreationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => const TaskCreationSheet(),
    );
  }

  @override
  State<TaskCreationSheet> createState() => _TaskCreationSheetState();
}

class _TaskCreationSheetState extends State<TaskCreationSheet> {
  final TextEditingController _titleController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.medium;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        key: const ValueKey<String>('task-creation-sheet'),
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Task',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey<String>('task-title-field'),
              controller: _titleController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Task title',
                hintText: 'What needs attention?',
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [
                for (final priority in TaskPriority.values)
                  ChoiceChip(
                    label: Text(priority.label),
                    selected: _selectedPriority == priority,
                    onSelected: (_) {
                      setState(() {
                        _selectedPriority = priority;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set Alarm Time'),
              subtitle: Text(
                _selectedTime == null
                    ? 'Optional. Picks the next occurrence of the selected time.'
                    : _selectedTime!.format(context),
              ),
              trailing: TextButton(
                onPressed: _pickTime,
                child: const Text('Choose'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveTask,
                child: Text(_isSaving ? 'Saving...' : 'Create Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = time;
    });
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final alarmDateTime = _selectedTime == null
        ? null
        : _nextOccurrenceFor(_selectedTime!, DateTime.now());
    final notificationService = context.read<NotificationService>();
    final taskProvider = context.read<TaskProvider>();

    if (alarmDateTime != null && mounted) {
      await notificationService.requestAlarmPermissions();
    }

    await taskProvider.addTask(
          title: _titleController.text,
          priority: _selectedPriority,
          alarmDateTime: alarmDateTime,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  DateTime _nextOccurrenceFor(TimeOfDay time, DateTime now) {
    final candidate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (candidate.isAfter(now)) {
      return candidate;
    }

    return candidate.add(const Duration(days: 1));
  }
}
