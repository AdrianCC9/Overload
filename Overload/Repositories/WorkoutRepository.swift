import Foundation
import SwiftData

@MainActor
final class WorkoutRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchTemplates() -> [WorkoutTemplate] {
        let descriptor = FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func createTemplate(name: String, colorTag: WorkoutColorTag = .red) throws -> WorkoutTemplate {
        let template = WorkoutTemplate(name: name, colorTag: colorTag)
        context.insert(template)
        try context.save()
        return template
    }

    func deleteTemplate(_ template: WorkoutTemplate) throws {
        context.delete(template)
        try context.save()
    }

    func addExercise(_ exercise: Exercise, to template: WorkoutTemplate) throws {
        guard !template.templateExercises.contains(where: { $0.exercise?.id == exercise.id }) else { return }

        let templateExercise = TemplateExercise(
            exercise: exercise,
            orderIndex: template.orderedExercises.count
        )
        context.insert(templateExercise)
        template.templateExercises.append(templateExercise)
        template.updatedAt = .now
        try context.save()
    }

    func addSet(to templateExercise: TemplateExercise, reps: Int = 8, weight: Double = 0) throws {
        let set = TemplateSet(
            targetReps: reps,
            targetWeight: weight,
            orderIndex: templateExercise.orderedSets.count
        )
        context.insert(set)
        templateExercise.templateSets.append(set)
        templateExercise.workoutTemplate?.updatedAt = .now
        try context.save()
    }

    func deleteTemplateSet(_ set: TemplateSet) throws {
        let templateExercise = set.templateExercise
        if let templateExercise {
            templateExercise.templateSets.removeAll { $0.id == set.id }
        }
        context.delete(set)
        renumberTemplateSets(for: templateExercise)
        templateExercise?.workoutTemplate?.updatedAt = .now
        try context.save()
    }

    func deleteTemplateExercise(_ templateExercise: TemplateExercise) throws {
        let template = templateExercise.workoutTemplate
        if let template {
            template.templateExercises.removeAll { $0.id == templateExercise.id }
        }
        context.delete(templateExercise)
        renumberTemplateExercises(for: template)
        template?.updatedAt = .now
        try context.save()
    }

    func moveTemplateExercise(_ templateExercise: TemplateExercise, direction: MoveDirection) throws {
        guard let template = templateExercise.workoutTemplate else { return }
        let ordered = template.orderedExercises
        guard let currentIndex = ordered.firstIndex(where: { $0.id == templateExercise.id }) else { return }

        let newIndex: Int
        switch direction {
        case .up:
            newIndex = max(0, currentIndex - 1)
        case .down:
            newIndex = min(ordered.count - 1, currentIndex + 1)
        }

        guard newIndex != currentIndex else { return }
        ordered[currentIndex].orderIndex = newIndex
        ordered[newIndex].orderIndex = currentIndex
        template.updatedAt = .now
        try context.save()
    }

    func fetchPlannedWorkouts() -> [PlannedWorkout] {
        let descriptor = FetchDescriptor<PlannedWorkout>(sortBy: [SortDescriptor(\.plannedDate)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func plannedWorkouts(in range: ClosedRange<Date>) -> [PlannedWorkout] {
        fetchPlannedWorkouts().filter { range.contains($0.plannedDate.startOfDay) }
    }

    func plannedWorkouts(on date: Date) -> [PlannedWorkout] {
        fetchPlannedWorkouts().filter { $0.plannedDate.isSameDay(as: date) }
    }

    @discardableResult
    func plan(template: WorkoutTemplate, on date: Date) throws -> PlannedWorkout {
        let plannedDate = date.startOfDay
        if let existing = fetchPlannedWorkouts().first(where: {
            $0.plannedDate.isSameDay(as: plannedDate) && $0.workoutTemplate?.id == template.id
        }) {
            return existing
        }

        let planned = PlannedWorkout(workoutTemplate: template, plannedDate: plannedDate)
        context.insert(planned)
        try context.save()
        return planned
    }

    func move(_ plannedWorkout: PlannedWorkout, to date: Date) throws {
        plannedWorkout.plannedDate = date.startOfDay
        try context.save()
    }

    func updateStatus(_ plannedWorkout: PlannedWorkout, status: WorkoutStatus) throws {
        plannedWorkout.status = status
        try context.save()
    }

    private func renumberTemplateExercises(for template: WorkoutTemplate?) {
        template?.orderedExercises.enumerated().forEach { index, exercise in
            exercise.orderIndex = index
        }
    }

    private func renumberTemplateSets(for templateExercise: TemplateExercise?) {
        templateExercise?.orderedSets.enumerated().forEach { index, set in
            set.orderIndex = index
        }
    }
}

enum MoveDirection {
    case up
    case down
}
