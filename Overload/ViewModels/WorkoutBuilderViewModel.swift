import Foundation
import SwiftData

@MainActor
final class WorkoutBuilderViewModel: ObservableObject {
    @Published private(set) var templates: [WorkoutTemplate] = []
    @Published private(set) var exercises: [Exercise] = []
    @Published var errorMessage: String?

    private let workoutRepository: WorkoutRepository
    private let exerciseRepository: ExerciseRepository

    init(context: ModelContext) {
        self.workoutRepository = WorkoutRepository(context: context)
        self.exerciseRepository = ExerciseRepository(context: context)
        try? exerciseRepository.seedExercisesIfNeeded()
        reload()
    }

    func reload() {
        templates = workoutRepository.fetchTemplates()
        exercises = exerciseRepository.fetchExercises()
    }

    @discardableResult
    func createTemplate(name: String, colorTag: WorkoutColorTag) -> WorkoutTemplate? {
        do {
            let template = try workoutRepository.createTemplate(name: name, colorTag: colorTag)
            reload()
            return template
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func createExercise(name: String, category: ExerciseCategory, unit: MeasurementUnit = .pounds) {
        do {
            _ = try exerciseRepository.createExercise(name: name, category: category, unit: unit)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTemplate(_ template: WorkoutTemplate) {
        do {
            try workoutRepository.deleteTemplate(template)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addExercise(_ exercise: Exercise, to template: WorkoutTemplate) {
        do {
            try workoutRepository.addExercise(exercise, to: template)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addCustomExercise(named name: String, to template: WorkoutTemplate) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        do {
            let exercise = try exerciseRepository.findOrCreateExercise(name: trimmedName)
            try workoutRepository.addExercise(exercise, to: template)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addSet(to templateExercise: TemplateExercise) {
        do {
            try workoutRepository.addSet(to: templateExercise)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTemplateSet(_ set: TemplateSet) {
        do {
            try workoutRepository.deleteTemplateSet(set)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTemplateExercise(_ templateExercise: TemplateExercise) {
        do {
            try workoutRepository.deleteTemplateExercise(templateExercise)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveTemplateExercise(_ templateExercise: TemplateExercise, direction: MoveDirection) {
        do {
            try workoutRepository.moveTemplateExercise(templateExercise, direction: direction)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
