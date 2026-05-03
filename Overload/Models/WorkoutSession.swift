import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var workoutTemplate: WorkoutTemplate?
    var plannedWorkout: PlannedWorkout?
    var date: Date
    var durationMinutes: Int
    var bodyweight: Double?
    var notes: String
    var completedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var sessionExercises: [SessionExercise]

    init(
        id: UUID = UUID(),
        workoutTemplate: WorkoutTemplate? = nil,
        plannedWorkout: PlannedWorkout? = nil,
        date: Date = .now,
        durationMinutes: Int = 0,
        bodyweight: Double? = nil,
        notes: String = "",
        completedAt: Date? = nil,
        sessionExercises: [SessionExercise] = []
    ) {
        self.id = id
        self.workoutTemplate = workoutTemplate
        self.plannedWorkout = plannedWorkout
        self.date = date
        self.durationMinutes = durationMinutes
        self.bodyweight = bodyweight
        self.notes = notes
        self.completedAt = completedAt
        self.sessionExercises = sessionExercises
    }

    var isCompleted: Bool {
        completedAt != nil
    }

    var orderedExercises: [SessionExercise] {
        sessionExercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var totalVolume: Double {
        sessionExercises.reduce(0) { $0 + $1.exerciseVolume }
    }
}
