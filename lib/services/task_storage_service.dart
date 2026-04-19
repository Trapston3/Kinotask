import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

abstract interface class TaskStorageService {
  Future<List<Task>> loadTasks();

  Future<void> saveTasks(List<Task> tasks);
}

class HiveTaskStorageService implements TaskStorageService {
  HiveTaskStorageService({
    String boxName = 'productivity_tasks',
  }) : _boxName = boxName;

  final String _boxName;
  static const String _tasksKey = 'tasks';

  Future<Box<dynamic>> _openBox() {
    return Hive.openBox<dynamic>(_boxName);
  }

  @override
  Future<List<Task>> loadTasks() async {
    final box = await _openBox();
    final rawValue = box.get(_tasksKey);
    final validTasks = <Task>[];

    if (rawValue == null) {
      return validTasks;
    }

    Iterable<dynamic> rawIterable = [];

    if (rawValue is String) {
      try {
        final decoded = jsonDecode(rawValue);
        if (decoded is Iterable) {
          rawIterable = decoded;
        }
      } catch (_) {
        // Corrupted JSON string gracefully ignored
      }
    } else if (rawValue is Iterable) {
      rawIterable = rawValue;
    }

    for (final item in rawIterable) {
      if (item is Map) {
        try {
          validTasks.add(Task.fromJson(item));
        } catch (e) {
          debugPrint('Failed to parse a Task: $e');
        }
      }
    }

    return validTasks;
  }

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    final box = await _openBox();
    await box.put(
      _tasksKey,
      jsonEncode(tasks.map((task) => task.toJson()).toList(growable: false)),
    );
  }
}
