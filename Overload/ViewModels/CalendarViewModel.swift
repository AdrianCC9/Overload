import Foundation
import SwiftData

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var monthDate: Date
    @Published var selectedDate: Date
    @Published private(set) var monthDays: [Date?] = []
    @Published private(set) var workoutsByDay: [Date: [PlannedWorkout]] = [:]
    @Published private(set) var sessionsByDay: [Date: [WorkoutSession]] = [:]
    @Published var errorMessage: String?

    private let repository: WorkoutRepository
    private let sessionRepository: SessionRepository

    init(context: ModelContext, monthDate: Date = .now) {
        self.monthDate = monthDate.monthStart
        self.selectedDate = Date.now.startOfDay
        self.repository = WorkoutRepository(context: context)
        self.sessionRepository = SessionRepository(context: context)
        reload()
    }

    var selectedWorkouts: [PlannedWorkout] {
        workoutsByDay[selectedDate.startOfDay] ?? []
    }

    var selectedSessions: [WorkoutSession] {
        sessionsByDay[selectedDate.startOfDay] ?? []
    }

    func reload() {
        monthDays = Self.makeMonthGrid(for: monthDate)
        let visibleDates = monthDays.compactMap { $0 }
        guard let first = visibleDates.first, let last = visibleDates.last else {
            workoutsByDay = [:]
            sessionsByDay = [:]
            return
        }
        workoutsByDay = Dictionary(grouping: repository.plannedWorkouts(in: first...last)) { $0.plannedDate.startOfDay }
        sessionsByDay = Dictionary(
            grouping: sessionRepository.fetchCompletedSessions().filter { (first...last).contains($0.date.startOfDay) }
        ) { $0.date.startOfDay }
    }

    func templates() -> [WorkoutTemplate] {
        repository.fetchTemplates()
    }

    func plan(_ template: WorkoutTemplate, on date: Date) {
        do {
            try repository.plan(template: template, on: date)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func move(_ workout: PlannedWorkout, to date: Date) {
        do {
            try repository.move(workout, to: date)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func changeMonth(by amount: Int) {
        monthDate = monthDate.addingMonths(amount).monthStart
        reload()
    }

    static func makeMonthGrid(for date: Date) -> [Date?] {
        let calendar = Calendar.overload
        let start = date.monthStart
        let range = calendar.range(of: .day, in: .month, for: start) ?? 1..<1
        let weekdayOffset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7

        var days = Array(repeating: Optional<Date>.none, count: weekdayOffset)
        days += range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }
}
