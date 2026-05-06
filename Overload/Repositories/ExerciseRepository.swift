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

    func createExercise(name: String, category: ExerciseCategory, unit: MeasurementUnit = .pounds) throws -> Exercise {
        let resolvedCategory = category == .other ? ExerciseMuscleRepository.category(for: name) : category
        let exercise = Exercise(name: name, category: resolvedCategory, defaultUnit: unit, isCustom: true)
        context.insert(exercise)
        try context.save()
        return exercise
    }

    func findOrCreateExercise(name: String, category: ExerciseCategory? = nil, unit: MeasurementUnit = .pounds) throws -> Exercise {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCategory = category ?? ExerciseMuscleRepository.category(for: trimmedName)
        if let existing = fetchExercises().first(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            if existing.category == .other, resolvedCategory != .other {
                existing.category = resolvedCategory
                try context.save()
            }
            return existing
        }
        return try createExercise(name: trimmedName, category: resolvedCategory, unit: unit)
    }

    func deleteExercise(_ exercise: Exercise) throws {
        context.delete(exercise)
        try context.save()
    }

    func seedExercisesIfNeeded() throws {
        let seeds = ExerciseMuscleRepository.commonExerciseSeeds

        let existingNames = Set(fetchExercises().map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        seeds.forEach { name, category in
            guard !existingNames.contains(name.lowercased()) else { return }
            context.insert(Exercise(name: name, category: category, isCustom: false))
        }
        try updateExistingExerciseCategories()
        try context.save()
    }

    private func updateExistingExerciseCategories() throws {
        for exercise in fetchExercises() {
            let inferredCategory = ExerciseMuscleRepository.category(for: exercise.name)
            if inferredCategory != .other, exercise.category != inferredCategory {
                exercise.category = inferredCategory
            }
        }
    }
}
