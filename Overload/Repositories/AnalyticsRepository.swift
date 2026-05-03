import Foundation
import SwiftData

@MainActor
final class AnalyticsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func saveSnapshot(
        exercise: Exercise?,
        periodStart: Date,
        periodEnd: Date,
        metric: AnalyticsMetric,
        value: Double,
        notes: String
    ) throws {
        let snapshot = AnalyticsSnapshot(
            exercise: exercise,
            periodStart: periodStart,
            periodEnd: periodEnd,
            metric: metric,
            value: value,
            notes: notes
        )
        context.insert(snapshot)
        try context.save()
    }

    func fetchSnapshots() -> [AnalyticsSnapshot] {
        let descriptor = FetchDescriptor<AnalyticsSnapshot>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
}

