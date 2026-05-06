import Foundation
import SwiftUI

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case legs = "Legs"
    case arms = "Arms"
    case core = "Core"
    case traps = "Traps"
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

    var label: String {
        switch self {
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .cyan: return "Cyan"
        case .blue: return "Blue"
        case .violet: return "Violet"
        case .gray: return "Gray"
        }
    }

    var color: Color {
        switch self {
        case .red: return Color(red: 0.94, green: 0.18, blue: 0.20)
        case .orange: return Color(red: 1.0, green: 0.55, blue: 0.22)
        case .yellow: return Color(red: 0.95, green: 0.78, blue: 0.25)
        case .green: return Color(red: 0.18, green: 0.72, blue: 0.42)
        case .cyan: return Color(red: 0.22, green: 0.72, blue: 0.86)
        case .blue: return Color(red: 0.32, green: 0.67, blue: 0.88)
        case .violet: return Color(red: 0.58, green: 0.43, blue: 0.92)
        case .gray: return Color(red: 0.55, green: 0.57, blue: 0.64)
        }
    }
}
