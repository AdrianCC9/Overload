import SwiftUI

struct ExerciseRow: View {
    var name: String
    var category: String
    var detail: String?
    var color: Color = OverloadTheme.accent

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OverloadTheme.primaryText)
                Text(detail ?? category)
                    .font(.caption)
                    .foregroundStyle(OverloadTheme.secondaryText)
            }
            Spacer()
            Text(category)
                .font(.caption2.weight(.medium))
                .foregroundStyle(OverloadTheme.mutedText)
        }
    }
}

