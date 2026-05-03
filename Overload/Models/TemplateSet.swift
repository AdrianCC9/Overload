import Foundation
import SwiftData

@Model
final class TemplateSet {
    var id: UUID
    var templateExercise: TemplateExercise?
    var targetReps: Int
    var targetWeight: Double
    var targetRPE: Double?
    var orderIndex: Int

    init(
        id: UUID = UUID(),
        templateExercise: TemplateExercise? = nil,
        targetReps: Int,
        targetWeight: Double,
        targetRPE: Double? = nil,
        orderIndex: Int
    ) {
        self.id = id
        self.templateExercise = templateExercise
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.targetRPE = targetRPE
        self.orderIndex = orderIndex
    }
}

