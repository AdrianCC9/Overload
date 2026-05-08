import Foundation
import SwiftData

@MainActor
final class WorkoutLoggerViewModel: ObservableObject {
    @Published private(set) var session: WorkoutSession?
    @Published var errorMessage: String?

    private let context: ModelContext
    private let loggingService: WorkoutLoggingService
    private let plannedWorkout: PlannedWorkout?
    private let focusedExerciseID: UUID?

    init(
        context: ModelContext,
        plannedWorkout: PlannedWorkout? = nil,
        session: WorkoutSession? = nil,
        focusedExerciseID: UUID? = nil
    ) {
        self.context = context
        self.loggingService = WorkoutLoggingService(context: context)
        self.plannedWorkout = plannedWorkout
        self.session = session
        self.focusedExerciseID = focusedExerciseID
    }

    var isFocusedExerciseMode: Bool {
        focusedExerciseID != nil
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

    func visibleExercises(in session: WorkoutSession) -> [SessionExercise] {
        guard let focusedExerciseID else { return session.orderedExercises }
        return session.orderedExercises.filter { $0.exercise?.id == focusedExerciseID }
    }

    func completeVisibleSetsAndSave() {
        guard let session else {
            save()
            return
        }

        completeSets(in: visibleExercises(in: session))
        save()
        objectWillChange.send()
    }

    func addSet(to exercise: SessionExercise) {
        do {
            try loggingService.addSet(to: exercise)
            objectWillChange.send()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func addExercise(named name: String) -> SessionExercise? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let session, !trimmedName.isEmpty else { return nil }

        do {
            let sessionExercise = try loggingService.addExercise(named: trimmedName, to: session)
            objectWillChange.send()
            return sessionExercise
        } catch {
            errorMessage = error.localizedDescription
            return nil
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
            completeSets(in: session.orderedExercises)
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

    private func completeSets(in exercises: [SessionExercise]) {
        for exercise in exercises {
            for set in exercise.orderedSets where set.reps > 0 {
                set.completed = true
            }
        }
    }
}
