import Foundation
import SwiftData

@MainActor
final class SampleDataService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadSampleData() throws {
        try ExerciseRepository(context: context).seedExercisesIfNeeded()
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        guard sessions.isEmpty else { return }

        let workoutRepository = WorkoutRepository(context: context)
        let loggingService = WorkoutLoggingService(context: context)

        let push = try findOrCreateTemplate(name: "Push", colorTag: .red, repository: workoutRepository)
        let pull = try findOrCreateTemplate(name: "Pull", colorTag: .blue, repository: workoutRepository)
        let legs = try findOrCreateTemplate(name: "Legs", colorTag: .green, repository: workoutRepository)

        try addTemplateExercise("Bench Press", from: exercises, to: push, repository: workoutRepository)
        try addTemplateExercise("Overhead Press", from: exercises, to: push, repository: workoutRepository)
        try addTemplateExercise("Triceps Pushdown", from: exercises, to: push, repository: workoutRepository)

        try addTemplateExercise("Pull-Up", from: exercises, to: pull, repository: workoutRepository)
        try addTemplateExercise("Barbell Row", from: exercises, to: pull, repository: workoutRepository)
        try addTemplateExercise("Lat Pulldown", from: exercises, to: pull, repository: workoutRepository)

        try addTemplateExercise("Squat", from: exercises, to: legs, repository: workoutRepository)
        try addTemplateExercise("Romanian Deadlift", from: exercises, to: legs, repository: workoutRepository)
        try addTemplateExercise("Leg Press", from: exercises, to: legs, repository: workoutRepository)

        for offset in stride(from: -35, through: -2, by: 7) {
            try completeSampleSession(template: push, date: Date.now.addingDays(offset), loggingService: loggingService, benchBase: 180 + Double(offset + 35) * 0.7)
            try completeSampleSession(template: pull, date: Date.now.addingDays(offset + 1), loggingService: loggingService, benchBase: 0)
            try completeSampleSession(template: legs, date: Date.now.addingDays(offset + 2), loggingService: loggingService, benchBase: 0)
        }

        try workoutRepository.plan(template: push, on: Date.now.weekStart)
        try workoutRepository.plan(template: pull, on: Date.now.weekStart.addingDays(1))
        try workoutRepository.plan(template: legs, on: Date.now.weekStart.addingDays(2))
        try context.save()
    }

    private func findOrCreateTemplate(
        name: String,
        colorTag: WorkoutColorTag,
        repository: WorkoutRepository
    ) throws -> WorkoutTemplate {
        if let existingTemplate = repository.fetchTemplates().first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return existingTemplate
        }

        return try repository.createTemplate(name: name, colorTag: colorTag)
    }

    private func addTemplateExercise(
        _ name: String,
        from exercises: [Exercise],
        to template: WorkoutTemplate,
        repository: WorkoutRepository
    ) throws {
        guard let exercise = exercises.first(where: { $0.name == name }) else { return }
        try repository.addExercise(exercise, to: template)
    }

    private func completeSampleSession(
        template: WorkoutTemplate,
        date: Date,
        loggingService: WorkoutLoggingService,
        benchBase: Double
    ) throws {
        let session = try loggingService.session(from: template, date: date)
        session.durationMinutes = 64

        for exercise in session.sessionExercises {
            if exercise.sessionSets.isEmpty {
                for setNumber in 1...3 {
                    let defaults = defaultSet(for: exercise.exercise?.name, setNumber: setNumber)
                    let set = SessionSet(
                        setNumber: setNumber,
                        reps: defaults.reps,
                        weight: defaults.weight,
                        completed: true
                    )
                    context.insert(set)
                    exercise.sessionSets.append(set)
                }
            }

            for set in exercise.sessionSets {
                if exercise.exercise?.name == "Bench Press", benchBase > 0 {
                    set.weight = benchBase
                    set.reps = set.setNumber == 2 ? 7 : 8
                }
                set.completed = true
            }
        }

        try loggingService.finish(session)
    }

    private func defaultSet(for exerciseName: String?, setNumber: Int) -> (reps: Int, weight: Double) {
        switch exerciseName {
        case "Bench Press":
            return (setNumber == 2 ? 7 : 8, 185)
        case "Overhead Press":
            return (8, 95)
        case "Triceps Pushdown":
            return (12, 65)
        case "Pull-Up":
            return (8, 0)
        case "Barbell Row":
            return (10, 155)
        case "Lat Pulldown":
            return (12, 140)
        case "Squat":
            return (5, 275)
        case "Romanian Deadlift":
            return (8, 225)
        case "Leg Press":
            return (12, 360)
        default:
            return (8, 0)
        }
    }
}
