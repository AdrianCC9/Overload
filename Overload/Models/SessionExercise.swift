import Foundation
import SwiftData

@Model
final class SessionExercise {
    var id: UUID
    var session: WorkoutSession?
    var exercise: Exercise?
    var orderIndex: Int
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \SessionSet.sessionExercise)
    var sessionSets: [SessionSet]

    init(
        id: UUID = UUID(),
        session: WorkoutSession? = nil,
        exercise: Exercise? = nil,
        orderIndex: Int,
        notes: String = "",
        sessionSets: [SessionSet] = []
    ) {
        self.id = id
        self.session = session
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.notes = notes
        self.sessionSets = sessionSets
    }

    var orderedSets: [SessionSet] {
        sessionSets.sorted { $0.setNumber < $1.setNumber }
    }

    var workingSets: [SessionSet] {
        sessionSets.filter { $0.completed && !$0.isWarmup }
    }

    var exerciseVolume: Double {
        workingSets.reduce(0) { $0 + $1.volume }
    }

    var bestEstimatedOneRepMax: Double {
        workingSets.map(\.estimatedOneRepMax).max() ?? 0
    }

    var topSetWeight: Double {
        workingSets.map(\.weight).max() ?? 0
    }

    var totalReps: Int {
        workingSets.reduce(0) { $0 + $1.reps }
    }

    var averageWorkingWeight: Double {
        guard !workingSets.isEmpty else { return 0 }
        return workingSets.reduce(0) { $0 + $1.weight } / Double(workingSets.count)
    }
}
