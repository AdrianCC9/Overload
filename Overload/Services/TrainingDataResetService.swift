import Foundation
import SwiftData

@MainActor
final class TrainingDataResetService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func clearTrainingData() throws {
        try deleteAll(AnalyticsSnapshot.self)
        try deleteAll(SessionSet.self)
        try deleteAll(SessionExercise.self)
        try deleteAll(WorkoutSession.self)
        try deleteAll(PlannedWorkout.self)
        try deleteAll(TemplateSet.self)
        try deleteAll(TemplateExercise.self)
        try deleteAll(WorkoutTemplate.self)
        try context.save()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        let items = try context.fetch(FetchDescriptor<T>())
        items.forEach(context.delete)
    }
}
