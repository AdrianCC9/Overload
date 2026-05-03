import SwiftData
import SwiftUI

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WeekViewModel?
    @State private var activeWorkout: PlannedWorkout?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    WeekContentView(viewModel: viewModel, activeWorkout: $activeWorkout)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("This Week")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        viewModel?.moveWeek(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Button {
                        viewModel?.referenceDate = .now
                        viewModel?.reload()
                    } label: {
                        Image(systemName: "dot.scope")
                    }

                    Button {
                        viewModel?.moveWeek(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .overloadScreenBackground()
            .task {
                if viewModel == nil {
                    viewModel = WeekViewModel(context: modelContext)
                } else {
                    viewModel?.reload()
                }
            }
            .sheet(item: $activeWorkout, onDismiss: {
                viewModel?.reload()
            }) { workout in
                TemplateExerciseOrderView(workout: workout)
            }
        }
    }
}

private struct WeekContentView: View {
    @ObservedObject var viewModel: WeekViewModel
    @Binding var activeWorkout: PlannedWorkout?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if viewModel.workoutsByDay.isEmpty {
                    ContentUnavailableView(
                        "No workouts planned this week",
                        systemImage: "calendar.badge.plus",
                        description: Text("Add a workout to any day.")
                    )
                    .foregroundStyle(OverloadTheme.secondaryText)
                    .padding(.top, 80)
                }

                ForEach(viewModel.weekDays, id: \.self) { day in
                    DayPlanCard(
                        day: day,
                        workouts: viewModel.workoutsByDay[day.startOfDay] ?? [],
                        templates: viewModel.templates(),
                        onPlan: { template in viewModel.plan(template, on: day) },
                        onLog: { activeWorkout = $0 },
                        onSkip: viewModel.markSkipped
                    )
                }
            }
            .padding(16)
        }
        .refreshable {
            viewModel.reload()
        }
    }
}

private struct DayPlanCard: View {
    var day: Date
    var workouts: [PlannedWorkout]
    var templates: [WorkoutTemplate]
    var onPlan: (WorkoutTemplate) -> Void
    var onLog: (PlannedWorkout) -> Void
    var onSkip: (PlannedWorkout) -> Void

    private var isToday: Bool {
        day.isSameDay(as: .now)
    }

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(DateFormatters.weekday.string(from: day).uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isToday ? OverloadTheme.accent : OverloadTheme.secondaryText)
                        Text(DateFormatters.shortDisplay.string(from: day))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(OverloadTheme.primaryText)
                    }
                    Spacer()
                    Menu {
                        ForEach(templates) { template in
                            Button(template.name) {
                                onPlan(template)
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(templates.isEmpty ? OverloadTheme.mutedText : OverloadTheme.accent)
                    }
                    .disabled(templates.isEmpty)
                }

                if workouts.isEmpty {
                    Text("No workouts planned.")
                        .font(.subheadline)
                        .foregroundStyle(OverloadTheme.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 10) {
                        ForEach(workouts) { workout in
                            PlannedWorkoutRow(
                                workout: workout,
                                onLog: { onLog(workout) },
                                onSkip: { onSkip(workout) }
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct PlannedWorkoutRow: View {
    var workout: PlannedWorkout
    var onLog: () -> Void
    var onSkip: () -> Void

    private var tint: Color {
        switch workout.status {
        case .planned:
            return workout.workoutTemplate?.colorTag.color ?? OverloadTheme.accent
        case .completed:
            return OverloadTheme.success
        case .skipped:
            return OverloadTheme.warning
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(tint)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(workout.workoutTemplate?.name ?? "Workout")
                    .font(.headline)
                    .foregroundStyle(OverloadTheme.primaryText)
                Text(workout.status.label)
                    .font(.caption)
                    .foregroundStyle(OverloadTheme.secondaryText)
            }

            Spacer()

            Button(action: onLog) {
                Image(systemName: "list.number")
                    .frame(width: 34, height: 34)
                    .background(OverloadTheme.elevated)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Menu {
                Button("Skip", role: .destructive, action: onSkip)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 34, height: 34)
                    .background(OverloadTheme.elevated)
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(OverloadTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
    }
}
