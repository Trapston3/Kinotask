import 'dart:convert';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import '../models/alarm_trigger_payload.dart';
import '../models/task.dart';
import 'notification_service.dart';

abstract interface class AlarmService {
  Future<void> initialize();

  Future<void> syncTasks(Iterable<Task> tasks);
}

class AlarmScheduleRequest {
  const AlarmScheduleRequest({
    required this.alarmId,
    required this.scheduledAt,
    required this.payload,
  });

  final int alarmId;
  final DateTime scheduledAt;
  final AlarmTriggerPayload payload;
}

abstract interface class AlarmSchedulerDriver {
  Future<void> initialize();

  Future<void> scheduleOneShot(AlarmScheduleRequest request);

  Future<void> cancel(int id);
}

class AndroidAlarmManagerSchedulerDriver implements AlarmSchedulerDriver {
  @override
  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  @override
  Future<void> scheduleOneShot(AlarmScheduleRequest request) async {
    try {
      await AndroidAlarmManager.oneShotAt(
        request.scheduledAt,
        request.alarmId,
        alarmCallbackDispatcher,
        alarmClock: request.payload.priority != TaskPriority.low,
        allowWhileIdle: true,
        exact: true,
        wakeup: request.payload.priority != TaskPriority.low,
        rescheduleOnReboot: true,
        params: request.payload.toJson(),
      );
    } catch (_) {
      // Permission prompts and OEM alarm restrictions should not crash task persistence.
    }
  }

  @override
  Future<void> cancel(int id) async {
    await AndroidAlarmManager.cancel(id);
  }
}

class AndroidAlarmService implements AlarmService {
  AndroidAlarmService({
    required NotificationService notificationService,
    AlarmSchedulerDriver? schedulerDriver,
  }) : _schedulerDriver = schedulerDriver ?? AndroidAlarmManagerSchedulerDriver();

  final AlarmSchedulerDriver _schedulerDriver;
  final Set<int> _scheduledIds = <int>{};

  @override
  Future<void> initialize() async {
    await _schedulerDriver.initialize();
  }

  @override
  Future<void> syncTasks(Iterable<Task> tasks) async {
    final desiredRequests = <AlarmScheduleRequest>[];

    for (final task in tasks) {
      final alarmDateTime = task.alarmDateTime;
      if (alarmDateTime == null || task.isCompleted) {
        continue;
      }
      if (!alarmDateTime.isAfter(DateTime.now())) {
        continue;
      }

      desiredRequests.add(
        AlarmScheduleRequest(
          alarmId: AlarmTriggerPayload.notificationIdFor(task.id),
          scheduledAt: alarmDateTime,
          payload: AlarmTriggerPayload.fromTask(task),
        ),
      );
    }

    final desiredIds = desiredRequests.map((request) => request.alarmId).toSet();
    final obsoleteIds = _scheduledIds.difference(desiredIds);

    for (final id in obsoleteIds) {
      await _schedulerDriver.cancel(id);
    }

    for (final request in desiredRequests) {
      await _schedulerDriver.scheduleOneShot(request);
    }

    _scheduledIds
      ..clear()
      ..addAll(desiredIds);
  }
}

@pragma('vm:entry-point')
Future<void> alarmCallbackDispatcher(int id, Map<String, dynamic> params) async {
  final notificationService = LocalNotificationService();
  final payload = AlarmTriggerPayload.fromJson(
    jsonDecode(jsonEncode(params)) as Map<String, dynamic>,
  );

  await notificationService.initialize();
  await notificationService.showAlarmNotification(payload);
}
