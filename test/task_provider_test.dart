import 'package:flutter_test/flutter_test.dart';

import 'package:productivity_app/models/task.dart';
import 'package:productivity_app/providers/task_provider.dart';
import 'package:productivity_app/services/alarm_service.dart';
import 'package:productivity_app/services/task_storage_service.dart';

class FakeTaskStorageService implements TaskStorageService {
  FakeTaskStorageService({
    this.seededTasks,
  });

  final List<Task>? seededTasks;
  List<Task>? savedTasks;

  @override
  Future<List<Task>> loadTasks() async => List<Task>.from(seededTasks ?? const []);

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    savedTasks = List<Task>.from(tasks);
  }
}

class FakeAlarmService implements AlarmService {
  List<Task> lastSyncedTasks = const [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncTasks(Iterable<Task> tasks) async {
    lastSyncedTasks = List<Task>.from(tasks);
  }
}

void main() {
  group('TaskProvider', () {
    test('loads persisted tasks on initialize and syncs alarms', () async {
      final storage = FakeTaskStorageService(
        seededTasks: const [
          Task(
            id: 'persisted-task',
            title: 'Persisted task',
            priority: TaskPriority.high,
            alarmTime: '2026-04-11T09:30:00.000',
          ),
        ],
      );
      final alarms = FakeAlarmService();
      final provider = TaskProvider(
        storageService: storage,
        alarmService: alarms,
      );

      await provider.initialize();

      expect(provider.isReady, isTrue);
      expect(provider.tasks, hasLength(1));
      expect(provider.tasks.single.title, 'Persisted task');
      expect(provider.tasks.single.alarmDateTime, isNotNull);
      expect(alarms.lastSyncedTasks.single.id, 'persisted-task');
    });

    test('adds a task with alarm time then persists and syncs', () async {
      final storage = FakeTaskStorageService();
      final alarms = FakeAlarmService();
      final provider = TaskProvider(
        storageService: storage,
        alarmService: alarms,
      );

      await provider.initialize();

      final created = await provider.addTask(
        title: 'Ship alarm architecture',
        priority: TaskPriority.medium,
        alarmDateTime: DateTime.parse('2026-04-11T07:15:00.000'),
      );

      expect(created.priority, TaskPriority.medium);
      expect(created.alarmDateTime, isNotNull);
      expect(storage.savedTasks, isNotNull);
      expect(storage.savedTasks!.last.title, 'Ship alarm architecture');
      expect(alarms.lastSyncedTasks.last.id, created.id);
    });

    test('toggling completion persists updated task state', () async {
      final storage = FakeTaskStorageService(
        seededTasks: const [
          Task(
            id: 'review-sprint-goals',
            title: 'Review sprint goals',
            priority: TaskPriority.high,
          ),
        ],
      );
      final provider = TaskProvider(
        storageService: storage,
        alarmService: FakeAlarmService(),
      );

      await provider.initialize();
      await provider.toggleTaskCompletion('review-sprint-goals');

      expect(provider.tasks.single.isCompleted, isTrue);
      expect(storage.savedTasks!.single.isCompleted, isTrue);
    });
  });
}
