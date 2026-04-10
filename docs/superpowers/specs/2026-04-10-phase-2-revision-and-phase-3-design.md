# Phase 2 Revision and Phase 3 Alarm System Design

## Summary

This design revises task completion to feel tactile and expressive, then adds an Android-only alarm architecture for Samsung Galaxy S23 deployment. Tasks must persist locally between sessions, task completion must use a custom pencil scratch animation synchronized to a tapered haptic waveform, and high-priority alarms must escalate to a blocking captcha experience that wakes the device.

## Scope

### Phase 2 Revision

- Replace the current checkbox-only completion target with a full-card completion surface.
- Replace the simple strikethrough with a custom scratch-off animation that visually feels like a pencil crossing text out.
- Synchronize the scratch animation with a continuous haptic waveform that starts strong and tapers to medium intensity over the exact animation duration.
- Keep swipe-to-delete with the threshold haptic tick.
- Add durable local persistence so tasks, priorities, completion states, and alarm times survive app restarts.
- Add a prominent One UI-style FAB to open an Add Task bottom sheet.

### Phase 3

- Android-only alarm implementation using `flutter_local_notifications` and `android_alarm_manager_plus`.
- Alarm behavior must map to task priority:
  - Low: standard notification
  - Medium: scheduled alarm notification with ringing behavior
  - High: full-screen intent alarm that wakes the device and forces a captcha flow
- High-priority alarms must randomly choose one of two blocking captcha modes:
  - math puzzle
  - text-match challenge
- Add alarm time selection to the Add Task bottom sheet.

## Architecture

### Task Domain

`Task` becomes the durable source of truth for:

- `id`
- `title`
- `priority`
- `isCompleted`
- `alarmTime`
- `createdAt`

The provider remains the main state interface but becomes persistence-aware and alarm-aware.

### Persistence

Use Hive for local persistence. Shared preferences is too limited for the richer task payload and scheduled metadata.

`TaskProvider` responsibilities:

- load persisted tasks during initialization
- seed default tasks only on first launch or empty storage
- persist every mutation
- expose readiness state so the UI can avoid flashing stale content
- coordinate with `AlarmService` after writes so alarms stay in sync with saved data

The persistence layer stays simple for now by serializing task records as maps stored in a Hive box, avoiding code generation unless later complexity justifies adapters.

### Scratch Completion Interaction

Each task card remains visually large and rounded, but the whole card becomes tappable.

Completion flow:

1. User taps anywhere on the card surface.
2. The provider marks the task complete.
3. A scratch animation begins over the title text.
4. A matching haptic waveform runs for the same duration.
5. The card fades slightly once completed.

The scratch effect is implemented with a custom painter layered over the task title. The animation reveals multiple angled graphite strokes progressively from left to right with slight jitter so the motion feels handwritten rather than geometric.

The scratch state is visual-only. The text itself no longer uses a strikethrough decoration.

### Haptics

The haptics service stays injectable and testable.

Patterns:

- Dismiss threshold: one sharp tick
- Completion scratch: one continuous custom waveform whose total duration matches the scratch animation exactly

The completion waveform starts at a stronger amplitude and steps down toward medium intensity to mimic friction decaying as the pencil stroke finishes.

### Task Screen UI

`TasksScreen` remains a large-title sliver layout with bottom-friendly spacing.

Additions:

- One UI-style FAB for adding tasks
- bottom sheet for task creation
- title field
- priority selector
- Android time picker for optional alarms

The FAB should remain reachable above the bottom navigation area and visually match the bold One UI aesthetic.

### Alarm Architecture

#### NotificationService

Responsibilities:

- initialize local notifications
- define notification channels for low, medium, and high alarms
- request notification and full-screen-intent related permissions where supported by plugin APIs
- show low-priority standard notifications
- show medium-priority ringing notifications
- show high-priority full-screen intent notifications

#### AlarmService

Responsibilities:

- initialize `android_alarm_manager_plus`
- request and validate exact alarm capability for Android 14+
- generate stable integer alarm IDs from task IDs
- schedule alarms by priority
- cancel alarms when tasks change or are deleted
- reschedule persisted alarms during startup
- bridge fired alarms back into notification display and app navigation

### High-Priority Alarm UX

High-priority alarms launch a full-screen intent notification that opens the app into a dedicated blocking route.

The alarm route must:

- wake into the foreground when invoked by the full-screen intent path
- display a One UI-styled full-screen alarm surface
- choose captcha mode randomly
- block dismissal until the current challenge is solved
- stop alarm playback/notification only after success

Captcha modes:

- Math puzzle: randomized arithmetic with a single correct numeric answer
- Text match: randomized token string that must be typed exactly

Both modes need deterministic validation and a visible error state for wrong answers.

### Android Platform Requirements

Manifest and activity changes:

- `RECEIVE_BOOT_COMPLETED`
- `WAKE_LOCK`
- `SCHEDULE_EXACT_ALARM`
- `USE_FULL_SCREEN_INTENT`
- optional inclusion of `SYSTEM_ALERT_WINDOW` only if later native overlay work becomes necessary
- activity flags for `showWhenLocked` and `turnScreenOn`
- receivers/services required by `flutter_local_notifications`
- receivers/services required by `android_alarm_manager_plus`

Build changes:

- add desugaring support required by `flutter_local_notifications`
- bump AGP from `8.11.1` to at least `8.12.1` to satisfy `android_alarm_manager_plus` guidance

## Data Flow

### Task Mutation

1. User adds or edits a task in the bottom sheet.
2. `TaskProvider` updates in-memory state.
3. Provider persists the full task list to Hive.
4. Provider asks `AlarmService` to schedule, update, or cancel alarms as needed.
5. UI rebuilds from provider state.

### Alarm Firing

1. AlarmManager callback fires in background.
2. `AlarmService` reconstructs task context from passed parameters and/or persisted storage.
3. `NotificationService` displays the correct notification style.
4. If the alarm is high priority, tapping or full-screen launch opens the captcha alarm route.
5. Solving the captcha dismisses the active alarm UI and stops the high-priority alarm presentation.

## Testing Strategy

### Phase 2

- provider tests for persistence-aware task mutations
- haptics tests for scratch waveform shape and dismiss tick
- widget tests for full-card tap completion, scratch animation state, Add Task FAB, and task creation flow

### Phase 3

- unit tests for captcha mode generation and validation
- service tests for alarm-to-priority mapping where possible with fake services
- widget tests for the full-screen captcha route behavior

Android-specific alarm firing and device wake behavior cannot be fully proven in widget tests and will need emulator or device validation on the Galaxy S23.

## Risks and Constraints

- Samsung devices apply aggressive background management, so exact alarm behavior depends on user/device settings in addition to code.
- Full-screen intent is the cleanest supported v1 path. A true overlay window would increase permission and policy complexity and is not required for the requested behavior.
- Alarm callback isolates do not share memory with the main isolate, so alarm payloads must be serializable and reconstructable from storage.

## Approved Decisions

- Android-only Phase 3
- Hive for task persistence
- Full-card completion gesture
- Custom pencil scratch animation instead of text strikethrough
- Dual-mode captcha for high-priority alarms
- One UI FAB and task creation bottom sheet with time picker
