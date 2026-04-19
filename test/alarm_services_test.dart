import 'package:flutter_test/flutter_test.dart';

import 'package:productivity_app/models/alarm_trigger_payload.dart';
import 'package:productivity_app/models/task.dart';
import 'package:productivity_app/services/alarm_service.dart';
import 'package:productivity_app/services/notification_service.dart';

class FakeAlarmSchedulerDriver implements AlarmSchedulerDriver {
  final List<AlarmScheduleRequest> scheduled = [];
  final List<int> cancelled = [];

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleOneShot(AlarmScheduleRequest request) async {
    scheduled.add(request);
  }
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

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<void> showStandardNotification({required String title, required String body}) async {}
}

void main() {
  group('AndroidAlarmService', () {
    test('routes alarm-backed tasks to alarm manager with payload metadata', () async {
      final scheduler = FakeAlarmSchedulerDriver();
      final notifications = FakeNotificationService();
      final service = AndroidAlarmService(
        schedulerDriver: scheduler,
        notificationService: notifications,
      );

      await service.syncTasks(const [
        Task(
          id: 'low-task',
          title: 'Low task',
          priority: TaskPriority.low,
          alarmTime: '2026-04-11T08:00:00.000',
        ),
        Task(
          id: 'medium-task',
          title: 'Medium task',
          priority: TaskPriority.medium,
          alarmTime: '2026-04-11T09:00:00.000',
        ),
        Task(
          id: 'high-task',
          title: 'High task',
          priority: TaskPriority.high,
          alarmTime: '2026-04-11T10:00:00.000',
        ),
      ]);

      expect(notifications, isNotNull);
      expect(scheduler.scheduled, hasLength(3));
      expect(scheduler.scheduled.map((item) => item.payload.taskId), containsAll([
        'low-task',
        'medium-task',
        'high-task',
      ]));
    });
  });
}
