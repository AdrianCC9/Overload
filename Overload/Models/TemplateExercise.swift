import Foundation
import SwiftData

@Model
final class TemplateExercise {
    var id: UUID
    var workoutTemplate: WorkoutTemplate?
    var exercise: Exercise?
    var orderIndex: Int
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \TemplateSet.templateExercise)
    var templateSets: [TemplateSet]

    init(
        id: UUID = UUID(),
        workoutTemplate: WorkoutTemplate? = nil,
        exercise: Exercise? = nil,
        orderIndex: Int,
        notes: String = "",
        templateSets: [TemplateSet] = []
    ) {
        self.id = id
        self.workoutTemplate = workoutTemplate
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.notes = notes
        self.templateSets = templateSets
    }

    var orderedSets: [TemplateSet] {
        templateSets.sorted { $0.orderIndex < $1.orderIndex }
    }
}
