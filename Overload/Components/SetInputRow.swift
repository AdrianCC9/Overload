import SwiftData
import SwiftUI

struct SetInputRow: View {
    @Bindable var set: SessionSet
    var isReadOnly: Bool
    var onDelete: () -> Void
    var onSave: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("\(set.setNumber)")
                .font(.headline.weight(.heavy))
                .foregroundStyle(OverloadTheme.primaryText)
                .frame(width: 48, height: 54)
                .background(OverloadTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous)
                        .stroke(OverloadTheme.accent.opacity(0.55), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))

            TextField("Reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .disabled(isReadOnly)
                .textFieldStyle(.plain)
                .onSubmit(completeAndSave)
                .font(.headline.weight(.heavy))
                .foregroundStyle(OverloadTheme.accent)
                .padding(.horizontal, 14)
                .frame(width: 78, height: 54)
                .background(OverloadTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous)
                        .stroke(OverloadTheme.accent.opacity(0.55), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))

            TextField("Weight", value: $set.weight, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .disabled(isReadOnly)
                .textFieldStyle(.plain)
                .onSubmit(completeAndSave)
                .font(.headline.weight(.heavy))
                .foregroundStyle(OverloadTheme.accent)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(OverloadTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous)
                        .stroke(OverloadTheme.accent.opacity(0.55), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                .overlay(alignment: .trailing) {
                    Text("lbs")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(OverloadTheme.mutedText)
                        .padding(.trailing, 12)
                }

            Menu {
                Button("Delete Set", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(OverloadTheme.mutedText)
                    .frame(width: 28, height: 54)
            }
            .disabled(isReadOnly)
        }
        .foregroundStyle(OverloadTheme.primaryText)
        .onChange(of: set.reps) { _, _ in
            completeAndSave()
        }
        .onChange(of: set.weight) { _, _ in
            completeAndSave()
        }
    }

    private func completeAndSave() {
        set.completed = set.reps > 0
        onSave()
    }
}
