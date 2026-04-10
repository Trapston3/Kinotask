# Phase 2 Revision and Phase 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Revise task completion with scratch-and-haptic feedback, add persistent task storage and creation UI, and implement Android-only multi-tier alarm scheduling with a blocking dual-mode captcha route for high-priority alarms.

**Architecture:** Keep the app provider-driven, add Hive-backed persistence directly in task state management, and isolate Android scheduling/presentation behavior in dedicated services. Use full-screen intent notifications to bring the app into a blocking captcha route for high-priority alarms instead of building a true system overlay.

**Tech Stack:** Flutter, provider, hive/hive_flutter, vibration, flutter_local_notifications, android_alarm_manager_plus, Android manifest and Gradle configuration

---

### Task 1: Add dependencies and failing tests

**Files:**
- Modify: `pubspec.yaml`
- Create: `test/alarm_models_test.dart`
- Create: `test/alarm_services_test.dart`
- Modify: `test/task_provider_test.dart`
- Modify: `test/tasks_screen_test.dart`

- [ ] Add Phase 3 dependencies and test helpers.
- [ ] Write failing tests for task persistence shape, task creation with alarm time, scratch completion state, and captcha challenge validation.
- [ ] Run focused `flutter test` commands and verify failures are caused by missing Phase 2 revision / Phase 3 behavior.

### Task 2: Expand models and persistence

**Files:**
- Modify: `lib/models/task.dart`
- Create: `lib/models/alarm_challenge.dart`
- Modify: `lib/providers/task_provider.dart`
- Create: `lib/services/task_storage_service.dart`
- Modify: `lib/main.dart`

- [ ] Add durable task fields and serialization.
- [ ] Add Hive initialization and storage service.
- [ ] Make `TaskProvider` asynchronous, persistence-aware, and alarm-aware.
- [ ] Re-run provider/model tests.

### Task 3: Revise Tasks UI and scratch interaction

**Files:**
- Modify: `lib/screens/tasks_screen.dart`
- Modify: `lib/widgets/task_card.dart`
- Create: `lib/widgets/task_creation_sheet.dart`
- Create: `lib/widgets/pencil_scratch_text.dart`
- Modify: `lib/services/haptics_service.dart`

- [ ] Replace strikethrough-based completion with scratch painter state.
- [ ] Make the full task card tappable.
- [ ] Add FAB and One UI bottom sheet with title, priority, and time picker.
- [ ] Match completion haptics to scratch duration.
- [ ] Re-run task screen and haptics tests.

### Task 4: Add alarm and notification services

**Files:**
- Create: `lib/services/notification_service.dart`
- Create: `lib/services/alarm_service.dart`
- Modify: `lib/app.dart`
- Modify: `lib/main.dart`
- Create: `lib/screens/alarm_captcha_screen.dart`
- Create: `lib/widgets/alarm_challenge_card.dart`

- [ ] Initialize alarm and notification services.
- [ ] Implement priority-based scheduling and notification display.
- [ ] Add the blocking captcha route with random math/text challenge selection.
- [ ] Add a navigation path for full-screen alarm launches.

### Task 5: Update Android configuration

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/build.gradle.kts`
- Modify: `android/settings.gradle.kts`
- Modify: `android/app/src/main/kotlin/com/example/productivity_app/MainActivity.kt`
- Create if needed: notification resources under `android/app/src/main/res`

- [ ] Add required permissions, receivers, services, and activity flags.
- [ ] Add desugaring and toolchain updates required by the chosen plugins.
- [ ] Ensure the app can request or use exact alarm and full-screen intent support on Android.

### Task 6: Final verification

**Files:**
- Verify: `lib/...`
- Verify: `android/...`
- Verify: `test/...`

- [ ] Run `flutter test`.
- [ ] Run `flutter analyze`.
- [ ] Confirm delivered scope covers persistence, scratch interaction, Add Task FAB/sheet, and multi-tier Android alarm architecture.
