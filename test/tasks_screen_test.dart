import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:productivity_app/app.dart';
import 'package:productivity_app/models/alarm_trigger_payload.dart';
import 'package:productivity_app/models/task.dart';
import 'package:productivity_app/providers/alarm_coordinator.dart';
import 'package:productivity_app/providers/navigation_provider.dart';
import 'package:productivity_app/providers/task_provider.dart';
import 'package:productivity_app/services/alarm_service.dart';
import 'package:productivity_app/services/haptics_service.dart';
import 'package:productivity_app/services/notification_service.dart';
import 'package:productivity_app/services/task_storage_service.dart';
import 'package:productivity_app/widgets/pencil_scratch_text.dart';

class FakeTaskStorageService implements TaskStorageService {
  @override
  Future<List<Task>> loadTasks() async => const [];

  @override
  Future<void> saveTasks(List<Task> tasks) async {}
}

class FakeAlarmService implements AlarmService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncTasks(Iterable<Task> tasks) async {}
}

class FakeNotificationService implements NotificationService {
  @override
  Future<void> cancelForTaskId(String taskId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestAlarmPermissions() async {}

  @override
  Future<void> showAlarmNotification(AlarmTriggerPayload payload) async {}
}

class FakeHapticsService implements HapticsService {
  int scratchCalls = 0;
  int dismissTickCalls = 0;

  @override
  Future<void> playDismissThresholdTick() async {
    dismissTickCalls++;
  }

  @override
  Future<void> playTaskScratchPattern() async {
    scratchCalls++;
  }
}

Widget buildTestApp({
  TaskProvider? taskProvider,
  FakeHapticsService? hapticsService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NavigationProvider>(
        create: (_) => NavigationProvider(),
      ),
      ChangeNotifierProvider<AlarmCoordinator>(
        create: (_) => AlarmCoordinator(),
      ),
      ChangeNotifierProvider<TaskProvider>.value(
        value: taskProvider ??
            TaskProvider(
              storageService: FakeTaskStorageService(),
              alarmService: FakeAlarmService(),
              initialTasks: const [
                Task(
                  id: 'review-sprint-goals',
                  title: 'Review sprint goals',
                  priority: TaskPriority.high,
                ),
              ],
              isReadyOverride: true,
            ),
      ),
      Provider<HapticsService>.value(
        value: hapticsService ?? FakeHapticsService(),
      ),
      Provider<NotificationService>.value(
        value: FakeNotificationService(),
      ),
      Provider<AlarmService>.value(
        value: FakeAlarmService(),
      ),
    ],
    child: const ProductivityApp(),
  );
}

void main() {
  testWidgets('renders seeded tasks with visible priority metadata', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('Review sprint goals'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('tasks-add-fab')), findsOneWidget);
  });

  testWidgets('tapping anywhere on the task card triggers scratch completion and haptics', (
    WidgetTester tester,
  ) async {
    final haptics = FakeHapticsService();
    final provider = TaskProvider(
      storageService: FakeTaskStorageService(),
      alarmService: FakeAlarmService(),
      initialTasks: const [
        Task(
          id: 'review-sprint-goals',
          title: 'Review sprint goals',
          priority: TaskPriority.high,
        ),
      ],
      isReadyOverride: true,
    );

    await tester.pumpWidget(
      buildTestApp(taskProvider: provider, hapticsService: haptics),
    );

    await tester.tap(find.byKey(const ValueKey<String>('task-surface-review-sprint-goals')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(haptics.scratchCalls, 1);
    expect(provider.tasks.single.isCompleted, isTrue);

    final scratchText = tester.widget<PencilScratchText>(
      find.byKey(const ValueKey<String>('task-scratch-review-sprint-goals')),
    );
    final animatedOpacity = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey<String>('task-opacity-review-sprint-goals')),
    );

    expect(scratchText.isCompleted, isTrue);
    expect(animatedOpacity.opacity, lessThan(1));
  });

  testWidgets('fab opens the add-task bottom sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.byKey(const ValueKey<String>('tasks-add-fab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('task-creation-sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('task-title-field')), findsOneWidget);
    expect(find.text('Set Alarm Time'), findsOneWidget);
  });

  testWidgets('swiping past the dismiss threshold plays a tick and deletes the card', (
    WidgetTester tester,
  ) async {
    final haptics = FakeHapticsService();
    final provider = TaskProvider(
      storageService: FakeTaskStorageService(),
      alarmService: FakeAlarmService(),
      initialTasks: const [
        Task(
          id: 'review-sprint-goals',
          title: 'Review sprint goals',
          priority: TaskPriority.high,
        ),
      ],
      isReadyOverride: true,
    );

    await tester.pumpWidget(
      buildTestApp(taskProvider: provider, hapticsService: haptics),
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('task-dismissible-review-sprint-goals')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(haptics.dismissTickCalls, 1);
    expect(find.text('Review sprint goals'), findsNothing);
  });
}
