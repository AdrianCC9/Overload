import SwiftData
import SwiftUI

struct SetInputRow: View {
    @Bindable var set: SessionSet
    var isReadOnly: Bool
    var onDelete: () -> Void
    var onSave: () -> Void

    var body: some View {
        GridRow {
            Text("\(set.setNumber)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(OverloadTheme.secondaryText)

            TextField("Weight", value: $set.weight, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .disabled(isReadOnly)
                .textFieldStyle(.plain)
                .onSubmit(onSave)

            TextField("Reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .disabled(isReadOnly)
                .textFieldStyle(.plain)
                .onSubmit(onSave)

            TextField("RPE", text: Binding(
                get: { set.rpe.map { String($0) } ?? "" },
                set: { set.rpe = Double($0) }
            ))
                .keyboardType(.decimalPad)
                .disabled(isReadOnly)
                .textFieldStyle(.plain)
                .onSubmit(onSave)

            Button {
                set.completed.toggle()
                HapticFeedback.light()
                onSave()
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.completed ? OverloadTheme.success : OverloadTheme.mutedText)
                    .font(.title3)
            }
            .disabled(isReadOnly)

            Menu {
                Button(set.isWarmup ? "Mark Working Set" : "Mark Warm-up") {
                    set.isWarmup.toggle()
                    onSave()
                }
                Button(set.isFailure ? "Clear Failure" : "Mark Failure") {
                    set.isFailure.toggle()
                    onSave()
                }
                Button("Delete Set", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(OverloadTheme.mutedText)
            }
            .disabled(isReadOnly)
        }
        .foregroundStyle(OverloadTheme.primaryText)
        .font(.subheadline)
    }
}
