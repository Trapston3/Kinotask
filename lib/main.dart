import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'app.dart';
import 'providers/alarm_coordinator.dart';
import 'providers/focus_provider.dart';
import 'providers/health_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/note_provider.dart';
import 'providers/standalone_alarm_provider.dart';
import 'providers/task_provider.dart';
import 'providers/vault_provider.dart';
import 'services/alarm_service.dart';
import 'services/foreground_service.dart';
import 'services/haptics_service.dart';
import 'services/notification_service.dart';
import 'services/task_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await Hive.initFlutter();

  final navigationProvider = NavigationProvider();
  final alarmCoordinator = AlarmCoordinator();
  final notificationService = LocalNotificationService(
    alarmCoordinator: alarmCoordinator,
  );
  final alarmService = AndroidAlarmService(
    notificationService: notificationService,
  );
  final taskProvider = TaskProvider(
    storageService: HiveTaskStorageService(),
    alarmService: alarmService,
  );
  final standaloneAlarmProvider = StandaloneAlarmProvider(
    notificationService: notificationService,
  );
  final noteProvider = NoteProvider();
  final healthProvider = HealthProvider(notificationService: notificationService);
  final vaultProvider = VaultProvider();

  // ── Foreground service (Now Bar) ──────────────────────────────────
  final foregroundService = FocusTimerForegroundService();
  foregroundService.initialize();
  final focusProvider = FocusProvider(foregroundService: foregroundService);

  await notificationService.initialize();
  await alarmService.initialize();
  await taskProvider.initialize();
  await standaloneAlarmProvider.initialize();
  await noteProvider.initialize();
  await healthProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NavigationProvider>.value(
          value: navigationProvider,
        ),
        ChangeNotifierProvider<AlarmCoordinator>.value(
          value: alarmCoordinator,
        ),
        ChangeNotifierProvider<TaskProvider>.value(
          value: taskProvider,
        ),
        ChangeNotifierProvider<FocusProvider>.value(
          value: focusProvider,
        ),
        ChangeNotifierProvider<StandaloneAlarmProvider>.value(
          value: standaloneAlarmProvider,
        ),
        ChangeNotifierProvider<NoteProvider>.value(
          value: noteProvider,
        ),
        ChangeNotifierProvider<HealthProvider>.value(
          value: healthProvider,
        ),
        ChangeNotifierProvider<VaultProvider>.value(
          value: vaultProvider,
        ),
        Provider<HapticsService>(
          create: (_) => DeviceHapticsService(),
        ),
        Provider<NotificationService>.value(
          value: notificationService,
        ),
        Provider<AlarmService>.value(
          value: alarmService,
        ),
      ],
      child: const ProductivityApp(),
    ),
  );
}
