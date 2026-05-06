import Foundation
import SwiftData

@Model
final class SessionSet: Identifiable {
    var id: UUID
    var sessionExercise: SessionExercise?
    var setNumber: Int
    var reps: Int
    var weight: Double
    var rpe: Double?
    var isWarmup: Bool
    var isFailure: Bool
    var completed: Bool

    init(
        id: UUID = UUID(),
        sessionExercise: SessionExercise? = nil,
        setNumber: Int,
        reps: Int,
        weight: Double,
        rpe: Double? = nil,
        isWarmup: Bool = false,
        isFailure: Bool = false,
        completed: Bool = false
    ) {
        self.id = id
        self.sessionExercise = sessionExercise
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.isFailure = isFailure
        self.completed = completed
    }

    var volume: Double {
        completed && !isWarmup ? weight * Double(reps) : 0
    }

    var estimatedOneRepMax: Double {
        guard completed, reps > 0, weight > 0 else { return 0 }
        return AnalyticsMath.estimatedOneRepMax(weight: weight, reps: reps)
    }
}
