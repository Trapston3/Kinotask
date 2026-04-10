enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const TaskPriority(this.label);

  final String label;

  static TaskPriority fromName(String value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.priority,
    this.isCompleted = false,
    this.alarmTime,
    this.createdAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final TaskPriority priority;
  final String? alarmTime;
  final String? createdAt;

  DateTime? get alarmDateTime =>
      alarmTime == null ? null : DateTime.tryParse(alarmTime!);

  DateTime? get createdAtDateTime =>
      createdAt == null ? null : DateTime.tryParse(createdAt!);

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    TaskPriority? priority,
    String? alarmTime,
    bool clearAlarmTime = false,
    String? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      alarmTime: clearAlarmTime ? null : (alarmTime ?? this.alarmTime),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'priority': priority.name,
      'alarmTime': alarmTime,
      'createdAt': createdAt,
    };
  }

  factory Task.fromJson(Map<dynamic, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: TaskPriority.fromName(json['priority'] as String? ?? 'medium'),
      alarmTime: json['alarmTime'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
