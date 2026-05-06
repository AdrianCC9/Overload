import SwiftData
import SwiftUI

struct WorkoutLoggerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutLoggerViewModel?

    var plannedWorkout: PlannedWorkout? = nil
    var existingSession: WorkoutSession? = nil
    var focusedExerciseID: UUID? = nil

    private var loggerTitle: String {
        if focusedExerciseID != nil {
            return "Log Exercise"
        }
        return plannedWorkout?.workoutTemplate?.name ?? existingSession?.workoutTemplate?.name ?? "Workout"
    }

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
            .navigationTitle(loggerTitle)
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
                        session: existingSession,
                        focusedExerciseID: focusedExerciseID
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

    private var visibleExercises: [SessionExercise] {
        viewModel.visibleExercises(in: session)
    }

    private var screenTitle: String {
        if viewModel.isFocusedExerciseMode {
            return visibleExercises.first?.exercise?.name ?? "Exercise"
        }
        return session.workoutTemplate?.name ?? "Workout"
    }

    private var visibleVolume: Double {
        visibleExercises.reduce(0) { $0 + $1.exerciseVolume }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DarkCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(screenTitle)
                                    .font(.title2.weight(.heavy))
                                    .foregroundStyle(OverloadTheme.primaryText)

                                Text(session.date.formatted(.dateTime.weekday(.wide).month().day()))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(OverloadTheme.secondaryText)
                                Text(session.isCompleted ? "Completed" : "In progress")
                                    .font(.caption.weight(.bold))
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

                        HStack {
                            StatPill(title: "Volume", value: "\(Int(visibleVolume)) lbs")
                            StatPill(title: "Exercises", value: "\(visibleExercises.count)")
                            StatPill(title: "Sets", value: "\(visibleExercises.flatMap(\.sessionSets).count)")
                        }
                    }
                }

                ForEach(visibleExercises) { sessionExercise in
                    SessionExerciseLoggerCard(
                        sessionExercise: sessionExercise,
                        isReadOnly: isReadOnly,
                        showsTitle: !viewModel.isFocusedExerciseMode,
                        autoCreateFirstSet: viewModel.isFocusedExerciseMode,
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
                } else if viewModel.isFocusedExerciseMode {
                    RedPrimaryButton(title: "Done", systemImage: "checkmark") {
                        viewModel.completeVisibleSetsAndSave()
                        HapticFeedback.success()
                        onClose()
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
    var showsTitle: Bool
    var autoCreateFirstSet: Bool
    var onAddSet: () -> Void
    var onRemoveSet: (SessionSet) -> Void
    var onSave: () -> Void

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 14) {
                if showsTitle {
                    ExerciseRow(
                        name: sessionExercise.exercise?.name ?? "Exercise",
                        category: sessionExercise.exercise?.category.rawValue ?? "Other",
                        detail: "\(Int(sessionExercise.exerciseVolume)) lbs volume"
                    )
                }

                HStack {
                    Text("SET")
                        .frame(width: 48, alignment: .leading)
                    Text("REPS")
                        .frame(width: 78, alignment: .leading)
                    Text("WEIGHT")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("")
                        .frame(width: 84)
                }
                .font(.caption.weight(.heavy))
                .foregroundStyle(OverloadTheme.mutedText)

                VStack(spacing: 12) {
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
        .onAppear {
            if autoCreateFirstSet, sessionExercise.orderedSets.isEmpty, !isReadOnly {
                onAddSet()
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
