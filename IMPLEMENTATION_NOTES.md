# Overload Implementation Notes

## Completed Without macOS

- Native SwiftUI source structure for a five-tab iOS app.
- SwiftData model layer for exercises, templates, plans, sessions, sets, and analytics snapshots.
- Repository layer for exercise, template, planned workout, session, analytics, and export persistence operations.
- Service layer for planning, logging, analytics, plateau detection, CSV export, seed exercises, and sample data.
- View models for week, calendar, builder, logger, analytics, export, and session history screens.
- Premium dark UI components and app screens matching the requested black/dark gray/red visual direction.
- Template/session separation so logged actuals never mutate target templates unless explicitly edited.
- Template exercise reordering with move up/down actions.
- Builder intentionally stores only workout name plus ordered exercises. It does not collect template sets, reps, weight, RPE, or target values.
- Planned workout creation, moving, status, and session linking.
- Planned workout detail keeps the body to exercise order only, with a top-right log icon for starting the session.
- Workout logging starts from template exercises with no prefilled template sets, then captures actual weight/reps/RPE, notes, bodyweight, duration, warm-up/failure flags, completion, and completed-session edit mode.
- Analytics focused first on current-week and average-week sets per muscle group, followed by most-improved exercise progression and simple supporting stats.
- Session history with open/edit/delete.
- Multi-file CSV folder export with ISO dates, blank optional fields, and fixed decimal formatting.
- Unit test coverage for core analytics math and plateau behavior.
- Browser-viewable preview mockups in `Previews/overload-ui-preview.html`.

## Requires macOS/Xcode

- Generate/open the Xcode project and let Xcode resolve Apple framework availability.
- Compile against iOS 17 SDK.
- Run SwiftData migration/build diagnostics.
- Run simulator UI tests.
- Capture true SwiftUI screenshots from the iOS simulator.
- Add final app icon image assets through Xcode asset tooling.

## Recommended Mac Validation

```sh
brew install xcodegen
xcodegen generate
xcodebuild -scheme Overload -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```
