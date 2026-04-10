import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/alarm_coordinator.dart';
import 'providers/navigation_provider.dart';
import 'providers/task_provider.dart';
import 'services/alarm_service.dart';
import 'services/haptics_service.dart';
import 'services/notification_service.dart';
import 'services/task_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  await notificationService.initialize();
  await alarmService.initialize();
  await taskProvider.initialize();

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
