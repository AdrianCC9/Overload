import SwiftData
import SwiftUI

struct WorkoutLoggerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutLoggerViewModel?

    var plannedWorkout: PlannedWorkout? = nil
    var existingSession: WorkoutSession? = nil

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel, let session = viewModel.session {
                    LoggerContentView(
                        viewModel: viewModel,
                        session: session,
                        onClose: { dismiss() }
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(plannedWorkout?.workoutTemplate?.name ?? existingSession?.workoutTemplate?.name ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .overloadScreenBackground()
            .task {
                if viewModel == nil {
                    let model = WorkoutLoggerViewModel(
                        context: modelContext,
                        plannedWorkout: plannedWorkout,
                        session: existingSession
                    )
                    model.load()
                    viewModel = model
                }
            }
        }
    }
}

private struct LoggerContentView: View {
    @ObservedObject var viewModel: WorkoutLoggerViewModel
    @Bindable var session: WorkoutSession
    var onClose: () -> Void
    @State private var editingCompletedSession = false

    private var isReadOnly: Bool {
        session.isCompleted && !editingCompletedSession
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DarkCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.date.formatted(.dateTime.weekday(.wide).month().day()))
                                    .font(.headline)
                                    .foregroundStyle(OverloadTheme.primaryText)
                                Text(session.isCompleted ? "Completed" : "In progress")
                                    .font(.subheadline)
                                    .foregroundStyle(session.isCompleted ? OverloadTheme.success : OverloadTheme.secondaryText)
                            }
                            Spacer()
                            if session.isCompleted {
                                Button(editingCompletedSession ? "Lock" : "Edit") {
                                    editingCompletedSession.toggle()
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        TextField("Workout notes", text: $session.notes, axis: .vertical)
                            .lineLimit(2...5)
                            .disabled(isReadOnly)
                            .padding(10)
                            .background(OverloadTheme.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                            .onSubmit(viewModel.save)

                        Grid(horizontalSpacing: 12, verticalSpacing: 10) {
                            GridRow {
                                Text("Duration")
                                Text("Bodyweight")
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(OverloadTheme.mutedText)

                            GridRow {
                                TextField("Minutes", value: $session.durationMinutes, format: .number)
                                    .keyboardType(.numberPad)
                                    .disabled(isReadOnly)
                                    .onSubmit(viewModel.save)

                                TextField("Weight", text: Binding(
                                    get: { session.bodyweight.map { String($0) } ?? "" },
                                    set: { session.bodyweight = Double($0) }
                                ))
                                .keyboardType(.decimalPad)
                                .disabled(isReadOnly)
                                .onSubmit(viewModel.save)
                            }
                            .font(.subheadline)
                            .foregroundStyle(OverloadTheme.primaryText)
                        }

                        HStack {
                            StatPill(title: "Volume", value: "\(Int(session.totalVolume))")
                            StatPill(title: "Exercises", value: "\(session.sessionExercises.count)")
                            StatPill(title: "Sets", value: "\(session.sessionExercises.flatMap(\.sessionSets).count)")
                        }
                    }
                }

                ForEach(session.orderedExercises) { sessionExercise in
                    SessionExerciseLoggerCard(
                        sessionExercise: sessionExercise,
                        isReadOnly: isReadOnly,
                        onAddSet: { viewModel.addSet(to: sessionExercise) },
                        onRemoveSet: viewModel.removeSet,
                        onSave: viewModel.save
                    )
                }

                if session.isCompleted {
                    if editingCompletedSession {
                        RedPrimaryButton(title: "Save Changes", systemImage: "checkmark") {
                            viewModel.save()
                            editingCompletedSession = false
                            HapticFeedback.success()
                        }
                    }
                } else {
                    RedPrimaryButton(title: "Finish Workout", systemImage: "flag.checkered") {
                        viewModel.finish()
                        HapticFeedback.success()
                        onClose()
                    }
                }
            }
            .padding(16)
        }
    }
}

private struct SessionExerciseLoggerCard: View {
    @Bindable var sessionExercise: SessionExercise
    var isReadOnly: Bool
    var onAddSet: () -> Void
    var onRemoveSet: (SessionSet) -> Void
    var onSave: () -> Void

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 14) {
                ExerciseRow(
                    name: sessionExercise.exercise?.name ?? "Exercise",
                    category: sessionExercise.exercise?.category.rawValue ?? "Other",
                    detail: "\(Int(sessionExercise.exerciseVolume)) volume"
                )

                TextField("Exercise notes", text: $sessionExercise.notes, axis: .vertical)
                    .lineLimit(1...4)
                    .disabled(isReadOnly)
                    .font(.subheadline)
                    .padding(10)
                    .background(OverloadTheme.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                    .onSubmit(onSave)

                Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("#")
                        Text("Weight")
                        Text("Reps")
                        Text("RPE")
                        Text("")
                        Text("")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(OverloadTheme.mutedText)

                    ForEach(sessionExercise.orderedSets) { set in
                        SetInputRow(
                            set: set,
                            isReadOnly: isReadOnly,
                            onDelete: { onRemoveSet(set) },
                            onSave: onSave
                        )
                    }
                }

                Button(action: onAddSet) {
                    Label("Add Set", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(OverloadTheme.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isReadOnly)
            }
        }
    }
}

private struct StatPill: View {
    var title: String
    var value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(OverloadTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(OverloadTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
    }
}
