import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/haptics_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class TaskCreationSheet extends StatefulWidget {
  const TaskCreationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const TaskCreationSheet(),
    );
  }

  @override
  State<TaskCreationSheet> createState() => _TaskCreationSheetState();
}

class _TaskCreationSheetState extends State<TaskCreationSheet> {
  final TextEditingController _titleController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDateTime;
  bool _isRecurring = false;
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
                      context.read<HapticsService>().subtleClick();
                      setState(() {
                        _selectedPriority = priority;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Date & Time (Optional)',
              style: TextStyle(
                color: AppTheme.subtleGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: _selectedDateTime ?? DateTime.now(),
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() => _selectedDateTime = newTime);
                  },
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recurring Daily'),
              value: _isRecurring,
              onChanged: (value) {
                context.read<HapticsService>().subtleClick();
                setState(() {
                  _isRecurring = value;
                });
              },
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



  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final notificationService = context.read<NotificationService>();
    final taskProvider = context.read<TaskProvider>();

    if (_selectedDateTime != null && mounted) {
      await notificationService.requestAlarmPermissions();
    }

    await taskProvider.addTask(
      title: _titleController.text,
      priority: _selectedPriority,
      alarmDateTime: _selectedDateTime,
      isRecurring: _isRecurring,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
