/// Lightweight regex-based NLP parser for extracting actionable tasks
/// from free-form text (typed or dictated).
class NlpTaskExtraction {
  const NlpTaskExtraction({required this.taskTitle, this.suggestedDate});

  final String taskTitle;
  final DateTime? suggestedDate;
}

class NlpParser {
  NlpParser._();

  /// Common action verbs that start a task-like phrase.
  static final _actionVerbs = RegExp(
    r'^(finish|complete|submit|send|call|email|review|prepare|write|'
    r'schedule|meet|buy|get|pick up|clean|fix|do|make|start|research|read)\b',
    caseSensitive: false,
  );

  /// Relative date keywords.
  static final _relativeDate = RegExp(
    r'\b(today|tonight|tomorrow|next week)\b',
    caseSensitive: false,
  );

  /// Day-of-week.
  static final _dayOfWeek = RegExp(
    r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    caseSensitive: false,
  );

  /// Time pattern: "at 5pm", "at 3:30 PM", "by 10am".
  static final _time = RegExp(
    r'(?:at|by)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)',
    caseSensitive: false,
  );

  /// The full date+time tail to strip from the task title.
  static final _dateTail = RegExp(
    r'\s*(?:on|by|at|tomorrow|today|tonight|next week'
    r'|monday|tuesday|wednesday|thursday|friday|saturday|sunday)'
    r'.*$',
    caseSensitive: false,
  );

  /// Attempts to extract a task from [text]. Returns `null` if no
  /// actionable pattern is found.
  static NlpTaskExtraction? tryExtract(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !_actionVerbs.hasMatch(trimmed)) return null;

    // ── Resolve date ──────────────────────────────────────────────
    DateTime? date;
    final now = DateTime.now();

    final relMatch = _relativeDate.firstMatch(trimmed);
    if (relMatch != null) {
      switch (relMatch.group(1)!.toLowerCase()) {
        case 'today':
        case 'tonight':
          date = DateTime(now.year, now.month, now.day, 18);
          break;
        case 'tomorrow':
          date = DateTime(now.year, now.month, now.day + 1, 9);
          break;
        case 'next week':
          date = DateTime(now.year, now.month, now.day + 7, 9);
          break;
      }
    }

    final dowMatch = _dayOfWeek.firstMatch(trimmed);
    if (dowMatch != null) {
      date = _nextWeekday(_dowIndex(dowMatch.group(1)!), now);
    }

    // ── Resolve time ──────────────────────────────────────────────
    final timeMatch = _time.firstMatch(trimmed);
    if (timeMatch != null && date != null) {
      var hour = int.parse(timeMatch.group(1)!);
      final min = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
      final ampm = timeMatch.group(3)!.toLowerCase();
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      date = DateTime(date.year, date.month, date.day, hour, min);
    }

    if (date == null) return null;

    // ── Extract title ─────────────────────────────────────────────
    final title = trimmed.replaceAll(_dateTail, '').trim();
    if (title.isEmpty) return null;

    return NlpTaskExtraction(taskTitle: title, suggestedDate: date);
  }

  static int _dowIndex(String day) {
    const days = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };
    return days[day.toLowerCase()] ?? DateTime.monday;
  }

  static DateTime _nextWeekday(int weekday, DateTime from) {
    var diff = weekday - from.weekday;
    if (diff <= 0) diff += 7;
    return DateTime(from.year, from.month, from.day + diff, 9);
  }
}
