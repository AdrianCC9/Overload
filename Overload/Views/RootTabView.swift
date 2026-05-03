import SwiftData
import SwiftUI

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext

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

            WorkoutBuilderView()
                .tabItem {
                    Label("Builder", systemImage: "dumbbell")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.xyaxis.line")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(OverloadTheme.accent)
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

