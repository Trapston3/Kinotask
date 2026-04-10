import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:productivity_app/app.dart';
import 'package:productivity_app/models/task.dart';
import 'package:productivity_app/providers/alarm_coordinator.dart';
import 'package:productivity_app/providers/navigation_provider.dart';
import 'package:productivity_app/providers/task_provider.dart';
import 'package:productivity_app/services/alarm_service.dart';
import 'package:productivity_app/services/haptics_service.dart';
import 'package:productivity_app/services/task_storage_service.dart';

class FakeTaskStorageService implements TaskStorageService {
  @override
  Future<List<Task>> loadTasks() async => const [];

  @override
  Future<void> saveTasks(List<Task> tasks) async {}
}

class FakeAlarmService implements AlarmService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncTasks(Iterable<Task> tasks) async {}
}

class NoOpHapticsService implements HapticsService {
  @override
  Future<void> playDismissThresholdTick() async {}

  @override
  Future<void> playTaskScratchPattern() async {}
}

Widget buildTestApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NavigationProvider>(
        create: (_) => NavigationProvider(),
      ),
      ChangeNotifierProvider<AlarmCoordinator>(
        create: (_) => AlarmCoordinator(),
      ),
      ChangeNotifierProvider<TaskProvider>(
        create: (_) => TaskProvider(
          storageService: FakeTaskStorageService(),
          alarmService: FakeAlarmService(),
          isReadyOverride: true,
        ),
      ),
      Provider<AlarmService>(
        create: (_) => FakeAlarmService(),
      ),
      Provider<HapticsService>(
        create: (_) => NoOpHapticsService(),
      ),
    ],
    child: const ProductivityApp(),
  );
}

void main() {
  testWidgets('renders the One UI shell with all top-level destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Scratchpad'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Secure Vault'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('screen-root-Tasks')), findsOneWidget);
  });

  testWidgets('switches destinations through the bottom navigation bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.text('Scratchpad'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('screen-root-Scratchpad')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('screen-root-Tasks')), findsNothing);
  });

  testWidgets('uses system theme mode with AMOLED dark surfaces and rounded cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final darkTheme = app.darkTheme;

    expect(app.themeMode, ThemeMode.system);
    expect(darkTheme, isNotNull);
    expect(darkTheme!.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(darkTheme.colorScheme.primary, const Color(0xFF007AFF));

    final shape = darkTheme.cardTheme.shape as RoundedRectangleBorder;
    final borderRadius = shape.borderRadius as BorderRadius;
    expect(borderRadius.topLeft.x, greaterThanOrEqualTo(24));
  });
}
