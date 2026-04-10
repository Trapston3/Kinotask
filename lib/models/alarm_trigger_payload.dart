import 'task.dart';

class AlarmTriggerPayload {
  const AlarmTriggerPayload({
    required this.taskId,
    required this.title,
    required this.priority,
    required this.alarmTime,
  });

  final String taskId;
  final String title;
  final TaskPriority priority;
  final String alarmTime;

  String get body {
    switch (priority) {
      case TaskPriority.low:
        return 'A gentle reminder for this task.';
      case TaskPriority.medium:
        return 'This task is due now. Open the app and take action.';
      case TaskPriority.high:
        return 'Solve the captcha to silence this alarm.';
    }
  }

  int get notificationId => notificationIdFor(taskId);

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'priority': priority.name,
      'alarmTime': alarmTime,
    };
  }

  factory AlarmTriggerPayload.fromTask(Task task) {
    return AlarmTriggerPayload(
      taskId: task.id,
      title: task.title,
      priority: task.priority,
      alarmTime: task.alarmTime ?? '',
    );
  }

  factory AlarmTriggerPayload.fromJson(Map<String, dynamic> json) {
    return AlarmTriggerPayload(
      taskId: json['taskId'] as String,
      title: json['title'] as String,
      priority: TaskPriority.fromName(json['priority'] as String? ?? 'medium'),
      alarmTime: json['alarmTime'] as String? ?? '',
    );
  }

  static int notificationIdFor(String taskId) {
    var hash = 0;
    for (final codeUnit in taskId.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
