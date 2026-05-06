import Foundation
import SwiftData

@Model
final class Exercise: Identifiable {
    var id: UUID
    var name: String
    var categoryRaw: String
    var defaultUnitRaw: String
    var isCustom: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        defaultUnit: MeasurementUnit = .pounds,
        isCustom: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.defaultUnitRaw = defaultUnit.rawValue
        self.isCustom = isCustom
        self.createdAt = createdAt
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var defaultUnit: MeasurementUnit {
        get { MeasurementUnit(rawValue: defaultUnitRaw) ?? .pounds }
        set { defaultUnitRaw = newValue.rawValue }
    }
}
