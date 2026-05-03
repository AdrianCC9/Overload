import SwiftUI

struct DarkCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(OverloadTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous)
                    .stroke(OverloadTheme.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
    }
}

