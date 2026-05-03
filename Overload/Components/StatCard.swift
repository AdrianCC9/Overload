import SwiftUI

struct StatCard: View {
    var title: String
    var value: String
    var subtitle: String?
    var systemImage: String
    var tint: Color = OverloadTheme.accent

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(tint)
                    Spacer()
                }
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(OverloadTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(OverloadTheme.secondaryText)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(OverloadTheme.mutedText)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

