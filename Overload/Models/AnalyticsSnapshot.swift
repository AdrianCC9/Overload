import Foundation
import SwiftData

@Model
final class AnalyticsSnapshot: Identifiable {
    var id: UUID
    var exercise: Exercise?
    var periodStart: Date
    var periodEnd: Date
    var metricRaw: String
    var value: Double
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        periodStart: Date,
        periodEnd: Date,
        metric: AnalyticsMetric,
        value: Double,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.exercise = exercise
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.metricRaw = metric.rawValue
        self.value = value
        self.notes = notes
        self.createdAt = createdAt
    }

    var metric: AnalyticsMetric {
        get { AnalyticsMetric(rawValue: metricRaw) ?? .estimatedOneRepMax }
        set { metricRaw = newValue.rawValue }
    }
}
