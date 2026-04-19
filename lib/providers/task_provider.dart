import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/alarm_service.dart';
import '../services/task_storage_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({
    required TaskStorageService storageService,
    required AlarmService alarmService,
    List<Task>? initialTasks,
    bool isReadyOverride = false,
  })  : _storageService = storageService,
        _alarmService = alarmService,
        _tasks = List<Task>.from(initialTasks ?? _seedTasks),
        _isReady = isReadyOverride;

  static final List<Task> _seedTasks = [
    Task(
      id: 'review-sprint-goals',
      title: 'Review sprint goals',
      priority: TaskPriority.high,
      createdAt: DateTime(2026, 4, 10, 8, 0).toIso8601String(),
    ),
    Task(
      id: 'capture-quick-notes',
      title: 'Capture quick notes from standup',
      priority: TaskPriority.medium,
      createdAt: DateTime(2026, 4, 10, 8, 30).toIso8601String(),
    ),
    Task(
      id: 'stretch-and-reset',
      title: 'Stretch and reset posture',
      priority: TaskPriority.low,
      createdAt: DateTime(2026, 4, 10, 9, 0).toIso8601String(),
    ),
  ];

  final TaskStorageService _storageService;
  final AlarmService _alarmService;
  final List<Task> _tasks;
  bool _isReady;

  bool get isReady => _isReady;

  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  // ── Kanban filtered views ───────────────────────────────────────
  List<Task> get todoTasks =>
      _tasks.where((t) => t.status == 'To Do' && !t.isCompleted).toList();

  List<Task> get inProgressTasks =>
      _tasks.where((t) => t.status == 'In Progress' && !t.isCompleted).toList();

  List<Task> get doneTasks =>
      _tasks.where((t) => t.status == 'Done' || t.isCompleted).toList();

  Future<void> initialize() async {
    if (_isReady) {
      await _alarmService.syncTasks(_tasks);
      return;
    }

    final storedTasks = await _storageService.loadTasks();
    _tasks
      ..clear()
      ..addAll(storedTasks.isEmpty ? _seedTasks : storedTasks);
    _isReady = true;

    await _persistAndSync();
    notifyListeners();
  }

  Future<Task> addTask({
    required String title,
    TaskPriority priority = TaskPriority.medium,
    DateTime? alarmDateTime,
    bool isRecurring = false,
  }) async {
    final task = Task(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_tasks.length}',
      title: title.trim(),
      priority: priority,
      isRecurring: isRecurring,
      alarmTime: alarmDateTime?.toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
    );

    _tasks.add(task);
    notifyListeners();
    await _persistAndSync();
    return task;
  }

  Future<void> toggleTaskCompletion(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      return;
    }

    final current = _tasks[index];
    
    if (!current.isCompleted && current.isRecurring) {
      final now = DateTime.now();
      final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);
      
      _tasks[index] = current.copyWith(
        isCompleted: false,
        alarmTime: tomorrowMidnight.toIso8601String(),
      );
    } else {
      _tasks[index] = current.copyWith(
        isCompleted: !current.isCompleted,
        status: !current.isCompleted ? 'Done' : 'To Do',
      );
    }

    notifyListeners();
    await _persistAndSync();
  }

  /// Update the Kanban status of a task and persist to Hive.
  Future<void> updateTaskStatus(String id, String newStatus) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    _tasks[index] = _tasks[index].copyWith(
      status: newStatus,
      isCompleted: newStatus == 'Done',
    );
    notifyListeners();
    await _persistAndSync();
  }

  Future<void> deleteTask(String id) async {
    final initialLength = _tasks.length;
    _tasks.removeWhere((task) => task.id == id);
    if (_tasks.length == initialLength) {
      return;
    }

    notifyListeners();
    await _persistAndSync();
  }

  Future<void> _persistAndSync() async {
    await _storageService.saveTasks(List<Task>.from(_tasks));
    await _alarmService.syncTasks(_tasks);
  }
}
