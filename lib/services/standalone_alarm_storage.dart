import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/standalone_alarm.dart';

class StandaloneAlarmStorageService {
  static const String _boxName = 'standalone_alarms';

  Future<List<StandaloneAlarm>> loadAlarms() async {
    final box = await Hive.openBox<String>(_boxName);
    return box.values
        .map((raw) =>
            StandaloneAlarm.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAlarms(List<StandaloneAlarm> alarms) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.clear();
    for (final alarm in alarms) {
      await box.put(alarm.id, jsonEncode(alarm.toJson()));
    }
  }
}
