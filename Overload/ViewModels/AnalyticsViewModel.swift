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

    init(context: ModelContext) {
        self.exerciseRepository = ExerciseRepository(context: context)
        self.analyticsService = AnalyticsService(context: context)
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
        muscleGroupSetSummaries = analyticsService.muscleGroupSetSummaries()
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
