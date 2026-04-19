import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/notification_service.dart';

class HealthProvider extends ChangeNotifier {
  // ── Live data ──────────────────────────────────────────────────
  int _steps = 0;
  double _sleepMinutes = 0;
  int _waterGlasses = 0;
  bool _hasPermission = false;
  bool _isLoading = false;
  String? _error;
  
  StreamSubscription<StepCount>? _stepSubscription;
  bool _usingPedometerFallback = false;

  // ── Goals ──────────────────────────────────────────────────────
  int stepsGoal = 10000;
  double sleepGoalMinutes = 480; // 8 hours
  int waterGoal = 10;
  
  late Box _box;

  // ── Fallback (pleasing dummy data for denied permissions) ──────
  static const int _fallbackSteps = 6420;
  static const double _fallbackSleepMin = 443; // 7h 23m
  static const int _fallbackWater = 5;

  final NotificationService? notificationService;
  bool _goalReachedNotified = false;

  HealthProvider({this.notificationService});

  // ── Getters ────────────────────────────────────────────────────
  int get steps => _hasPermission ? _steps : _fallbackSteps;
  double get sleepMinutes => _hasPermission ? _sleepMinutes : _fallbackSleepMin;
  int get waterGlasses => _hasPermission ? _waterGlasses : _fallbackWater;
  bool get hasPermission => _hasPermission;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get stepsProgress => (steps / stepsGoal).clamp(0.0, 1.0);

  String get stepsDisplay {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }

  double get sleepProgress =>
      (sleepMinutes / sleepGoalMinutes).clamp(0.0, 1.0);

  String get sleepDisplay {
    final h = (sleepMinutes ~/ 60);
    final m = (sleepMinutes % 60).round();
    return '${h}h ${m}m';
  }

  double get waterProgress =>
      (waterGlasses / waterGoal).clamp(0.0, 1.0);

  String get waterDisplay => '$waterGlasses / $waterGoal';

  String get stepsDetail =>
      _hasPermission ? 'Goal: $stepsGoal steps' : 'Connect Health for live data';

  String get sleepDetail =>
      _hasPermission ? 'Goal: 8h sleep' : 'Connect Health for live data';

  String get waterDetail =>
      _hasPermission ? 'Goal: $waterGoal glasses' : 'Connect Health for live data';

  // ── Initialization ─────────────────────────────────────────────
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _box = await Hive.openBox('health_data');
    waterGoal = _box.get('waterGoal', defaultValue: 10);
    sleepGoalMinutes = _box.get('sleepGoalMinutes', defaultValue: 480.0);
    stepsGoal = _box.get('stepsGoal', defaultValue: 10000);

    try {
      Health().configure();

      final types = <HealthDataType>[
        HealthDataType.STEPS,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.WATER,
      ];
      final permissions =
          types.map((_) => HealthDataAccess.READ).toList();

      _hasPermission = await Health().requestAuthorization(
        types,
        permissions: permissions,
      );

      if (_hasPermission) {
        await fetchData();
        Timer.periodic(const Duration(seconds: 30), (_) => fetchData());
      } else {
        await _initPedometerFallback();
      }
    } catch (e) {
      _error = e.toString();
      _hasPermission = false;
      await _initPedometerFallback();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      // ── Steps ──────────────────────────────────────────────────
      final totalSteps =
          await Health().getTotalStepsInInterval(midnight, now);
      _steps = totalSteps ?? 0;

      // ── Sleep ──────────────────────────────────────────────────
      // Fallback: Check if manual sleep was logged in Hive today
      final manualSleep = _box.get('manual_sleep_${now.year}_${now.month}_${now.day}');
      if (manualSleep != null) {
        _sleepMinutes = manualSleep as double;
      } else {
        final yesterday = midnight.subtract(const Duration(hours: 12));
        final sleepData = await Health().getHealthDataFromTypes(
          startTime: yesterday,
          endTime: now,
          types: [HealthDataType.SLEEP_ASLEEP],
        );
        _sleepMinutes = 0;
        for (final dp in sleepData) {
          _sleepMinutes +=
              dp.dateTo.difference(dp.dateFrom).inMinutes.toDouble();
        }
      }

      // ── Water ──────────────────────────────────────────────────
      final waterData = await Health().getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.WATER],
      );
      // Wait, we also allow manual logging of water which increments _waterGlasses without Health.
      // Actually we have `logWater()` doing Health().writeHealthData. So it's synced.
      _waterGlasses = waterData.length;
      final localWater = _box.get('manual_water_${now.year}_${now.month}_${now.day}', defaultValue: 0);
      if (localWater > _waterGlasses) {
        _waterGlasses = localWater;
      }
    } catch (e) {
      _error = e.toString();
      if (!_usingPedometerFallback) {
        await _initPedometerFallback();
      }
    }

    if (_steps == 0 && !_usingPedometerFallback && _hasPermission) {
       await _initPedometerFallback();
    }

    _checkGoals();
    _saveHistory();

    notifyListeners();
  }

  void _checkGoals() {
    if (_steps >= stepsGoal && !_goalReachedNotified) {
      _goalReachedNotified = true;
      if (notificationService != null) {
        notificationService!.showStandardNotification(
          title: 'Goal Achieved!',
          body: 'Amazing! You hit your step goal of $stepsGoal today.',
        );
      }
    }
  }

  void _saveHistory() {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Store daily progress completion
    final completeness = (stepsProgress + sleepProgress + waterProgress) / 3.0;
    _box.put('history_$dateStr', completeness);
  }

  Future<void> _initPedometerFallback() async {
    if (_usingPedometerFallback) return;
    
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _usingPedometerFallback = true;
      _hasPermission = true; // Force local UI to not use mock data
      _stepSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          _steps = event.steps;
          _checkGoals();
          _saveHistory();
          notifyListeners();
        },
        onError: (e) {
          _error = 'Pedometer error: $e';
        },
      );
    }
  }

  /// Log a glass of water manually.
  Future<void> logWater() async {
    _waterGlasses++;
    notifyListeners();
    _saveHistory();

    final now = DateTime.now();
    _box.put('manual_water_${now.year}_${now.month}_${now.day}', _waterGlasses);

    if (_hasPermission) {
      try {
        final now = DateTime.now();
        await Health().writeHealthData(
          value: 250, // 250ml = 1 glass
          type: HealthDataType.WATER,
          startTime: now,
          endTime: now,
        );
      } catch (_) {
        // Silent failure — local count still incremented.
      }
    }
  }

  // ── Manual Overrides / Settings ───────────────────────────────────────
  
  void setWaterGoal(int goal) {
    waterGoal = goal;
    _box.put('waterGoal', goal);
    notifyListeners();
  }

  void setSleepGoal(double val) {
    sleepGoalMinutes = val;
    _box.put('sleepGoalMinutes', val);
    notifyListeners();
  }

  void logSleep(double durationMinutes) {
    _sleepMinutes = durationMinutes;
    final now = DateTime.now();
    _box.put('manual_sleep_${now.year}_${now.month}_${now.day}', durationMinutes);
    _saveHistory();
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    super.dispose();
  }
}
