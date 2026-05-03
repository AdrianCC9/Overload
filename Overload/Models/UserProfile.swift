import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var preferredUnitRaw: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "Athlete",
        preferredUnit: MeasurementUnit = .pounds,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.preferredUnitRaw = preferredUnit.rawValue
        self.createdAt = createdAt
    }

    var preferredUnit: MeasurementUnit {
        get { MeasurementUnit(rawValue: preferredUnitRaw) ?? .pounds }
        set { preferredUnitRaw = newValue.rawValue }
    }
}

