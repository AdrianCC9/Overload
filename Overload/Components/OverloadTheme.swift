import SwiftUI

enum AppAccentColor: String, CaseIterable, Identifiable {
    case red
    case blue
    case darkBlue
    case purple
    case green

    var id: String { rawValue }

    var label: String {
        switch self {
        case .red: return "Red"
        case .blue: return "Blue"
        case .darkBlue: return "Dark Blue"
        case .purple: return "Purple"
        case .green: return "Green"
        }
    }

    var color: Color {
        switch self {
        case .red: return Color(red: 0.94, green: 0.12, blue: 0.14)
        case .blue: return Color(red: 0.22, green: 0.58, blue: 0.95)
        case .darkBlue: return Color(red: 0.08, green: 0.22, blue: 0.58)
        case .purple: return Color(red: 0.56, green: 0.32, blue: 0.92)
        case .green: return Color(red: 0.17, green: 0.72, blue: 0.36)
        }
    }
}

enum OverloadTheme {
    static let accentPreferenceKey = "overloadAccentColor"

    static let background = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let surface = Color(red: 0.15, green: 0.16, blue: 0.22)
    static let elevated = Color(red: 0.19, green: 0.20, blue: 0.27)
    static let border = Color.white.opacity(0.10)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.68)
    static let mutedText = Color.white.opacity(0.42)
    static var accent: Color {
        let rawValue = UserDefaults.standard.string(forKey: accentPreferenceKey) ?? AppAccentColor.red.rawValue
        return AppAccentColor(rawValue: rawValue)?.color ?? AppAccentColor.red.color
    }
    static let success = Color(red: 0.17, green: 0.72, blue: 0.36)
    static let warning = Color(red: 1.0, green: 0.67, blue: 0.20)

    static let cornerRadius: CGFloat = 8
}

extension View {
    func overloadScreenBackground() -> some View {
        background(OverloadTheme.background.ignoresSafeArea())
    }
}
