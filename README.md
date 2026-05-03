# Overload

Overload is a native offline-first iOS workout tracking app for experienced gym users. It is built with SwiftUI, SwiftData, and Swift Charts.

## Open The Project

This workspace includes an XcodeGen spec:

```sh
brew install xcodegen
xcodegen generate
open Overload.xcodeproj
```

The app targets iOS 17+ because it uses SwiftData.

## Implemented Scope

- Dark premium SwiftUI shell with Today/Week, Calendar, Builder, Analytics, and Settings tabs.
- SwiftData entities for exercises, templates, planned workouts, logged sessions, sets, and analytics snapshots.
- Seed exercises and sample data mode.
- Template builder with workout names, ordered exercise lists, delete actions, and move up/down exercise reordering.
- Planned workout scheduling, status handling, and logger session creation that copies template exercises into empty editable logging rows.
- Workout logger with duration, bodyweight, notes, warm-up/failure flags, completed-session edit mode, and haptic hooks.
- Session history with open/edit/delete.
- Analytics focused on current-week and average-week sets per muscle group, followed by the most-improved exercise graph and simple supporting stats.
- Multi-file CSV folder export through SwiftUI `fileExporter`.

## UI Previews

Open the local preview page in a browser:

```text
Previews/overload-ui-preview.html
```

The preview page is a static HTML mock that mirrors the SwiftUI design direction. True SwiftUI previews still require Xcode on macOS.

## Notes

See `IMPLEMENTATION_NOTES.md` for the completed scope and the remaining macOS-only validation steps. See `Macbook-instructions.md` for the developer handoff once this is opened on a Mac.
