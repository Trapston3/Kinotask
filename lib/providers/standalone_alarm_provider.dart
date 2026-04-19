import 'dart:convert';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/standalone_alarm.dart';
import '../services/notification_service.dart';
import '../services/standalone_alarm_storage.dart';

class StandaloneAlarmProvider extends ChangeNotifier {
  StandaloneAlarmProvider({
    StandaloneAlarmStorageService? storage,
    NotificationService? notificationService,
  }) : _storage = storage ?? StandaloneAlarmStorageService();

  final StandaloneAlarmStorageService _storage;
  List<StandaloneAlarm> _alarms = [];
  bool _isReady = false;

  List<StandaloneAlarm> get alarms => List.unmodifiable(_alarms);
  bool get isReady => _isReady;

  Future<void> initialize() async {
    _alarms = await _storage.loadAlarms();
    _isReady = true;
    notifyListeners();
  }

  Future<void> addAlarm(StandaloneAlarm alarm) async {
    _alarms.add(alarm);
    await _storage.saveAlarms(_alarms);
    await _syncAlarm(alarm);
    notifyListeners();
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    _alarms[index] = _alarms[index].copyWith(enabled: !_alarms[index].enabled);
    await _storage.saveAlarms(_alarms);
    await _syncAlarm(_alarms[index]);
    notifyListeners();
  }

  Future<void> deleteAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      await AndroidAlarmManager.cancel(int.parse(alarm.id.substring(alarm.id.length - 8)));
    }
    _alarms.removeWhere((a) => a.id == id);
    await _storage.saveAlarms(_alarms);
    notifyListeners();
  }

  Future<void> updateAlarm(StandaloneAlarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index == -1) return;
    _alarms[index] = alarm;
    await _storage.saveAlarms(_alarms);
    await _syncAlarm(alarm);
    notifyListeners();
  }

  Future<void> _syncAlarm(StandaloneAlarm alarm) async {
    final alarmIdInt = int.parse(alarm.id.substring(alarm.id.length - 8));
    if (!alarm.enabled) {
      await AndroidAlarmManager.cancel(alarmIdInt);
      return;
    }

    final now = DateTime.now();
    DateTime scheduleTime = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
    
    if (scheduleTime.isBefore(now)) {
      scheduleTime = scheduleTime.add(const Duration(days: 1));
    }

    // If it has repeat days, we need to find the next valid day.
    if (alarm.repeatDays.isNotEmpty) {
      while (!alarm.repeatDays.contains(scheduleTime.weekday)) {
        scheduleTime = scheduleTime.add(const Duration(days: 1));
      }
    }

    await AndroidAlarmManager.oneShotAt(
      scheduleTime,
      alarmIdInt,
      fireAlarm,
      exact: true,
      wakeup: true,
      alarmClock: true,
    );
  }
}

@pragma('vm:entry-point')
Future<void> fireAlarm(int id) async {
  // Separate isolate: must initialize everything manually.
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  final box = await Hive.openBox<String>('standalone_alarms');
  
  // Find the alarm by ID (id passed is the last 8 digits of the full string ID).
  String? foundJson;
  for (final value in box.values) {
    if (value.contains(id.toString())) {
      foundJson = value;
      break;
    }
  }

  if (foundJson != null) {
    final Map<String, dynamic> data = jsonDecode(foundJson) as Map<String, dynamic>;
    final label = data['label'] as String? ?? 'Alarm';
    
    // We can't easily use NotificationService here because it depends on providers.
    // Use the plugin directly for the isolate trigger.
    final plugin = FlutterLocalNotificationsPlugin();
    const androidDetails = AndroidNotificationDetails(
      'standalone_alarms_channel',
      'Standalone Alarms',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
    );
    
    const details = NotificationDetails(android: androidDetails);
    
    await plugin.show(
      id: id,
      title: 'Kinotask Alarm',
      body: label,
      notificationDetails: details,
      payload: foundJson,
    );
  }
}
