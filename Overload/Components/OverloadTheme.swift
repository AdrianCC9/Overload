import SwiftUI

enum OverloadTheme {
    static let background = Color.black
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.10)
    static let elevated = Color(red: 0.14, green: 0.14, blue: 0.15)
    static let border = Color.white.opacity(0.08)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.68)
    static let mutedText = Color.white.opacity(0.42)
    static let accent = Color(red: 0.94, green: 0.12, blue: 0.14)
    static let success = Color(red: 0.17, green: 0.72, blue: 0.36)
    static let warning = Color(red: 1.0, green: 0.67, blue: 0.20)

    static let cornerRadius: CGFloat = 8
}

extension View {
    func overloadScreenBackground() -> some View {
        background(OverloadTheme.background.ignoresSafeArea())
    }
}

