import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/foreground_service.dart';

enum FocusMode { none, timer, stopwatch }

class FocusProvider extends ChangeNotifier {
  FocusProvider({
    required FocusTimerForegroundService foregroundService,
  }) : _fg = foregroundService;

  final FocusTimerForegroundService _fg;

  // ── Timer state ────────────────────────────────────────────────────
  int _timerTotalSeconds = 25 * 60;
  bool _timerRunning = false;
  Timer? _timerTicker;
  FocusMode _activeMode = FocusMode.none;

  final ValueNotifier<int> _timerRemainingNotifier = ValueNotifier(25 * 60);

  int get timerTotal => _timerTotalSeconds;
  int get timerRemaining => _timerRemainingNotifier.value;
  ValueNotifier<int> get timerRemainingNotifier => _timerRemainingNotifier;
  bool get timerRunning => _timerRunning;
  FocusMode get activeMode => _activeMode;

  int _selectedSegment = 0;
  int get selectedSegment => _selectedSegment;

  void setSegment(int index) {
    _selectedSegment = index;
    notifyListeners();
  }

  /// Whether the Pomodoro timer is actively counting down (for accent shift).
  bool get isInDeepWork => _timerRunning;

  double get timerProgress =>
      _timerTotalSeconds > 0 ? _timerRemainingNotifier.value / _timerTotalSeconds : 1;

  String get timerDisplay {
    final m = (_timerRemainingNotifier.value ~/ 60).toString().padLeft(2, '0');
    final s = (_timerRemainingNotifier.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void setTimerDuration(int totalSeconds) {
    if (_timerRunning) return;
    _timerTotalSeconds = totalSeconds;
    _timerRemainingNotifier.value = totalSeconds;
    notifyListeners();
  }

  Future<void> toggleTimer() async {
    if (_timerRunning) {
      _timerTicker?.cancel();
      _timerRunning = false;
      _activeMode = FocusMode.none;
      _fg.update(title: 'Focus Timer — Paused', text: timerDisplay);
      notifyListeners();
    } else {
      await Permission.notification.request();
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_timerRemainingNotifier.value > 0) {
          _timerRemainingNotifier.value--;
          _fg.update(title: 'Focus Timer', text: '$timerDisplay remaining');
          // Important: We do NOT call notifyListeners here to avoid full page rebuilds
        } else {
          _timerTicker?.cancel();
          _timerRunning = false;
          _activeMode = FocusMode.none;
          _fg.stop();
          
          if (_timerTotalSeconds == 25 * 60) {
            setTimerDuration(5 * 60);
            toggleTimer();
          } else {
            notifyListeners();
          }
        }
      });
      _timerRunning = true;
      _activeMode = FocusMode.timer;
      _fg.start(title: 'Focus Timer', text: '$timerDisplay remaining');
      notifyListeners();
    }
  }

  void resetTimer() {
    _timerTicker?.cancel();
    _timerRunning = false;
    _timerRemainingNotifier.value = _timerTotalSeconds;
    _activeMode = FocusMode.none;
    _fg.stop();
    notifyListeners();
  }

  // ── Stopwatch state ────────────────────────────────────────────────
  final Stopwatch _sw = Stopwatch();
  Timer? _swTicker;
  Duration _swElapsed = Duration.zero;
  final List<Duration> _laps = [];

  Duration get stopwatchElapsed => _swElapsed;
  bool get stopwatchRunning => _sw.isRunning;
  List<Duration> get laps => List.unmodifiable(_laps);

  String get stopwatchDisplay => _fmtDuration(_swElapsed);

  void toggleStopwatch() {
    if (_sw.isRunning) {
      _sw.stop();
      _swTicker?.cancel();
      _activeMode = FocusMode.none;
      _fg.update(title: 'Stopwatch — Paused', text: stopwatchDisplay);
    } else {
      _sw.start();
      _swTicker = Timer.periodic(const Duration(milliseconds: 30), (_) {
        _swElapsed = _sw.elapsed;
        // Update the foreground notification once per second.
        if (_swElapsed.inMilliseconds % 1000 < 35) {
          _fg.update(title: 'Stopwatch', text: stopwatchDisplay);
        }
        notifyListeners();
      });
      _activeMode = FocusMode.stopwatch;
      _fg.start(title: 'Stopwatch', text: stopwatchDisplay);
    }
    notifyListeners();
  }

  void lapStopwatch() {
    if (_sw.isRunning) {
      _laps.add(_sw.elapsed);
      notifyListeners();
    }
  }

  void resetStopwatch() {
    _sw
      ..stop()
      ..reset();
    _swTicker?.cancel();
    _swElapsed = Duration.zero;
    _laps.clear();
    _activeMode = FocusMode.none;
    _fg.stop();
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────
  static String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms =
        (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  String fmtLap(Duration d) => _fmtDuration(d);

  @override
  void dispose() {
    _timerTicker?.cancel();
    _swTicker?.cancel();
    _fg.stop();
    super.dispose();
  }
}
