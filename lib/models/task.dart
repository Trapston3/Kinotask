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
    this.isRecurring = false,
    this.alarmTime,
    this.createdAt,
    this.status = 'To Do',
  });

  final String id;
  final String title;
  final bool isCompleted;
  final bool isRecurring;
  final TaskPriority priority;
  final String? alarmTime;
  final String? createdAt;

  /// Kanban status: 'To Do', 'In Progress', 'Done'.
  final String status;

  DateTime? get alarmDateTime =>
      alarmTime == null ? null : DateTime.tryParse(alarmTime!);

  DateTime? get createdAtDateTime =>
      createdAt == null ? null : DateTime.tryParse(createdAt!);

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    bool? isRecurring,
    TaskPriority? priority,
    String? alarmTime,
    bool clearAlarmTime = false,
    String? createdAt,
    String? status,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isRecurring: isRecurring ?? this.isRecurring,
      priority: priority ?? this.priority,
      alarmTime: clearAlarmTime ? null : (alarmTime ?? this.alarmTime),
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'isRecurring': isRecurring,
      'priority': priority.name,
      'alarmTime': alarmTime,
      'createdAt': createdAt,
      'status': status,
    };
  }

  factory Task.fromJson(Map<dynamic, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isRecurring: json['isRecurring'] as bool? ?? false,
      priority: TaskPriority.fromName(json['priority'] as String? ?? 'medium'),
      alarmTime: json['alarmTime'] as String?,
      createdAt: json['createdAt'] as String?,
      status: json['status'] as String? ?? 'To Do',
    );
  }
}
