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
                    summaries: viewModel.muscleGroupSetSummaries
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
                    Text("Completed sets by main muscle.")
                        .font(.caption)
                        .foregroundStyle(OverloadTheme.secondaryText)
                }

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
                            }

                            GeometryReader { proxy in
                                let currentWeekRatio = Double(summary.currentWeekSets) / maxCurrentSets
                                let barWidth = summary.currentWeekSets == 0 ? 0 : proxy.size.width * max(0.06, currentWeekRatio)
                                let averageRatio = min(summary.averageSetsPerWeek / maxCurrentSets, 1)
                                let averageX = proxy.size.width * averageRatio

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(OverloadTheme.elevated)
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(OverloadTheme.accent)
                                            .frame(width: barWidth)
                                    }
                                    .overlay(alignment: .leading) {
                                        Rectangle()
                                            .fill(OverloadTheme.primaryText.opacity(0.86))
                                            .frame(width: 2, height: 15)
                                            .offset(x: averageX)
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
    }

    private func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }

    private func setCountText(_ count: Int) -> String {
        "\(count) \(count == 1 ? "Set" : "Sets")"
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
