import Foundation
import Charts
import SwiftData
import SwiftUI

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AnalyticsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    AnalyticsContentView(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel?.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .overloadScreenBackground()
            .task {
                if viewModel == nil {
                    viewModel = AnalyticsViewModel(context: modelContext)
                } else {
                    viewModel?.reload()
                }
            }
            .onAppear {
                viewModel?.reload()
            }
        }
    }
}

private struct AnalyticsContentView: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MuscleGroupSetFocusCard(
                    title: viewModel.currentWeekInterval.displayTitle,
                    summaries: viewModel.muscleGroupSetSummaries,
                    onSetVolumeGoals: viewModel.setVolumeGoals
                )

                ProgressionChartCard(
                    exercises: viewModel.exercises,
                    selectedExercise: viewModel.selectedExercise,
                    metrics: viewModel.selectedMetrics,
                    onSelectExercise: viewModel.selectExercise
                )

                SimpleAnalyticsCard(title: "Other Stats") {
                    SimpleStatRow(label: "Workouts this week", value: "\(viewModel.dashboardStats.workoutsThisWeek)")
                    SimpleStatRow(label: "Workouts this month", value: "\(viewModel.dashboardStats.workoutsThisMonth)")
                    SimpleStatRow(label: "Training streak", value: "\(viewModel.dashboardStats.trainingStreak) days")
                    SimpleStatRow(label: "Most trained group", value: viewModel.dashboardStats.mostTrainedMuscleGroup)
                    SimpleStatRow(label: "Most improved", value: viewModel.dashboardStats.mostImprovedExercise)
                    SimpleStatRow(label: "Least improved", value: viewModel.dashboardStats.leastImprovedExercise)
                }

                if !viewModel.maxWeightRecords.isEmpty {
                    SimpleAnalyticsCard(title: "PRs") {
                        ForEach(viewModel.maxWeightRecords) { record in
                            SimpleStatRow(
                                label: record.exerciseName,
                                value: record.value
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .refreshable {
            viewModel.reload()
        }
    }
}

private struct MuscleGroupSetFocusCard: View {
    var title: String
    var summaries: [MuscleGroupSetSummary]
    var onSetVolumeGoals: ([String: Int?]) -> Void

    @State private var isEditingGoals = false

    private var maxCurrentSets: Double {
        Double(max(summaries.map(\.currentWeekSets).max() ?? 1, 1))
    }

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(OverloadTheme.primaryText)
                    Text("Completed sets by muscle group.")
                        .font(.caption)
                        .foregroundStyle(OverloadTheme.secondaryText)
                }

                Button {
                    isEditingGoals = true
                } label: {
                    Label("Set Volume Goals", systemImage: "target")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(OverloadTheme.primaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(OverloadTheme.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)

                if summaries.isEmpty {
                    Text("Log sets to see weekly muscle totals.")
                        .font(.subheadline)
                        .foregroundStyle(OverloadTheme.secondaryText)
                } else {
                    ForEach(summaries) { summary in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(summary.muscleGroup)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(OverloadTheme.primaryText)
                                Spacer()
                                Text(setCountText(summary.currentWeekSets))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(OverloadTheme.accent)
                            }

                            HStack {
                                Text("Avg \(format(summary.averageSetsPerWeek)) / week")
                                    .font(.caption)
                                    .foregroundStyle(OverloadTheme.secondaryText)
                                Spacer()
                                if let goal = summary.volumeGoalSets {
                                    Text("Goal \(goal) \(goal == 1 ? "set" : "sets")")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(summary.currentWeekSets >= goal ? OverloadTheme.success : OverloadTheme.secondaryText)
                                }
                            }

                            GeometryReader { proxy in
                                let barWidth = progressBarWidth(for: summary, in: proxy.size.width)
                                let didReachGoal = hasReachedGoal(summary)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(OverloadTheme.elevated)
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(didReachGoal ? OverloadTheme.success : OverloadTheme.accent)
                                            .frame(width: barWidth)
                                    }
                            }
                            .frame(height: 7)
                        }
                        .padding(12)
                        .background(OverloadTheme.elevated.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                    }
                }
            }
        }
        .sheet(isPresented: $isEditingGoals) {
            VolumeGoalEditorView(summaries: summaries) { goals in
                onSetVolumeGoals(goals)
            }
        }
    }

    private func hasReachedGoal(_ summary: MuscleGroupSetSummary) -> Bool {
        guard let goal = summary.volumeGoalSets else { return false }
        return summary.currentWeekSets >= goal
    }

    private func progressBarWidth(for summary: MuscleGroupSetSummary, in availableWidth: CGFloat) -> CGFloat {
        let ratio: Double
        if let goal = summary.volumeGoalSets {
            ratio = min(Double(summary.currentWeekSets) / Double(goal), 1)
        } else {
            ratio = Double(summary.currentWeekSets) / maxCurrentSets
        }

        guard summary.currentWeekSets > 0 else { return 0 }
        return availableWidth * max(0.06, ratio)
    }

    private func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }

    private func setCountText(_ count: Int) -> String {
        "\(count) \(count == 1 ? "Set" : "Sets")"
    }
}

private struct VolumeGoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    var summaries: [MuscleGroupSetSummary]
    var onSave: ([String: Int?]) -> Void
    @State private var goalInputs: [String: String]

    init(summaries: [MuscleGroupSetSummary], onSave: @escaping ([String: Int?]) -> Void) {
        self.summaries = summaries
        self.onSave = onSave
        _goalInputs = State(initialValue: Dictionary(uniqueKeysWithValues: summaries.map { summary in
            (summary.muscleGroup, summary.volumeGoalSets.map(String.init) ?? "")
        }))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weekly Set Goals") {
                    ForEach(summaries) { summary in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(summary.muscleGroup)
                                    .foregroundStyle(OverloadTheme.primaryText)
                                Text("This week: \(summary.currentWeekSets) \(summary.currentWeekSets == 1 ? "set" : "sets")")
                                    .font(.caption)
                                    .foregroundStyle(OverloadTheme.secondaryText)
                            }

                            Spacer()

                            TextField("0", text: Binding(
                                get: { goalInputs[summary.muscleGroup] ?? "" },
                                set: { goalInputs[summary.muscleGroup] = sanitizedGoalInput($0) }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 72)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(OverloadTheme.background)
            .navigationTitle("Volume Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(goals())
                        dismiss()
                    }
                }
            }
        }
    }

    private func sanitizedGoalInput(_ input: String) -> String {
        input.filter(\.isNumber)
    }

    private func goals() -> [String: Int?] {
        summaries.reduce(into: [String: Int?]()) { result, summary in
            let input = (goalInputs[summary.muscleGroup] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let goal = Int(input) {
                result[summary.muscleGroup] = goal
            } else {
                result[summary.muscleGroup] = .some(nil)
            }
        }
    }
}

private struct ProgressionChartCard: View {
    var exercises: [Exercise]
    var selectedExercise: Exercise?
    var metrics: [ExerciseSessionMetrics]
    var onSelectExercise: (Exercise) -> Void

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Progression Chart")
                            .font(.headline)
                            .foregroundStyle(OverloadTheme.primaryText)
                        Text("Max weight by logged workout.")
                            .font(.caption)
                            .foregroundStyle(OverloadTheme.secondaryText)
                    }

                    Spacer()

                    Menu {
                        ForEach(exercises) { exercise in
                            Button(exercise.name) {
                                onSelectExercise(exercise)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedExercise?.name ?? "Exercise")
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(OverloadTheme.primaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(OverloadTheme.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                    }
                    .disabled(exercises.isEmpty)
                }

                if metrics.isEmpty {
                    ContentUnavailableView(
                        "No chart data yet",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Log this exercise to see progression.")
                    )
                    .frame(height: 220)
                    .foregroundStyle(OverloadTheme.secondaryText)
                } else {
                    Chart(metrics) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Max Weight", point.topSetWeight)
                        )
                        .foregroundStyle(OverloadTheme.accent)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Max Weight", point.topSetWeight)
                        )
                        .foregroundStyle(.white)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 240)
                }
            }
        }
    }
}

private struct SimpleAnalyticsCard<Content: View>: View {
    var title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(OverloadTheme.primaryText)
                content
            }
        }
    }
}

private struct SimpleStatRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(OverloadTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OverloadTheme.primaryText)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 3)
    }
}
