# Macbook Instructions For Overload

This file is the Mac handoff. Read this first, then open the project. The goal is to get the existing iOS app compiling, validate behavior in Simulator, and finish the macOS-only work quickly.

## Current Product Decisions

- Overload is an offline-first native iOS workout tracker for experienced gym users.
- Stack: SwiftUI, SwiftData, Swift Charts, iOS 17+.
- Theme: black background, dark gray cards, red accent for primary actions only.
- Templates are intentionally simple now: a template is only a workout name plus ordered exercises.
- Do not put planned sets, reps, weight, target RPE, or notes in the Workout Builder UI.
- Do not put custom exercise creation inside the main Builder flow unless a separate product decision adds it elsewhere.
- Tapping a planned workout such as Push should show only the exercises in order.
- Analytics should first show current-week set count and average sets per week for each muscle group.
- The Analytics graph underneath should automatically use the most-improved exercise.
- Supporting analytics stats should stay simple and below the main set-count section and graph.
- Calendar should show:
  - monthly calendar
  - indicators for completed/planned workout days
  - selected-day completed workout history
  - exercise/set/reps/weight history for that selected day
- Calendar should not include extra explanatory notes or become a planner-heavy page.
- Workout logging remains where actual sets/reps/weight/RPE/bodyweight/duration belong.
- Will ONLY be run on a Iphone 16 pro

## First Mac Setup

From the repo root:

```sh
brew install xcodegen
xcodegen generate
open Overload.xcodeproj
```

Then in Xcode:

1. Select the `Overload` scheme.
2. Select an iOS 17+ simulator, ideally iPhone 16 Pro if it is installed.
3. Build once with `Cmd+B`.
4. Run tests with `Cmd+U`.
5. Run the app and load sample data from Settings.

Command-line validation:

```sh
xcodebuild -scheme Overload -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
xcodebuild -scheme Overload -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

If the iPhone 16 Pro simulator is not installed, replace it with an available iOS 17+ simulator from:

```sh
xcrun simctl list devices available
```

## Code Map

- App entry:
  - `Overload/App/OverloadApp.swift`
- SwiftData models:
  - `Overload/Models/*.swift`
- Persistence repositories:
  - `Overload/Repositories/*.swift`
- Business logic:
  - `Overload/Services/AnalyticsService.swift`
  - `Overload/Services/PlateauDetectionService.swift`
  - `Overload/Services/WorkoutLoggingService.swift`
  - `Overload/Services/WorkoutPlannerService.swift`
  - `Overload/Services/CSVExportService.swift`
  - `Overload/Services/SampleDataService.swift`
- Screen state:
  - `Overload/ViewModels/*.swift`
- SwiftUI screens:
  - `Overload/Views/WeekView.swift`
  - `Overload/Views/CalendarView.swift`
  - `Overload/Views/WorkoutBuilderView.swift`
  - `Overload/Views/WorkoutLoggerView.swift`
  - `Overload/Views/AnalyticsView.swift`
  - `Overload/Views/SettingsView.swift`
  - `Overload/Views/SessionHistoryView.swift`
  - `Overload/Views/TemplateExerciseOrderView.swift`
- Shared UI:
  - `Overload/Components/*.swift`
- Tests:
  - `Tests/UnitTests/AnalyticsServiceTests.swift`
- Static browser preview:
  - `Previews/overload-ui-preview.html`
  - `Previews/screens/*.png`

## Fastest Build Fix Plan

Because this was authored on Windows, the first Mac task is compile validation. Do this in order:

1. Generate the project with XcodeGen.
2. Build the app target.
3. Fix any Swift syntax/API issues caused by unavailable Windows-side compilation.
4. Build tests.
5. Run unit tests.
6. Run the app in Simulator.
7. Load sample data from Settings.
8. Visit each tab and validate the acceptance checklist below.

Do not refactor architecture during the first build pass. Keep changes surgical until the app compiles and runs.

## Known Mac-Only Items To Verify

- SwiftData relationships and inverse annotations compile cleanly.
- `@Bindable` usage compiles in nested row components.
- `FileDocument` folder export through `fileExporter` behaves correctly on device/simulator.
- Swift Charts renders correctly in Analytics.
- Haptic calls do not fire in unsupported simulator contexts.
- Asset catalog is sufficient for a local run. Add final app icon assets if Xcode warns.
- `project.yml` includes all sources and resources correctly.

## Acceptance Checklist

### Builder

- Create a template named Push.
- Add Bench Press, Incline Dumbbell Press, Overhead Press, Triceps Pushdown.
- Confirm only exercise order is shown.
- Confirm no template set/reps/weight/RPE fields are visible.
- Confirm creating a workout asks only for the workout name.
- Confirm Builder does not expose a default set/weight/reps/RPE setup.
- Move an exercise up/down.
- Delete an exercise.
- Relaunch app and confirm template persists.

### Week

- Add Push to Monday, Pull to Tuesday, Legs to Wednesday.
- Tap Push.
- Confirm the sheet shows only ordered exercises.
- Confirm no sets, reps, weight, target values, notes, or logging form appear in that sheet.
- Use the top-right log icon from that sheet to start logging the planned workout.

### Calendar

- Load sample data or create completed sessions.
- Tap dates with completed workouts.
- Confirm the selected-date area shows completed workout history.
- Confirm history includes exercises and sets/reps/weight.
- Confirm no planner notes or extra instructional copy clutter the page.

### Logger

- Start a session from the planned workout sheet log icon, or open a completed session from Session History.
- Confirm the logger starts with the template exercises only and no prefilled template sets.
- Add actual sets.
- Edit reps, weight, RPE, duration, bodyweight.
- Mark warm-up and failure.
- Finish workout.
- Reopen/edit completed session.
- Confirm analytics changes after edits.

### Analytics

- Confirm the top section shows each muscle group with:
  - sets completed in the current week
  - average sets per week
  - total sets counted
- Confirm current-week set counts only include completed working sets from the current Monday-Sunday week.
- Confirm average sets per week uses completed working sets across logged training weeks.
- Confirm the graph underneath uses the most-improved exercise automatically.
- Confirm graph values match session data.
- Confirm Epley formula: `estimated1RM = weight * (1 + reps / 30)`.
- Confirm plateau detection follows:
  - at least 4 logs in last 6 weeks
  - estimated 1RM improved by less than 2%, or top set weight did not increase across 4 sessions, or volume decreased 3 sessions in a row

### Export

- Export all data from Settings.
- Confirm exported folder contains:
  - `exercises.csv`
  - `workout_templates.csv`
  - `template_exercises.csv`
  - `template_sets.csv`
  - `planned_workouts.csv`
  - `workout_sessions.csv`
  - `session_exercises.csv`
  - `session_sets.csv`
  - `analytics_snapshots.csv`
- Confirm dates are `YYYY-MM-DD`.
- Confirm empty optional fields are blank, not `null`.
- Confirm decimals are consistent.

## Suggested Next Implementation Tasks

Do these after the first successful build:

1. Add drag-and-drop reordering in Builder using SwiftUI `.onMove` if the current move up/down menu feels too slow.
2. Add UI tests for:
   - template creation
   - calendar history selection
   - workout logging
   - CSV export button flow
3. Add snapshot screenshots from iPhone SE, iPhone 16 Pro, and iPhone 16 Pro Max simulators.
4. Replace placeholder app icon metadata with a real app icon.
5. Consider a schema migration only if changing persisted model properties after real test installs.

## Important Context

- Template data and session data are deliberately separate.
- Template screens should stay lightweight and planning-oriented.
- Logged session screens are where actual performance data lives.
- Calendar is now a history surface, not the primary workout builder.
- The static HTML preview is only for visual direction on non-Mac machines. True UI validation must happen in Xcode previews or Simulator.
