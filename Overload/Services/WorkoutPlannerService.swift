import Foundation
import SwiftData

@MainActor
final class WorkoutPlannerService {
    private let repository: WorkoutRepository

    init(context: ModelContext) {
        self.repository = WorkoutRepository(context: context)
    }

    func workoutsForCurrentWeek(referenceDate: Date = .now) -> [Date: [PlannedWorkout]] {
        let start = referenceDate.weekStart
        let end = start.addingDays(6)
        return Dictionary(grouping: repository.plannedWorkouts(in: start...end)) { $0.plannedDate.startOfDay }
    }

    @discardableResult
    func plan(template: WorkoutTemplate, on date: Date) throws -> PlannedWorkout {
        try repository.plan(template: template, on: date)
    }

    func markSkipped(_ workout: PlannedWorkout) throws {
        try repository.updateStatus(workout, status: .skipped)
    }

    func move(_ workout: PlannedWorkout, to date: Date) throws {
        try repository.move(workout, to: date)
    }
}
