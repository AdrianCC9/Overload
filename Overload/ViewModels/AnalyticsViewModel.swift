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
    @Published private(set) var muscleGroupSetSummaries: [MuscleGroupSetSummary] = []
    @Published private(set) var muscleGroupVolumes: [MuscleGroupVolume] = []
    @Published private(set) var averageSetsPerMuscleGroup: [MuscleGroupVolume] = []
    @Published private(set) var exerciseFrequency: [ExerciseFrequency] = []
    @Published private(set) var recentRecords: [PersonalRecord] = []
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
        exercises = exerciseRepository.fetchExercises()
        selectedExercise = analyticsService.mostImprovedExercise() ?? selectedExercise ?? exercises.first
        selectedMetric = .estimatedOneRepMax
        dashboardStats = analyticsService.dashboardStats()
        muscleGroupSetSummaries = analyticsService.muscleGroupSetSummaries()
        muscleGroupVolumes = analyticsService.muscleGroupVolumes()
        averageSetsPerMuscleGroup = analyticsService.averageSetsPerMuscleGroupPerWeek()
        exerciseFrequency = analyticsService.exerciseFrequency()
        recentRecords = analyticsService.recentPersonalRecords()
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
        insights = analyticsService.insights(for: selectedExercise)
    }

    func value(for metrics: ExerciseSessionMetrics) -> Double {
        analyticsService.value(for: selectedMetric, in: metrics)
    }
}
