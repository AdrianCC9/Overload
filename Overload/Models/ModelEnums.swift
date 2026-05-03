import Foundation
import SwiftUI

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case other = "Other"

    var id: String { rawValue }
}

enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case pounds = "lbs"
    case kilograms = "kg"

    var id: String { rawValue }
}

enum WorkoutStatus: String, Codable, CaseIterable, Identifiable {
    case planned
    case completed
    case skipped

    var id: String { rawValue }

    var label: String {
        switch self {
        case .planned: return "Planned"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        }
    }
}

enum AnalyticsMetric: String, Codable, CaseIterable, Identifiable {
    case estimatedOneRepMax = "Estimated 1RM"
    case topSetWeight = "Top Set"
    case volume = "Volume"
    case reps = "Reps"
    case averageWorkingWeight = "Avg Weight"

    var id: String { rawValue }
}

enum WorkoutColorTag: String, Codable, CaseIterable, Identifiable {
    case red
    case orange
    case yellow
    case green
    case cyan
    case blue
    case violet
    case gray

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .cyan: return .cyan
        case .blue: return .blue
        case .violet: return .purple
        case .gray: return .gray
        }
    }
}

