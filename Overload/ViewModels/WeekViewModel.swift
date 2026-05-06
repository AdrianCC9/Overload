import Foundation
import SwiftData

@MainActor
final class WeekViewModel: ObservableObject {
    @Published var referenceDate: Date
    @Published var selectedDate: Date
    @Published private(set) var displayDays: [Date] = []
    @Published private(set) var workoutsByDay: [Date: [PlannedWorkout]] = [:]
    @Published var errorMessage: String?

    private let dayRangeRadius = 45
    private let planner: WorkoutPlannerService
    private let workoutRepository: WorkoutRepository

    init(context: ModelContext, referenceDate: Date = .now) {
        self.referenceDate = referenceDate
        self.selectedDate = referenceDate.startOfDay
        self.planner = WorkoutPlannerService(context: context)
        self.workoutRepository = WorkoutRepository(context: context)
        reload()
    }

    var selectedWorkouts: [PlannedWorkout] {
        workoutsByDay[selectedDate.startOfDay] ?? []
    }

    func reload() {
        let start = referenceDate.startOfDay.addingDays(-dayRangeRadius)
        let end = referenceDate.startOfDay.addingDays(dayRangeRadius)
        displayDays = (0...(dayRangeRadius * 2)).map { start.addingDays($0) }
        workoutsByDay = Dictionary(grouping: workoutRepository.plannedWorkouts(in: start...end)) { $0.plannedDate.startOfDay }
        if !displayDays.contains(where: { $0.isSameDay(as: selectedDate) }) {
            selectedDate = referenceDate.startOfDay
        }
    }

    func templates() -> [WorkoutTemplate] {
        workoutRepository.fetchTemplates()
    }

    @discardableResult
    func plan(_ template: WorkoutTemplate, on date: Date) -> PlannedWorkout? {
        do {
            let workout = try planner.plan(template: template, on: date)
            reload()
            return workout
        } catch {
            errorMessage = error.localizedDescription
            return nil
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
        selectedDate = selectedDate.addingDays(amount * 7)
        reload()
    }

    func select(_ day: Date) {
        selectedDate = day.startOfDay
    }
}
