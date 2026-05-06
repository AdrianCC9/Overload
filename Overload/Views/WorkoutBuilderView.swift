import SwiftData
import SwiftUI

struct WorkoutBuilderView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        WorkoutBuilderContainer(context: modelContext)
    }
}

private struct WorkoutBuilderContainer: View {
    @StateObject private var viewModel: WorkoutBuilderViewModel
    @State private var isCreatingTemplate = false
    @State private var editingTemplate: WorkoutTemplate?
    @State private var pendingCreatedTemplate: WorkoutTemplate?
    @State private var deletingTemplate: WorkoutTemplate?

    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: WorkoutBuilderViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if viewModel.templates.isEmpty {
                        ContentUnavailableView(
                            "No workout templates",
                            systemImage: "dumbbell",
                            description: Text("Create a workout and add exercises in order.")
                        )
                        .foregroundStyle(OverloadTheme.secondaryText)
                        .padding(.top, 80)
                    }

                    ForEach(viewModel.templates) { template in
                        TemplateSummaryCard(
                            template: template,
                            onEdit: { editingTemplate = template },
                            onDelete: { deletingTemplate = template }
                        )
                    }
                }
                .padding(16)
            }
            .refreshable {
                viewModel.reload()
            }
            .navigationTitle("Builder")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreatingTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overloadScreenBackground()
            .onAppear {
                viewModel.reload()
            }
            .sheet(isPresented: $isCreatingTemplate, onDismiss: {
                viewModel.reload()
                if let pendingCreatedTemplate {
                    editingTemplate = pendingCreatedTemplate
                    self.pendingCreatedTemplate = nil
                }
            }) {
                NewTemplateSheet(viewModel: viewModel) { template in
                    pendingCreatedTemplate = template
                }
            }
            .sheet(item: $editingTemplate, onDismiss: {
                viewModel.reload()
            }) { template in
                TemplateEditorView(template: template, viewModel: viewModel)
            }
            .confirmationDialog(
                "Delete template?",
                isPresented: Binding(
                    get: { deletingTemplate != nil },
                    set: { if !$0 { deletingTemplate = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Template", role: .destructive) {
                    if let deletingTemplate {
                        viewModel.deleteTemplate(deletingTemplate)
                    }
                    deletingTemplate = nil
                }
                Button("Cancel", role: .cancel) {
                    deletingTemplate = nil
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(OverloadTheme.secondaryText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
    }
}

private struct TemplateSummaryCard: View {
    var template: WorkoutTemplate
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        DarkCard {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(template.colorTag.color)
                    .frame(width: 5)

                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(OverloadTheme.primaryText)
                    Text("\(template.templateExercises.count) exercises")
                        .font(.subheadline)
                        .foregroundStyle(OverloadTheme.secondaryText)

                    HStack(spacing: 6) {
                        ForEach(template.orderedExercises.prefix(4)) { templateExercise in
                            Text(templateExercise.exercise?.name ?? "Exercise")
                                .font(.caption2.weight(.medium))
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(OverloadTheme.elevated)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 36, height: 36)
                        .background(OverloadTheme.elevated)
                        .clipShape(Circle())
                }
            }
        }
        .onTapGesture(perform: onEdit)
    }
}

private struct NewTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkoutBuilderViewModel
    var onCreated: (WorkoutTemplate) -> Void
    @State private var name = ""
    @State private var selectedColor: WorkoutColorTag = .blue

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    TextField("Name", text: $name)
                }
                Section("Color") {
                    TemplateColorPicker(selection: $selectedColor)
                }
            }
            .scrollContentBackground(.hidden)
            .background(OverloadTheme.background)
            .navigationTitle("New Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if let template = viewModel.createTemplate(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            colorTag: selectedColor
                        ) {
                            onCreated(template)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var template: WorkoutTemplate
    @ObservedObject var viewModel: WorkoutBuilderViewModel
    @State private var deletingExercise: TemplateExercise?
    @State private var isAddingExercise = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DarkCard {
                        VStack(alignment: .leading, spacing: 14) {
                            TextField("Workout name", text: $template.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(OverloadTheme.primaryText)
                                .onSubmit(save)

                            TemplateColorPicker(
                                selection: Binding(
                                    get: { template.colorTag },
                                    set: { color in
                                        template.colorTag = color
                                        save()
                                    }
                                )
                            )

                            Button {
                                isAddingExercise = true
                            } label: {
                                Label("Add Exercise", systemImage: "plus.circle.fill")
                                    .foregroundStyle(OverloadTheme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if template.templateExercises.isEmpty {
                        ContentUnavailableView(
                            "No exercises yet",
                            systemImage: "list.bullet.rectangle",
                            description: Text("Add exercises and arrange their order.")
                        )
                        .foregroundStyle(OverloadTheme.secondaryText)
                        .padding(.top, 30)
                    } else {
                        ForEach(template.orderedExercises) { templateExercise in
                            TemplateExerciseCard(
                                templateExercise: templateExercise,
                                onDelete: { deletingExercise = templateExercise },
                                onMoveUp: { viewModel.moveTemplateExercise(templateExercise, direction: .up) },
                                onMoveDown: { viewModel.moveTemplateExercise(templateExercise, direction: .down) }
                            )
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save()
                        dismiss()
                    }
                }
            }
            .overloadScreenBackground()
            .sheet(isPresented: $isAddingExercise) {
                AddCustomExerciseSheet { exerciseName in
                    viewModel.addCustomExercise(named: exerciseName, to: template)
                }
            }
            .confirmationDialog(
                "Delete exercise?",
                isPresented: Binding(
                    get: { deletingExercise != nil },
                    set: { if !$0 { deletingExercise = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Exercise", role: .destructive) {
                    if let deletingExercise {
                        viewModel.deleteTemplateExercise(deletingExercise)
                    }
                    deletingExercise = nil
                }
                Button("Cancel", role: .cancel) {
                    deletingExercise = nil
                }
            }
        }
    }

    private func save() {
        template.updatedAt = .now
        try? modelContext.save()
    }
}

private struct TemplateColorPicker: View {
    @Binding var selection: WorkoutColorTag

    private let colors: [WorkoutColorTag] = [.blue, .red, .green, .orange, .violet, .cyan]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(colors) { color in
                Button {
                    selection = color
                } label: {
                    Circle()
                        .fill(color.color)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Circle()
                                .stroke(selection == color ? Color.white : Color.clear, lineWidth: 3)
                        }
                        .overlay {
                            if selection == color {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(color.label) workout color")
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddCustomExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (String) -> Void
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                }
            }
            .scrollContentBackground(.hidden)
            .background(OverloadTheme.background)
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct TemplateExerciseCard: View {
    @Bindable var templateExercise: TemplateExercise
    var onDelete: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("\(templateExercise.orderIndex + 1)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(OverloadTheme.accent)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(templateExercise.exercise?.name ?? "Exercise")
                            .font(.headline)
                            .foregroundStyle(OverloadTheme.primaryText)
                    }

                    Spacer()

                    Menu {
                        Button(action: onMoveUp) {
                            Label("Move Up", systemImage: "arrow.up")
                        }
                        Button(action: onMoveDown) {
                            Label("Move Down", systemImage: "arrow.down")
                        }
                        Button("Delete Exercise", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 34, height: 34)
                            .background(OverloadTheme.elevated)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}
