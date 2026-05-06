import Foundation
import SwiftData

@MainActor
final class SessionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchSessions() -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchCompletedSessions() -> [WorkoutSession] {
        fetchSessions().filter(\.isCompleted)
    }

    func fetchLoggedSessions() -> [WorkoutSession] {
        fetchSessions().filter { session in
            session.isCompleted || session.sessionExercises.contains { !$0.workingSets.isEmpty }
        }
    }

    func deleteSession(_ session: WorkoutSession) throws {
        session.plannedWorkout?.linkedSession = nil
        session.plannedWorkout?.status = .planned
        context.delete(session)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
