import Foundation
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
        }
    }
}

private struct AnalyticsContentView: View {
    @ObservedObject var viewModel: AnalyticsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MuscleGroupSetFocusCard(summaries: viewModel.muscleGroupSetSummaries)

                ProgressChartCard(
                    title: "Most Improved: \(viewModel.selectedExercise?.name ?? "Exercise")",
                    metricLabel: "Estimated 1RM",
                    metrics: viewModel.selectedMetrics,
                    value: viewModel.value(for:)
                )

                SimpleAnalyticsCard(title: "Other Stats") {
                    SimpleStatRow(label: "Workouts this week", value: "\(viewModel.dashboardStats.workoutsThisWeek)")
                    SimpleStatRow(label: "Workouts this month", value: "\(viewModel.dashboardStats.workoutsThisMonth)")
                    SimpleStatRow(label: "Training streak", value: "\(viewModel.dashboardStats.trainingStreak) days")
                    SimpleStatRow(label: "Most trained group", value: viewModel.dashboardStats.mostTrainedMuscleGroup)
                    SimpleStatRow(label: "Most improved", value: viewModel.dashboardStats.mostImprovedExercise)
                    SimpleStatRow(label: "Least improved", value: viewModel.dashboardStats.leastImprovedExercise)
                }

                if !viewModel.insights.isEmpty {
                    SimpleAnalyticsCard(title: "Insights") {
                        ForEach(viewModel.insights) { insight in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(insight.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(OverloadTheme.primaryText)
                                Text(insight.detail)
                                    .font(.caption)
                                    .foregroundStyle(OverloadTheme.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !viewModel.recentRecords.isEmpty {
                    SimpleAnalyticsCard(title: "Recent PRs") {
                        ForEach(viewModel.recentRecords) { record in
                            SimpleStatRow(
                                label: "\(record.exerciseName) - \(record.title)",
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
    var summaries: [MuscleGroupSetSummary]

    private var maxCurrentSets: Double {
        Double(max(summaries.map(\.currentWeekSets).max() ?? 1, 1))
    }

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sets By Muscle Group")
                        .font(.headline)
                        .foregroundStyle(OverloadTheme.primaryText)
                    Text("Current week compared with your average week.")
                        .font(.caption)
                        .foregroundStyle(OverloadTheme.secondaryText)
                }

                if summaries.isEmpty {
                    Text("Complete workouts to see weekly set counts.")
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
                                Text("\(summary.currentWeekSets) this week")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(OverloadTheme.accent)
                            }

                            HStack {
                                Text("Avg \(format(summary.averageSetsPerWeek)) / week")
                                    .font(.caption)
                                    .foregroundStyle(OverloadTheme.secondaryText)
                                Spacer()
                                Text("\(summary.totalSets) total")
                                    .font(.caption)
                                    .foregroundStyle(OverloadTheme.mutedText)
                            }

                            GeometryReader { proxy in
                                let currentWeekRatio = Double(summary.currentWeekSets) / maxCurrentSets
                                let barWidth = summary.currentWeekSets == 0 ? 0 : proxy.size.width * max(0.06, currentWeekRatio)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(OverloadTheme.elevated)
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(OverloadTheme.accent)
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
    }

    private func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
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
