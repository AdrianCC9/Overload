import Foundation
import SwiftData
import SwiftUI

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CalendarViewModel?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    calendarContent(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        viewModel?.changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Button {
                        viewModel?.changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .overloadScreenBackground()
            .task {
                if viewModel == nil {
                    viewModel = CalendarViewModel(context: modelContext)
                } else {
                    viewModel?.reload()
                }
            }
        }
    }

    @ViewBuilder
    private func calendarContent(_ viewModel: CalendarViewModel) -> some View {
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
                                        viewModel.plan(template, on: viewModel.selectedDate)
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
                            Text("No completed workouts on this date.")
                                .font(.subheadline)
                                .foregroundStyle(OverloadTheme.mutedText)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.selectedSessions) { session in
                                CalendarSessionHistoryCard(session: session)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
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
                    ForEach(sessions.prefix(3)) { _ in
                        Circle()
                            .fill(OverloadTheme.success)
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
                Text("\(Int(session.totalVolume))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(OverloadTheme.accent)
            }

            ForEach(Array(session.orderedExercises.enumerated()), id: \.element.id) { index, exercise in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(OverloadTheme.accent)
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
                            Text("\(formatted(set.weight)) x \(set.reps)")
                            if let rpe = set.rpe {
                                Text("RPE \(formatted(rpe))")
                                    .foregroundStyle(OverloadTheme.mutedText)
                            }
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
