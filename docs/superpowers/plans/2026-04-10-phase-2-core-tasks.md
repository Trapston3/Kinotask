# Phase 2 Core Tasks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a provider-backed task list with priority metadata, animated completion states, swipe-to-delete, and vibration-based haptic feedback inside the existing One UI shell.

**Architecture:** Keep task state in a focused `TaskProvider`, move device vibration calls behind a dedicated haptics service, and render a dedicated task card widget inside `TasksScreen`. The task screen stays visually consistent with the existing large sliver header and bottom-heavy navigation while making task interactions easy to reach.

**Tech Stack:** Flutter, provider, vibration, widget tests, unit tests

---

### Task 1: Add failing provider and widget tests

**Files:**
- Create: `test/task_provider_test.dart`
- Modify: `test/widget_test.dart`

- [ ] Write a failing provider test for seeded tasks, completion toggling, and deletion.
- [ ] Write failing widget tests for task rendering, animated completion state, and swipe-to-delete behavior.
- [ ] Run `flutter test test/task_provider_test.dart test/widget_test.dart` and verify failures are for missing task/domain behavior.

### Task 2: Build the task domain and provider

**Files:**
- Create: `lib/models/task.dart`
- Create: `lib/providers/task_provider.dart`
- Modify: `lib/main.dart`

- [ ] Add a `TaskPriority` enum plus an immutable `Task` model with `copyWith`.
- [ ] Add a `TaskProvider` with seeded sample tasks and `addTask`, `toggleTaskCompletion`, and `deleteTask`.
- [ ] Register `TaskProvider` inside the root `MultiProvider`.
- [ ] Re-run `flutter test test/task_provider_test.dart` and verify the provider tests pass.

### Task 3: Add haptics abstraction and task card UI

**Files:**
- Create: `lib/services/haptics_service.dart`
- Create: `lib/widgets/task_card.dart`
- Modify: `lib/screens/tasks_screen.dart`

- [ ] Add a haptics service that uses `vibration` for completion feedback and dismiss-threshold ticks, while remaining injectable for tests.
- [ ] Replace the placeholder task content with a One UI-style task list and bottom-friendly spacing.
- [ ] Implement task cards with a subtle priority indicator, `AnimatedDefaultTextStyle`, `AnimatedOpacity`, and `Dismissible` threshold feedback.
- [ ] Run `flutter test test/widget_test.dart` and verify the task UI behavior now passes.

### Task 4: Final verification

**Files:**
- Verify: `lib/models/task.dart`
- Verify: `lib/providers/task_provider.dart`
- Verify: `lib/services/haptics_service.dart`
- Verify: `lib/screens/tasks_screen.dart`
- Verify: `lib/widgets/task_card.dart`
- Verify: `test/task_provider_test.dart`
- Verify: `test/widget_test.dart`

- [ ] Run `flutter test`.
- [ ] Run `flutter analyze`.
- [ ] Confirm the delivered behavior matches the approved Phase 2 scope: task list, priorities, completion animation, swipe deletion, and haptic hooks.
