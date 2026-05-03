import Foundation
import SwiftData

@MainActor
final class WeekViewModel: ObservableObject {
    @Published var referenceDate: Date
    @Published private(set) var weekDays: [Date] = []
    @Published private(set) var workoutsByDay: [Date: [PlannedWorkout]] = [:]
    @Published var errorMessage: String?

    private let planner: WorkoutPlannerService
    private let workoutRepository: WorkoutRepository

    init(context: ModelContext, referenceDate: Date = .now) {
        self.referenceDate = referenceDate
        self.planner = WorkoutPlannerService(context: context)
        self.workoutRepository = WorkoutRepository(context: context)
        reload()
    }

    func reload() {
        let start = referenceDate.weekStart
        weekDays = (0..<7).map { start.addingDays($0) }
        workoutsByDay = planner.workoutsForCurrentWeek(referenceDate: referenceDate)
    }

    func templates() -> [WorkoutTemplate] {
        workoutRepository.fetchTemplates()
    }

    func plan(_ template: WorkoutTemplate, on date: Date) {
        do {
            try planner.plan(template: template, on: date)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markSkipped(_ workout: PlannedWorkout) {
        do {
            try planner.markSkipped(workout)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveWeek(by amount: Int) {
        referenceDate = referenceDate.addingDays(amount * 7)
        reload()
    }
}

