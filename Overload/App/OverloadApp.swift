import SwiftData
import SwiftUI

@main
struct OverloadApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            if let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                try FileManager.default.createDirectory(at: applicationSupportURL, withIntermediateDirectories: true)
            }

            let schema = Schema([
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
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
        }
    }
}
