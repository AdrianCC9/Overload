import Foundation
import SwiftData

@MainActor
final class ExerciseRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchExercises() -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func createExercise(name: String, category: ExerciseCategory, unit: MeasurementUnit = .pounds) throws {
        let exercise = Exercise(name: name, category: category, defaultUnit: unit, isCustom: true)
        context.insert(exercise)
        try context.save()
    }

    func deleteExercise(_ exercise: Exercise) throws {
        context.delete(exercise)
        try context.save()
    }

    func seedExercisesIfNeeded() throws {
        let seeds: [(String, ExerciseCategory)] = [
            ("Bench Press", .chest),
            ("Squat", .legs),
            ("Deadlift", .legs),
            ("Overhead Press", .shoulders),
            ("Barbell Row", .back),
            ("Pull-Up", .back),
            ("Lat Pulldown", .back),
            ("Leg Press", .legs),
            ("Romanian Deadlift", .legs),
            ("Dumbbell Curl", .arms),
            ("Triceps Pushdown", .arms),
            ("Incline Dumbbell Press", .chest),
            ("Shoulder Press", .shoulders)
        ]

        let existingNames = Set(fetchExercises().map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        seeds.forEach { name, category in
            guard !existingNames.contains(name.lowercased()) else { return }
            context.insert(Exercise(name: name, category: category, isCustom: false))
        }
        try context.save()
    }
}
