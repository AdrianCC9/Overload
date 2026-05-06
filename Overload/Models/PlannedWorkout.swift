import Foundation
import SwiftData

@Model
final class PlannedWorkout: Identifiable {
    var id: UUID
    var workoutTemplate: WorkoutTemplate?
    var plannedDate: Date
    var statusRaw: String
    @Relationship(inverse: \WorkoutSession.plannedWorkout)
    var linkedSession: WorkoutSession?

    init(
        id: UUID = UUID(),
        workoutTemplate: WorkoutTemplate? = nil,
        plannedDate: Date,
        status: WorkoutStatus = .planned,
        linkedSession: WorkoutSession? = nil
    ) {
        self.id = id
        self.workoutTemplate = workoutTemplate
        self.plannedDate = plannedDate
        self.statusRaw = status.rawValue
        self.linkedSession = linkedSession
    }

    var status: WorkoutStatus {
        get { WorkoutStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }
}
