import SwiftUI

struct TemplateExerciseOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoggingWorkout = false
    var workout: PlannedWorkout

    private var orderedExercises: [TemplateExercise] {
        workout.workoutTemplate?.orderedExercises ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if orderedExercises.isEmpty {
                        ContentUnavailableView(
                            "No exercises",
                            systemImage: "list.number",
                            description: Text("Add exercises in the builder.")
                        )
                        .foregroundStyle(OverloadTheme.secondaryText)
                        .padding(.top, 80)
                    } else {
                        ForEach(Array(orderedExercises.enumerated()), id: \.element.id) { index, templateExercise in
                            DarkCard {
                                HStack(spacing: 14) {
                                    Text("\(index + 1)")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(OverloadTheme.accent)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(templateExercise.exercise?.name ?? "Exercise")
                                            .font(.headline)
                                            .foregroundStyle(OverloadTheme.primaryText)
                                    }

                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle(workout.workoutTemplate?.name ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isLoggingWorkout = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Log Workout")
                }
            }
            .overloadScreenBackground()
            .sheet(isPresented: $isLoggingWorkout) {
                WorkoutLoggerView(plannedWorkout: workout)
            }
        }
    }
}
