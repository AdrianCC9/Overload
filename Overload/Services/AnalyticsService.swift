import Foundation
import SwiftData

struct ProgressInsight: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var detail: String
}

struct DashboardStats {
    var workoutsThisWeek: Int = 0
    var workoutsThisMonth: Int = 0
    var workoutsThisYear: Int = 0
    var trainingStreak: Int = 0
    var mostTrainedMuscleGroup: String = "None"
    var mostImprovedExercise: String = "None"
    var leastImprovedExercise: String = "None"
}

struct MuscleGroupVolume: Identifiable, Equatable {
    var id: String { muscleGroup }
    var muscleGroup: String
    var volume: Double
}

struct MuscleGroupSetSummary: Identifiable, Equatable {
    var id: String { muscleGroup }
    var muscleGroup: String
    var averageSetsPerWeek: Double
    var currentWeekSets: Int
    var totalSets: Int
    var loggedWeeks: Int
}

struct ExerciseFrequency: Identifiable, Equatable {
    var id: String { exerciseName }
    var exerciseName: String
    var sessions: Int
}

struct PersonalRecord: Identifiable, Equatable {
    var id = UUID()
    var exerciseName: String
    var title: String
    var value: String
    var date: Date
}

@MainActor
final class AnalyticsService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func metrics(for exercise: Exercise) -> [ExerciseSessionMetrics] {
        fetchCompletedSessions()
            .flatMap { session in
                session.sessionExercises.compactMap { sessionExercise -> ExerciseSessionMetrics? in
                    guard sessionExercise.exercise?.id == exercise.id, !sessionExercise.workingSets.isEmpty else {
                        return nil
                    }

                    return ExerciseSessionMetrics(
                        id: sessionExercise.id,
                        date: session.date,
                        exerciseName: exercise.name,
                        estimatedOneRepMax: sessionExercise.bestEstimatedOneRepMax,
                        topSetWeight: sessionExercise.topSetWeight,
                        volume: sessionExercise.exerciseVolume,
                        reps: sessionExercise.totalReps,
                        averageWorkingWeight: sessionExercise.averageWorkingWeight
                    )
                }
            }
            .sorted { $0.date < $1.date }
    }

    func value(for metric: AnalyticsMetric, in metrics: ExerciseSessionMetrics) -> Double {
        switch metric {
        case .estimatedOneRepMax:
            return metrics.estimatedOneRepMax
        case .topSetWeight:
            return metrics.topSetWeight
        case .volume:
            return metrics.volume
        case .reps:
            return Double(metrics.reps)
        case .averageWorkingWeight:
            return metrics.averageWorkingWeight
        }
    }

    func changeOverLast30Days(for exercise: Exercise, metric: AnalyticsMetric = .estimatedOneRepMax) -> Double? {
        let cutoff = Calendar.overload.date(byAdding: .day, value: -30, to: .now) ?? .now
        let recent = metrics(for: exercise).filter { $0.date >= cutoff }
        guard let first = recent.first, let last = recent.last, first.id != last.id else {
            return nil
        }
        return AnalyticsMath.percentChange(from: value(for: metric, in: first), to: value(for: metric, in: last))
    }

    func insights(for exercise: Exercise) -> [ProgressInsight] {
        let exerciseMetrics = metrics(for: exercise)
        guard !exerciseMetrics.isEmpty else { return [] }

        var insights: [ProgressInsight] = []

        if let change = changeOverLast30Days(for: exercise) {
            let direction = change >= 0 ? "increased" : "decreased"
            insights.append(
                ProgressInsight(
                    title: "30-day estimated 1RM",
                    detail: "\(exercise.name) estimated 1RM \(direction) \(abs(AnalyticsMath.rounded(change)))% in the last 30 days."
                )
            )
        }

        let plateau = PlateauDetectionService.detectPlateau(metrics: exerciseMetrics)
        insights.append(ProgressInsight(title: plateau.title, detail: plateau.message))

        if let best = exerciseMetrics.max(by: { $0.volume < $1.volume }) {
            insights.append(
                ProgressInsight(
                    title: "Best volume day",
                    detail: "\(DateFormatters.isoDay.string(from: best.date)) was your highest-volume \(exercise.name) session at \(Int(best.volume)) total pounds."
                )
            )
        }

        return insights
    }

    func dashboardStats() -> DashboardStats {
        let sessions = fetchCompletedSessions()
        let today = Date.now.startOfDay
        let weekStart = today.weekStart
        let weekEnd = weekStart.addingDays(7)
        let monthStart = today.monthStart
        let monthEnd = monthStart.addingMonths(1)
        let year = Calendar.overload.component(.year, from: today)

        var stats = DashboardStats()
        stats.workoutsThisWeek = sessions.filter { $0.date >= weekStart && $0.date < weekEnd }.count
        stats.workoutsThisMonth = sessions.filter { $0.date >= monthStart && $0.date < monthEnd }.count
        stats.workoutsThisYear = sessions.filter { Calendar.overload.component(.year, from: $0.date) == year }.count
        stats.trainingStreak = trainingStreak(from: sessions)
        stats.mostTrainedMuscleGroup = mostTrainedMuscleGroup(from: sessions)

        let improvements = exerciseImprovements()
        stats.mostImprovedExercise = improvements.max(by: { $0.value < $1.value })?.key ?? "None"
        stats.leastImprovedExercise = improvements.min(by: { $0.value < $1.value })?.key ?? "None"
        return stats
    }

    func muscleGroupSetSummaries(referenceDate: Date = .now) -> [MuscleGroupSetSummary] {
        let sessions = fetchCompletedSessions()
        let currentWeekStart = referenceDate.weekStart
        let currentWeekEnd = currentWeekStart.addingDays(7)
        let loggedWeeks = max(Set(sessions.map { weekKey(for: $0.date) }).count, 1)

        struct SetAccumulator {
            var total: Int = 0
            var current: Int = 0
        }

        let counts = sessions.reduce(into: [String: SetAccumulator]()) { result, session in
            for sessionExercise in session.sessionExercises {
                let group = sessionExercise.exercise?.category.rawValue ?? "Other"
                let setCount = sessionExercise.workingSets.count
                result[group, default: SetAccumulator()].total += setCount

                if session.date >= currentWeekStart && session.date < currentWeekEnd {
                    result[group, default: SetAccumulator()].current += setCount
                }
            }
        }

        return counts
            .map { group, accumulator in
                MuscleGroupSetSummary(
                    muscleGroup: group,
                    averageSetsPerWeek: Double(accumulator.total) / Double(loggedWeeks),
                    currentWeekSets: accumulator.current,
                    totalSets: accumulator.total,
                    loggedWeeks: loggedWeeks
                )
            }
            .sorted {
                if $0.currentWeekSets == $1.currentWeekSets {
                    return $0.averageSetsPerWeek > $1.averageSetsPerWeek
                }
                return $0.currentWeekSets > $1.currentWeekSets
            }
    }

    func mostImprovedExercise() -> Exercise? {
        let exercises = ((try? context.fetch(FetchDescriptor<Exercise>())) ?? [])
        let improvements = exercises.compactMap { exercise -> (exercise: Exercise, change: Double)? in
            guard let change = changeOverLast30Days(for: exercise), metrics(for: exercise).count >= 2 else {
                return nil
            }
            return (exercise, change)
        }

        return improvements.max(by: { $0.change < $1.change })?.exercise
    }

    func muscleGroupVolumes() -> [MuscleGroupVolume] {
        let totals = fetchCompletedSessions()
            .flatMap(\.sessionExercises)
            .reduce(into: [String: Double]()) { result, sessionExercise in
                let group = sessionExercise.exercise?.category.rawValue ?? "Other"
                result[group, default: 0] += sessionExercise.exerciseVolume
            }

        return totals
            .map { MuscleGroupVolume(muscleGroup: $0.key, volume: $0.value) }
            .sorted { $0.volume > $1.volume }
    }

    func exerciseFrequency(limit: Int = 5) -> [ExerciseFrequency] {
        let counts = fetchCompletedSessions()
            .flatMap(\.sessionExercises)
            .compactMap { $0.exercise?.name }
            .reduce(into: [String: Int]()) { result, exercise in
                result[exercise, default: 0] += 1
            }

        return counts
            .map { ExerciseFrequency(exerciseName: $0.key, sessions: $0.value) }
            .sorted { $0.sessions > $1.sessions }
            .prefix(limit)
            .map { $0 }
    }

    func averageSetsPerMuscleGroupPerWeek() -> [MuscleGroupVolume] {
        let sessions = fetchCompletedSessions()
        let groupedSets = sessions
            .flatMap(\.sessionExercises)
            .reduce(into: [String: Int]()) { result, sessionExercise in
                let group = sessionExercise.exercise?.category.rawValue ?? "Other"
                result[group, default: 0] += sessionExercise.workingSets.count
            }

        let uniqueWeeks = Set(sessions.map { weekKey(for: $0.date) })
        let weekCount = max(uniqueWeeks.count, 1)

        return groupedSets
            .map { MuscleGroupVolume(muscleGroup: $0.key, volume: Double($0.value) / Double(weekCount)) }
            .sorted { $0.volume > $1.volume }
    }

    func recentPersonalRecords(limit: Int = 6) -> [PersonalRecord] {
        let sessions = fetchCompletedSessions().sorted { $0.date < $1.date }
        var bestWeightByExercise: [String: Double] = [:]
        var bestOneRepMaxByExercise: [String: Double] = [:]
        var bestVolumeByExercise: [String: Double] = [:]
        var bestRepsAtWeightByExercise: [String: [Double: Int]] = [:]
        var records: [PersonalRecord] = []

        for session in sessions {
            for sessionExercise in session.sessionExercises {
                guard let exerciseName = sessionExercise.exercise?.name else { continue }

                if sessionExercise.exerciseVolume > (bestVolumeByExercise[exerciseName] ?? 0) {
                    bestVolumeByExercise[exerciseName] = sessionExercise.exerciseVolume
                    records.append(
                        PersonalRecord(
                            exerciseName: exerciseName,
                            title: "Highest session volume",
                            value: "\(Int(sessionExercise.exerciseVolume))",
                            date: session.date
                        )
                    )
                }

                for set in sessionExercise.workingSets {
                    if set.weight > (bestWeightByExercise[exerciseName] ?? 0) {
                        bestWeightByExercise[exerciseName] = set.weight
                        records.append(
                            PersonalRecord(
                                exerciseName: exerciseName,
                                title: "Heaviest weight",
                                value: "\(Int(set.weight)) x \(set.reps)",
                                date: session.date
                            )
                        )
                    }

                    if set.estimatedOneRepMax > (bestOneRepMaxByExercise[exerciseName] ?? 0) {
                        bestOneRepMaxByExercise[exerciseName] = set.estimatedOneRepMax
                        records.append(
                            PersonalRecord(
                                exerciseName: exerciseName,
                                title: "Best estimated 1RM",
                                value: "\(Int(set.estimatedOneRepMax))",
                                date: session.date
                            )
                        )
                    }

                    let bestRepsAtWeight = bestRepsAtWeightByExercise[exerciseName]?[set.weight] ?? 0
                    if set.reps > bestRepsAtWeight {
                        bestRepsAtWeightByExercise[exerciseName, default: [:]][set.weight] = set.reps
                        records.append(
                            PersonalRecord(
                                exerciseName: exerciseName,
                                title: "Most reps at \(Int(set.weight))",
                                value: "\(set.reps) reps",
                                date: session.date
                            )
                        )
                    }
                }
            }
        }

        return records
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    private func fetchCompletedSessions() -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date)])
        return ((try? context.fetch(descriptor)) ?? []).filter(\.isCompleted)
    }

    private func trainingStreak(from sessions: [WorkoutSession]) -> Int {
        let completedDays = Set(sessions.map { $0.date.startOfDay })
        var streak = 0
        var cursor = Date.now.startOfDay

        while completedDays.contains(cursor) {
            streak += 1
            cursor = cursor.addingDays(-1)
        }

        if streak == 0, completedDays.contains(Date.now.addingDays(-1).startOfDay) {
            cursor = Date.now.addingDays(-1).startOfDay
            while completedDays.contains(cursor) {
                streak += 1
                cursor = cursor.addingDays(-1)
            }
        }

        return streak
    }

    private func mostTrainedMuscleGroup(from sessions: [WorkoutSession]) -> String {
        let counts = sessions
            .flatMap(\.sessionExercises)
            .compactMap { $0.exercise?.category.rawValue }
            .reduce(into: [String: Int]()) { result, category in
                result[category, default: 0] += 1
            }

        return counts.max(by: { $0.value < $1.value })?.key ?? "None"
    }

    private func exerciseImprovements() -> [String: Double] {
        let exercises = ((try? context.fetch(FetchDescriptor<Exercise>())) ?? [])
        return exercises.reduce(into: [String: Double]()) { result, exercise in
            guard let change = changeOverLast30Days(for: exercise) else { return }
            result[exercise.name] = change
        }
    }

    private func weekKey(for date: Date) -> String {
        let components = Calendar.overload.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(components.yearForWeekOfYear ?? 0)-\(components.weekOfYear ?? 0)"
    }
}
