import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Thin wrapper around `flutter_foreground_task` that exposes
/// start / update / stop for the "Now Bar" lock-screen notification.
class FocusTimerForegroundService {
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Call once during app initialization.
  void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'focus_timer_channel',
        channelName: 'Focus Timer',
        channelDescription: 'Shows the active timer or stopwatch countdown.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Start the foreground service with an initial notification.
  Future<void> start({
    required String title,
    required String text,
  }) async {
    if (_isRunning) {
      await update(title: title, text: text);
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: title,
      notificationText: text,
      callback: _startCallback,
    );
    _isRunning = true;
  }

  /// Update the persistent notification (call every timer tick).
  Future<void> update({
    required String title,
    required String text,
  }) async {
    if (!_isRunning) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
  }

  /// Stop the foreground service entirely.
  Future<void> stop() async {
    if (!_isRunning) return;
    await FlutterForegroundTask.stopService();
    _isRunning = false;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Background isolate entry point – required by flutter_foreground_task.
// The actual timer logic runs on the main isolate via FocusProvider;
// this handler simply keeps the Android service alive.
// ═══════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveHandler());
}

class _KeepAliveHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
