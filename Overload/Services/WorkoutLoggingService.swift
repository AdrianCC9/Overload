import Foundation
import SwiftData

@MainActor
final class WorkoutLoggingService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func session(for plannedWorkout: PlannedWorkout) throws -> WorkoutSession {
        if let linkedSession = plannedWorkout.linkedSession {
            return linkedSession
        }

        let session = WorkoutSession(
            workoutTemplate: plannedWorkout.workoutTemplate,
            date: plannedWorkout.plannedDate
        )
        context.insert(session)
        plannedWorkout.linkedSession = session

        copyTemplateExercises(from: plannedWorkout.workoutTemplate, to: session)
        try context.save()
        return session
    }

    func session(from template: WorkoutTemplate, date: Date = .now) throws -> WorkoutSession {
        let session = WorkoutSession(workoutTemplate: template, date: date.startOfDay)
        context.insert(session)
        copyTemplateExercises(from: template, to: session)
        try context.save()
        return session
    }

    func addSet(to sessionExercise: SessionExercise) throws {
        let nextNumber = (sessionExercise.sessionSets.map(\.setNumber).max() ?? 0) + 1
        let previous = sessionExercise.orderedSets.last
        let set = SessionSet(
            setNumber: nextNumber,
            reps: previous?.reps ?? 8,
            weight: previous?.weight ?? 0,
            rpe: previous?.rpe,
            completed: false
        )
        context.insert(set)
        sessionExercise.sessionSets.append(set)
        try context.save()
    }

    func removeSet(_ set: SessionSet) throws {
        let sessionExercise = set.sessionExercise
        if let sessionExercise {
            sessionExercise.sessionSets.removeAll { $0.id == set.id }
        }
        context.delete(set)
        renumberSets(for: sessionExercise)
        try context.save()
    }

    func finish(_ session: WorkoutSession) throws {
        session.completedAt = .now
        session.plannedWorkout?.status = .completed
        session.plannedWorkout?.linkedSession = session
        try context.save()
    }

    func reopen(_ session: WorkoutSession) throws {
        session.completedAt = nil
        session.plannedWorkout?.status = .planned
        try context.save()
    }

    private func copyTemplateExercises(from template: WorkoutTemplate?, to session: WorkoutSession) {
        guard let template else { return }

        template.orderedExercises.forEach { templateExercise in
            let sessionExercise = SessionExercise(
                exercise: templateExercise.exercise,
                orderIndex: templateExercise.orderIndex,
                notes: templateExercise.notes
            )
            context.insert(sessionExercise)
            session.sessionExercises.append(sessionExercise)
        }
    }

    private func renumberSets(for sessionExercise: SessionExercise?) {
        sessionExercise?.orderedSets.enumerated().forEach { index, set in
            set.setNumber = index + 1
        }
    }
}
