import Charts
import SwiftUI

struct ProgressChartCard: View {
    var title: String
    var metricLabel: String
    var metrics: [ExerciseSessionMetrics]
    var value: (ExerciseSessionMetrics) -> Double

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(OverloadTheme.primaryText)
                        Text(metricLabel)
                            .font(.caption)
                            .foregroundStyle(OverloadTheme.secondaryText)
                    }
                    Spacer()
                }

                if metrics.isEmpty {
                    ContentUnavailableView(
                        "No analytics yet",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Complete a workout to see progress.")
                    )
                    .frame(height: 220)
                    .foregroundStyle(OverloadTheme.secondaryText)
                } else {
                    Chart(metrics) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(metricLabel, value(point))
                        )
                        .foregroundStyle(OverloadTheme.accent)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(metricLabel, value(point))
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

