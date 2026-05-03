import Foundation
import SwiftData

@MainActor
final class SessionHistoryViewModel: ObservableObject {
    @Published private(set) var sessions: [WorkoutSession] = []
    @Published var errorMessage: String?

    private let repository: SessionRepository

    init(context: ModelContext) {
        self.repository = SessionRepository(context: context)
        reload()
    }

    func reload() {
        sessions = repository.fetchSessions()
    }

    func deleteSession(_ session: WorkoutSession) {
        do {
            try repository.deleteSession(session)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

