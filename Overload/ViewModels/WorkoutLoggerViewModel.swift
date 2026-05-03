import Foundation
import SwiftData

@MainActor
final class WorkoutLoggerViewModel: ObservableObject {
    @Published private(set) var session: WorkoutSession?
    @Published var errorMessage: String?

    private let context: ModelContext
    private let loggingService: WorkoutLoggingService
    private let plannedWorkout: PlannedWorkout?

    init(context: ModelContext, plannedWorkout: PlannedWorkout? = nil, session: WorkoutSession? = nil) {
        self.context = context
        self.loggingService = WorkoutLoggingService(context: context)
        self.plannedWorkout = plannedWorkout
        self.session = session
    }

    func load() {
        guard session == nil, let plannedWorkout else { return }
        do {
            session = try loggingService.session(for: plannedWorkout)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() {
        do {
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addSet(to exercise: SessionExercise) {
        do {
            try loggingService.addSet(to: exercise)
            objectWillChange.send()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeSet(_ set: SessionSet) {
        do {
            try loggingService.removeSet(set)
            objectWillChange.send()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func finish() {
        guard let session else { return }
        do {
            try loggingService.finish(session)
            objectWillChange.send()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reopen() {
        guard let session else { return }
        do {
            try loggingService.reopen(session)
            objectWillChange.send()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

