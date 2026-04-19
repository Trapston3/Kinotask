class StandaloneAlarm {
  const StandaloneAlarm({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.repeatDays = const [],
  });

  final String id;
  final String label;
  final int hour;
  final int minute;
  final bool enabled;
  /// Days of week: 1 = Monday … 7 = Sunday.  Empty = one-shot.
  final List<int> repeatDays;

  String get timeDisplay {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
  }

  String get repeatLabel {
    if (repeatDays.isEmpty) return 'One-shot';
    if (repeatDays.length == 7) return 'Every day';
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = [...repeatDays]..sort();
    return sorted.map((d) => names[d]).join(', ');
  }

  StandaloneAlarm copyWith({
    String? id,
    String? label,
    int? hour,
    int? minute,
    bool? enabled,
    List<int>? repeatDays,
  }) {
    return StandaloneAlarm(
      id: id ?? this.id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
      'repeatDays': repeatDays,
    };
  }

  factory StandaloneAlarm.fromJson(Map<String, dynamic> json) {
    return StandaloneAlarm(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      enabled: json['enabled'] as bool? ?? true,
      repeatDays: (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }
}
