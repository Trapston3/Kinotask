import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/alarm_trigger_payload.dart';
import '../models/task.dart';
import '../providers/alarm_coordinator.dart';

abstract interface class NotificationService {
  Future<void> initialize();

  Future<void> requestAlarmPermissions();

  Future<void> showAlarmNotification(AlarmTriggerPayload payload);

  Future<void> cancelForTaskId(String taskId);

  /// Whether the OS currently allows exact alarm scheduling (Android 14+).
  Future<bool> canScheduleExactAlarms();

  /// Show a simple, non-alarm notification (e.g. goal congratulation).
  Future<void> showStandardNotification({required String title, required String body});
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    AlarmCoordinator? alarmCoordinator,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _alarmCoordinator = alarmCoordinator;

  final FlutterLocalNotificationsPlugin _plugin;
  final AlarmCoordinator? _alarmCoordinator;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final details = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = details?.notificationResponse?.payload;
    if (launchPayload != null) {
      _activateChallengeFromPayload(launchPayload);
    }

    _isInitialized = true;
  }

  @override
  Future<void> requestAlarmPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.requestFullScreenIntentPermission();
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showAlarmNotification(AlarmTriggerPayload payload) async {
    await initialize();

    final isHigh = payload.priority == TaskPriority.high;
    final isAlarm = payload.priority != TaskPriority.low;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelIdForPriority(payload.priority),
        _channelNameForPriority(payload.priority),
        channelDescription: _channelDescriptionForPriority(payload.priority),
        importance: isAlarm ? Importance.max : Importance.defaultImportance,
        priority: isAlarm ? Priority.max : Priority.defaultPriority,
        category: isAlarm
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(
          isAlarm
              // 5-pulse alarm pattern (much more aggressive than a notification)
              ? [0, 800, 200, 800, 200, 800, 200, 800, 200, 800]
              : [0, 110, 60, 90],
        ),
        ongoing: isAlarm,
        autoCancel: !isAlarm,
        // ── KEY FIX: both High AND Medium get full-screen intent ──
        fullScreenIntent: isAlarm,
        // ── Use alarm audio stream so sound respects alarm volume ──
        audioAttributesUsage: isAlarm
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        visibility: NotificationVisibility.public,
        ticker: payload.title,
        additionalFlags: isAlarm ? Int32List.fromList(<int>[4]) : null,
        // High never auto-dismisses; Medium times out after 60 s.
        timeoutAfter: isHigh ? null : 60000,
      ),
    );

    await _plugin.show(
      id: payload.notificationId,
      title: payload.title,
      body: payload.body,
      notificationDetails: details,
      payload: jsonEncode(payload.toJson()),
    );
  }

  @override
  Future<void> cancelForTaskId(String taskId) async {
    await initialize();
    await _plugin.cancel(id: AlarmTriggerPayload.notificationIdFor(taskId));
  }

  @override
  Future<void> showStandardNotification({required String title, required String body}) async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'kinotask_general',
        'General Notifications',
        channelDescription: 'Non-alarm notifications like goal achievements.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) {
      return;
    }

    _activateChallengeFromPayload(payload);
  }

  void _activateChallengeFromPayload(String payloadJson) {
    if (_alarmCoordinator == null) {
      return;
    }

    final payload = AlarmTriggerPayload.fromJson(
      jsonDecode(payloadJson) as Map<String, dynamic>,
    );

    if (payload.priority == TaskPriority.high) {
      _alarmCoordinator.activate(payload);
    }
  }

  String _channelIdForPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'tasks_low_priority';
      case TaskPriority.medium:
        return 'tasks_medium_alarm';
      case TaskPriority.high:
        return 'tasks_high_alarm';
    }
  }

  String _channelNameForPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low Priority Reminders';
      case TaskPriority.medium:
        return 'Medium Priority Alarms';
      case TaskPriority.high:
        return 'High Priority Captcha Alarms';
    }
  }

  String _channelDescriptionForPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Standard reminders for low-priority tasks.';
      case TaskPriority.medium:
        return 'Ringing alarms for medium-priority tasks.';
      case TaskPriority.high:
        return 'Full-screen alarms that require a captcha to dismiss.';
    }
  }
}
