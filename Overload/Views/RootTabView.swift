import SwiftData
import SwiftUI

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(OverloadTheme.accentPreferenceKey) private var accentRawValue = AppAccentColor.red.rawValue

    private var accentColor: Color {
        AppAccentColor(rawValue: accentRawValue)?.color ?? AppAccentColor.red.color
    }

    var body: some View {
        TabView {
            WeekView()
                .tabItem {
                    Label("Today", systemImage: "calendar.day.timeline.left")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.xyaxis.line")
                }

            WorkoutBuilderView()
                .tabItem {
                    Label("Builder", systemImage: "dumbbell")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(accentColor)
        .task {
            SeedDataService.seedIfNeeded(context: modelContext)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [
            UserProfile.self,
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            TemplateSet.self,
            PlannedWorkout.self,
            WorkoutSession.self,
            SessionExercise.self,
            SessionSet.self,
            AnalyticsSnapshot.self
        ], inMemory: true)
}
