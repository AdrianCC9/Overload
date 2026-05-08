import Foundation
import SwiftData

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published private(set) var exercises: [Exercise] = []
    @Published var selectedExercise: Exercise?
    @Published var selectedMetric: AnalyticsMetric = .estimatedOneRepMax
    @Published private(set) var selectedMetrics: [ExerciseSessionMetrics] = []
    @Published private(set) var insights: [ProgressInsight] = []
    @Published private(set) var dashboardStats = DashboardStats()
    @Published private(set) var currentWeekInterval = WeekInterval(start: Date.now.sundayWeekStart, end: Date.now.sundayWeekStart.addingDays(6))
    @Published private(set) var muscleGroupSetSummaries: [MuscleGroupSetSummary] = []
    @Published private(set) var muscleGroupVolumes: [MuscleGroupVolume] = []
    @Published private(set) var averageSetsPerMuscleGroup: [MuscleGroupVolume] = []
    @Published private(set) var exerciseFrequency: [ExerciseFrequency] = []
    @Published private(set) var recentRecords: [PersonalRecord] = []
    @Published private(set) var maxWeightRecords: [PersonalRecord] = []
    @Published var errorMessage: String?

    private let exerciseRepository: ExerciseRepository
    private let analyticsService: AnalyticsService
    private let volumeGoalStore: VolumeGoalStore

    init(context: ModelContext, volumeGoalStore: VolumeGoalStore = VolumeGoalStore()) {
        self.exerciseRepository = ExerciseRepository(context: context)
        self.analyticsService = AnalyticsService(context: context)
        self.volumeGoalStore = volumeGoalStore
        try? exerciseRepository.seedExercisesIfNeeded()
        reload()
    }

    func reload() {
        let loggedExercises = analyticsService.loggedExercises()
        exercises = loggedExercises.isEmpty ? exerciseRepository.fetchExercises() : loggedExercises
        if let selectedExercise, exercises.contains(where: { $0.id == selectedExercise.id }) {
            self.selectedExercise = selectedExercise
        } else {
            selectedExercise = exercises.first
        }
        selectedMetric = .topSetWeight
        dashboardStats = analyticsService.dashboardStats()
        currentWeekInterval = analyticsService.currentWeekInterval()
        muscleGroupSetSummaries = analyticsService.muscleGroupSetSummaries(volumeGoals: volumeGoalStore.goals())
        muscleGroupVolumes = analyticsService.muscleGroupVolumes()
        averageSetsPerMuscleGroup = analyticsService.averageSetsPerMuscleGroupPerWeek()
        exerciseFrequency = analyticsService.exerciseFrequency()
        recentRecords = analyticsService.recentPersonalRecords()
        maxWeightRecords = analyticsService.maxWeightRecords()
        refreshSelectedExercise()
    }

    func selectExercise(_ exercise: Exercise) {
        selectedExercise = exercise
        refreshSelectedExercise()
    }

    func setVolumeGoal(for muscleGroup: String, sets: Int?) {
        volumeGoalStore.setGoal(sets, for: muscleGroup)
        reload()
    }

    func setVolumeGoals(_ goals: [String: Int?]) {
        goals.forEach { muscleGroup, sets in
            volumeGoalStore.setGoal(sets, for: muscleGroup)
        }
        reload()
    }

    func refreshSelectedExercise() {
        guard let selectedExercise else {
            selectedMetrics = []
            insights = []
            return
        }

        selectedMetrics = analyticsService.metrics(for: selectedExercise)
        insights = []
    }

    func value(for metrics: ExerciseSessionMetrics) -> Double {
        analyticsService.value(for: selectedMetric, in: metrics)
    }
}

struct VolumeGoalStore {
    private let key: String
    private let defaults: UserDefaults

    init(key: String = "overloadWeeklyVolumeGoalsByMuscle", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func goals() -> [String: Int] {
        let rawGoals = defaults.dictionary(forKey: key) ?? [:]
        return rawGoals.reduce(into: [String: Int]()) { result, item in
            let goal: Int?
            if let value = item.value as? Int {
                goal = value
            } else if let value = item.value as? NSNumber {
                goal = value.intValue
            } else if let value = item.value as? String {
                goal = Int(value)
            } else {
                goal = nil
            }

            if let goal, goal > 0 {
                result[item.key] = goal
            }
        }
    }

    func setGoal(_ goal: Int?, for muscleGroup: String) {
        var currentGoals = goals()
        if let goal, goal > 0 {
            currentGoals[muscleGroup] = goal
        } else {
            currentGoals.removeValue(forKey: muscleGroup)
        }
        defaults.set(currentGoals, forKey: key)
    }
}
