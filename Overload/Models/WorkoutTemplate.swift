import Foundation
import SwiftData

@Model
final class WorkoutTemplate: Identifiable {
    var id: UUID
    var name: String
    var colorTagRaw: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.workoutTemplate)
    var templateExercises: [TemplateExercise]

    init(
        id: UUID = UUID(),
        name: String,
        colorTag: WorkoutColorTag = .red,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        templateExercises: [TemplateExercise] = []
    ) {
        self.id = id
        self.name = name
        self.colorTagRaw = colorTag.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.templateExercises = templateExercises
    }

    var colorTag: WorkoutColorTag {
        get { WorkoutColorTag(rawValue: colorTagRaw) ?? .red }
        set { colorTagRaw = newValue.rawValue }
    }

    var orderedExercises: [TemplateExercise] {
        templateExercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}
