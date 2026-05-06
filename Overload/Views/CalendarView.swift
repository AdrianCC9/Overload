import Foundation
import SwiftData
import SwiftUI

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        CalendarContainer(context: modelContext)
    }
}

private struct CalendarContainer: View {
    @StateObject private var viewModel: CalendarViewModel
    @State private var activeWorkout: PlannedWorkout?

    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: CalendarViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            CalendarContentView(viewModel: viewModel, activeWorkout: $activeWorkout)
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        viewModel.changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Button {
                        viewModel.changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .overloadScreenBackground()
            .onAppear {
                viewModel.reload()
            }
            .sheet(item: $activeWorkout, onDismiss: {
                viewModel.reload()
            }) { workout in
                WorkoutLoggerView(plannedWorkout: workout)
            }
        }
    }
}

private struct CalendarContentView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var activeWorkout: PlannedWorkout?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DarkCard {
                    VStack(spacing: 14) {
                        Text(viewModel.monthDate.formatted(.dateTime.month(.wide).year()))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(OverloadTheme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, symbol in
                                Text(symbol)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(OverloadTheme.mutedText)
                                    .frame(maxWidth: .infinity)
                            }

                            ForEach(Array(viewModel.monthDays.enumerated()), id: \.offset) { _, date in
                                CalendarDayCell(
                                    date: date,
                                    isSelected: date?.isSameDay(as: viewModel.selectedDate) ?? false,
                                    workouts: date.map { viewModel.workoutsByDay[$0.startOfDay] ?? [] } ?? [],
                                    sessions: date.map { viewModel.sessionsByDay[$0.startOfDay] ?? [] } ?? [],
                                    onSelect: {
                                        if let date {
                                            viewModel.selectedDate = date.startOfDay
                                        }
                                    }
                                )
                            }
                        }
                    }
                }

                DarkCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Workout History")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(OverloadTheme.secondaryText)
                                Text(viewModel.selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
                                    .font(.headline)
                                    .foregroundStyle(OverloadTheme.primaryText)
                            }

                            Spacer()

                            Menu {
                                ForEach(viewModel.templates()) { template in
                                    Button(template.name) {
                                        if let workout = viewModel.plan(template, on: viewModel.selectedDate) {
                                            activeWorkout = workout
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(viewModel.templates().isEmpty ? OverloadTheme.mutedText : OverloadTheme.accent)
                            }
                            .disabled(viewModel.templates().isEmpty)
                        }

                        if viewModel.selectedSessions.isEmpty {
                            Text("No logged workouts on this date.")
                                .font(.subheadline)
                                .foregroundStyle(OverloadTheme.mutedText)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.selectedSessions) { session in
                                CalendarSessionHistoryCard(session: session)
                            }
                        }

                        if !viewModel.selectedWorkouts.isEmpty {
                            Divider()
                                .overlay(OverloadTheme.border)

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Planned")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(OverloadTheme.secondaryText)

                                ForEach(viewModel.selectedWorkouts) { workout in
                                    CalendarPlannedWorkoutRow(
                                        workout: workout,
                                        onOpen: { activeWorkout = workout }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

private struct CalendarPlannedWorkoutRow: View {
    var workout: PlannedWorkout
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 10) {
                Circle()
                    .fill(workout.workoutTemplate?.colorTag.color ?? OverloadTheme.accent)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.workoutTemplate?.name ?? "Workout")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OverloadTheme.primaryText)
                    Text(workout.status.label)
                        .font(.caption)
                        .foregroundStyle(OverloadTheme.secondaryText)
                }

                Spacer()
            }
            .padding(12)
            .background(OverloadTheme.elevated)
            .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CalendarDayCell: View {
    var date: Date?
    var isSelected: Bool
    var workouts: [PlannedWorkout]
    var sessions: [WorkoutSession]
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Text(date.map { String(Calendar.overload.component(.day, from: $0)) } ?? "")
                    .font(.subheadline.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(date == nil ? .clear : OverloadTheme.primaryText)
                    .frame(height: 20)

                HStack(spacing: 3) {
                    ForEach(Array(sessions.prefix(3))) { session in
                        Circle()
                            .fill(session.workoutTemplate?.colorTag.color ?? OverloadTheme.accent)
                            .frame(width: 5, height: 5)
                    }
                    if sessions.isEmpty {
                        ForEach(workouts.prefix(3)) { workout in
                            Circle()
                                .fill(workout.workoutTemplate?.colorTag.color ?? OverloadTheme.accent)
                                .frame(width: 5, height: 5)
                        }
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(isSelected ? OverloadTheme.accent.opacity(0.22) : OverloadTheme.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(isSelected ? OverloadTheme.accent : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(date == nil)
    }
}

private struct CalendarSessionHistoryCard: View {
    var session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.workoutTemplate?.name ?? "Workout")
                        .font(.headline)
                        .foregroundStyle(OverloadTheme.primaryText)
                    Text("\(session.orderedExercises.count) exercises")
                        .font(.caption)
                        .foregroundStyle(OverloadTheme.secondaryText)
                }
                Spacer()
                Text("\(Int(session.totalVolume)) lbs")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(session.workoutTemplate?.colorTag.color ?? OverloadTheme.accent)
            }

            ForEach(Array(session.orderedExercises.enumerated()), id: \.element.id) { index, exercise in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(session.workoutTemplate?.colorTag.color ?? OverloadTheme.accent)
                            .frame(width: 22)
                        Text(exercise.exercise?.name ?? "Exercise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OverloadTheme.primaryText)
                        Spacer()
                    }

                    ForEach(exercise.orderedSets) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                            Spacer()
                            Text("\(set.reps) x \(formatted(set.weight)) lbs")
                        }
                        .font(.caption)
                        .foregroundStyle(OverloadTheme.secondaryText)
                    }
                }
                .padding(12)
                .background(OverloadTheme.elevated)
                .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}
