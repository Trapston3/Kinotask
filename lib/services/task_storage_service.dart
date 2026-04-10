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
    if (rawValue is! List) {
      return const [];
    }

    return rawValue
        .whereType<Map>()
        .map(Task.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    final box = await _openBox();
    await box.put(
      _tasksKey,
      tasks.map((task) => task.toJson()).toList(growable: false),
    );
  }
}
