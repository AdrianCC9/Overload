import SwiftData
import SwiftUI

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        WeekContainer(context: modelContext)
    }
}

private struct WeekContainer: View {
    @StateObject private var viewModel: WeekViewModel
    @State private var activeLogger: LoggerRoute?

    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: WeekViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            WeekContentView(viewModel: viewModel, activeLogger: $activeLogger)
                .navigationTitle("This Week")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            viewModel.moveWeek(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Button {
                            viewModel.referenceDate = .now
                            viewModel.selectedDate = Date.now.startOfDay
                            viewModel.reload()
                        } label: {
                            Image(systemName: "dot.scope")
                        }

                        Button {
                            viewModel.moveWeek(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .overloadScreenBackground()
                .onAppear {
                    viewModel.reload()
                }
                .sheet(item: $activeLogger, onDismiss: {
                    viewModel.reload()
                }) { route in
                    WorkoutLoggerView(
                        plannedWorkout: route.workout,
                        focusedExerciseID: route.focusedExerciseID
                    )
                }
        }
    }
}

private struct LoggerRoute: Identifiable {
    let id = UUID()
    let workout: PlannedWorkout
    let focusedExerciseID: UUID?
}

private struct WeekContentView: View {
    @ObservedObject var viewModel: WeekViewModel
    @Binding var activeLogger: LoggerRoute?

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                WeekDaySelector(
                    days: viewModel.displayDays,
                    selectedDate: viewModel.selectedDate,
                    onSelect: viewModel.select
                )

                PlanWorkoutButton(
                    templates: viewModel.templates(),
                    onPlan: { template in
                        if let workout = viewModel.plan(template, on: viewModel.selectedDate) {
                            activeLogger = LoggerRoute(workout: workout, focusedExerciseID: nil)
                        }
                    }
                )

                SelectedDayWorkoutPanel(
                    selectedDate: viewModel.selectedDate,
                    workouts: viewModel.selectedWorkouts,
                    onOpenWorkout: { workout in
                        activeLogger = LoggerRoute(workout: workout, focusedExerciseID: nil)
                    },
                    onOpenExercise: { workout, exerciseID in
                        activeLogger = LoggerRoute(
                            workout: workout,
                            focusedExerciseID: exerciseID
                        )
                    },
                    onSkipWorkout: viewModel.markSkipped
                )
            }
            .padding(16)
        }
        .refreshable {
            viewModel.reload()
        }
    }
}

private struct WeekDaySelector: View {
    var days: [Date]
    var selectedDate: Date
    var onSelect: (Date) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(days, id: \.self) { day in
                        let isSelected = day.isSameDay(as: selectedDate)
                        let isToday = day.isSameDay(as: .now)

                        Button {
                            onSelect(day)
                        } label: {
                            VStack(spacing: 10) {
                                Text(DateFormatters.weekday.string(from: day))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(isSelected ? Color.white : isToday ? AppAccentColor.red.color : OverloadTheme.mutedText)

                                VStack(spacing: 2) {
                                    Text("\(Calendar.overload.component(.day, from: day))")
                                        .font(.title2.weight(.heavy))
                                    Text(isToday ? "Today" : isSelected ? day.formatted(.dateTime.month(.abbreviated)) : "")
                                        .font(.caption.weight(.heavy))
                                        .opacity(isToday || isSelected ? 1 : 0)
                                }
                                .frame(width: 52, height: 72)
                                .foregroundStyle(isSelected ? Color.white : isToday ? AppAccentColor.red.color : OverloadTheme.mutedText)
                                .background(dayBackground(isSelected: isSelected, isToday: isToday))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(isToday ? AppAccentColor.red.color : Color.clear, lineWidth: 2)
                                }
                            }
                            .frame(width: 58)
                            .id(day)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            .onAppear {
                scrollToSelectedDay(with: proxy)
            }
            .onChange(of: selectedDate) { _, _ in
                scrollToSelectedDay(with: proxy)
            }
            .onChange(of: days) { _, _ in
                scrollToSelectedDay(with: proxy)
            }
        }
    }

    private func scrollToSelectedDay(with proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.snappy(duration: 0.25)) {
                if let selectedDay = days.first(where: { $0.isSameDay(as: selectedDate) }) {
                    proxy.scrollTo(selectedDay, anchor: .center)
                }
            }
        }
    }

    private func dayBackground(isSelected: Bool, isToday: Bool) -> Color {
        if isToday {
            return isSelected ? AppAccentColor.red.color : AppAccentColor.red.color.opacity(0.18)
        }
        return isSelected ? OverloadTheme.accent : Color.clear
    }
}

private struct PlanWorkoutButton: View {
    var templates: [WorkoutTemplate]
    var onPlan: (WorkoutTemplate) -> Void

    var body: some View {
        Menu {
            ForEach(templates) { template in
                Button(template.name) {
                    onPlan(template)
                }
            }
        } label: {
            Text(templates.isEmpty ? "Create a Workout First" : "Start a Workout")
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 21)
                .background(templates.isEmpty ? OverloadTheme.elevated : OverloadTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(templates.isEmpty)
    }
}

private struct SelectedDayWorkoutPanel: View {
    var selectedDate: Date
    var workouts: [PlannedWorkout]
    var onOpenWorkout: (PlannedWorkout) -> Void
    var onOpenExercise: (PlannedWorkout, UUID?) -> Void
    var onSkipWorkout: (PlannedWorkout) -> Void

    var body: some View {
        VStack(spacing: 16) {
            if workouts.isEmpty {
                EmptySelectedDayCard(selectedDate: selectedDate)
            } else {
                ForEach(workouts) { workout in
                    SelectedWorkoutCard(
                        workout: workout,
                        onOpenWorkout: { onOpenWorkout(workout) },
                        onOpenExercise: { exerciseID in
                            onOpenExercise(workout, exerciseID)
                        },
                        onSkip: { onSkipWorkout(workout) }
                    )
                }
            }
        }
    }
}

private struct EmptySelectedDayCard: View {
    var selectedDate: Date

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.headline)
                    .foregroundStyle(OverloadTheme.primaryText)
                Text("No workout planned.")
                    .font(.subheadline)
                    .foregroundStyle(OverloadTheme.secondaryText)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        }
    }
}

private struct SelectedWorkoutCard: View {
    var workout: PlannedWorkout
    var onOpenWorkout: () -> Void
    var onOpenExercise: (UUID?) -> Void
    var onSkip: () -> Void

    private var exerciseRows: [SelectedWorkoutExerciseRow] {
        let templateExercises = workout.workoutTemplate?.orderedExercises ?? []
        let templateIDs = Set(templateExercises.compactMap { $0.exercise?.id })
        let templateRows = templateExercises.map { templateExercise in
            SelectedWorkoutExerciseRow(
                id: templateExercise.id,
                exerciseID: templateExercise.exercise?.id,
                name: templateExercise.exercise?.name ?? "Exercise",
                isSessionOnly: false,
                loggedSets: loggedSets(forExerciseID: templateExercise.exercise?.id)
            )
        }

        let sessionOnlyRows = workout.linkedSession?.orderedExercises
            .filter { sessionExercise in
                guard let exerciseID = sessionExercise.exercise?.id else { return false }
                return !templateIDs.contains(exerciseID)
            }
            .map { sessionExercise in
                SelectedWorkoutExerciseRow(
                    id: sessionExercise.id,
                    exerciseID: sessionExercise.exercise?.id,
                    name: sessionExercise.exercise?.name ?? "Exercise",
                    isSessionOnly: true,
                    loggedSets: sessionExercise.orderedSets.filter { $0.completed }
                )
            }
        ?? []

        return templateRows + sessionOnlyRows
    }

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(workout.workoutTemplate?.name ?? "Workout")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(OverloadTheme.primaryText)
                        Text("\(exerciseRows.count) Exercises")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(OverloadTheme.secondaryText)
                    }

                    Spacer()

                    Menu {
                        Button("Log Workout", action: onOpenWorkout)
                        Button("Skip", role: .destructive, action: onSkip)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(OverloadTheme.primaryText)
                            .frame(width: 40, height: 40)
                    }
                }

                if exerciseRows.isEmpty {
                    Text("No exercises added yet.")
                        .font(.subheadline)
                        .foregroundStyle(OverloadTheme.secondaryText)
                        .padding(.vertical, 18)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(exerciseRows.enumerated()), id: \.element.id) { index, row in
                            Button {
                                onOpenExercise(row.exerciseID)
                            } label: {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(row.name)
                                            .font(.headline.weight(.heavy))
                                            .foregroundStyle(OverloadTheme.primaryText)
                                            .multilineTextAlignment(.leading)

                                        if row.isSessionOnly {
                                            Text("Added to this workout")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(OverloadTheme.secondaryText)
                                        }

                                        if !row.loggedSets.isEmpty {
                                            VStack(alignment: .leading, spacing: 2) {
                                                ForEach(row.loggedSets) { set in
                                                    Text(setLine(for: set))
                                                        .font(.subheadline.weight(.semibold))
                                                        .foregroundStyle(OverloadTheme.mutedText)
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    Spacer()
                                }
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)

                            if index != exerciseRows.count - 1 {
                                Divider()
                                    .overlay(OverloadTheme.border)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func loggedSets(forExerciseID exerciseID: UUID?) -> [SessionSet] {
        guard let exerciseID else { return [] }
        return workout.linkedSession?.orderedExercises
            .first { $0.exercise?.id == exerciseID }?
            .orderedSets
            .filter { $0.completed }
        ?? []
    }

    private func setLine(for set: SessionSet) -> String {
        "\(set.setNumber). \(set.reps) x \(formattedWeight(set.weight))lbs"
    }

    private func formattedWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(weight)) : String(format: "%.1f", weight)
    }
}

private struct SelectedWorkoutExerciseRow: Identifiable {
    var id: UUID
    var exerciseID: UUID?
    var name: String
    var isSessionOnly: Bool
    var loggedSets: [SessionSet]
}
