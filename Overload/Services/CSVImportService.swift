import Foundation
import SwiftData

struct CSVImportResult {
    var importedSetCount: Int
}

@MainActor
final class CSVImportService {
    func importLoggedData(csv: String, context: ModelContext) throws -> CSVImportResult {
        let parsedRows = parse(csv)
        guard let header = parsedRows.first else { return CSVImportResult(importedSetCount: 0) }

        let headerLookup = Dictionary(uniqueKeysWithValues: header.enumerated().map { index, column in
            (column.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), index)
        })
        let rows = parsedRows.dropFirst().filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }

        var templatesByName = Dictionary(uniqueKeysWithValues: fetch(WorkoutTemplate.self, context: context).map {
            ($0.name.lowercased(), $0)
        })
        var exercisesByName = Dictionary(uniqueKeysWithValues: fetch(Exercise.self, context: context).map {
            ($0.name.lowercased(), $0)
        })
        let preExistingSessionIDs = Set(fetch(WorkoutSession.self, context: context).map(\.id))
        var importedSessionsByID: [UUID: WorkoutSession] = [:]
        var fallbackSessionIDs: [String: UUID] = [:]
        var importedSetCount = 0

        for row in rows {
            let workoutName = value("workout_name", in: row, headerLookup: headerLookup).nilIfEmpty ?? "Imported Workout"
            let exerciseName = value("exercise_name", in: row, headerLookup: headerLookup).nilIfEmpty ?? "Imported Exercise"
            let date = date(from: value("date", in: row, headerLookup: headerLookup)) ?? Date.now.startOfDay
            let fallbackKey = "\(DateFormatters.isoDay.string(from: date))|\(workoutName)"
            let sessionID = UUID(uuidString: value("session_id", in: row, headerLookup: headerLookup))
                ?? fallbackSessionIDs[fallbackKey]
                ?? UUID()
            fallbackSessionIDs[fallbackKey] = sessionID

            guard !preExistingSessionIDs.contains(sessionID) else { continue }

            let workoutColor = workoutColor(
                rawValue: value("workout_color", in: row, headerLookup: headerLookup),
                workoutName: workoutName
            )
            let template = template(
                named: workoutName,
                color: workoutColor,
                context: context,
                templatesByName: &templatesByName
            )
            let exercise = exercise(
                named: exerciseName,
                muscleGroup: value("muscle_group", in: row, headerLookup: headerLookup),
                context: context,
                exercisesByName: &exercisesByName
            )
            ensureTemplate(template, contains: exercise, context: context)

            let session = importedSessionsByID[sessionID] ?? createSession(
                id: sessionID,
                date: date,
                template: template,
                context: context
            )
            importedSessionsByID[sessionID] = session

            let sessionExercise = ensureSession(session, contains: exercise, context: context)
            let set = SessionSet(
                setNumber: intValue("set_number", in: row, headerLookup: headerLookup) ?? (sessionExercise.orderedSets.count + 1),
                reps: intValue("reps", in: row, headerLookup: headerLookup) ?? 0,
                weight: doubleValue("weight_lbs", in: row, headerLookup: headerLookup) ?? 0,
                completed: true
            )
            context.insert(set)
            sessionExercise.sessionSets.append(set)
            importedSetCount += 1
        }

        try context.save()
        return CSVImportResult(importedSetCount: importedSetCount)
    }

    private func template(
        named name: String,
        color: WorkoutColorTag,
        context: ModelContext,
        templatesByName: inout [String: WorkoutTemplate]
    ) -> WorkoutTemplate {
        let key = name.lowercased()
        if let existing = templatesByName[key] {
            return existing
        }

        let template = WorkoutTemplate(name: name, colorTag: color)
        context.insert(template)
        templatesByName[key] = template
        return template
    }

    private func exercise(
        named name: String,
        muscleGroup: String,
        context: ModelContext,
        exercisesByName: inout [String: Exercise]
    ) -> Exercise {
        let key = name.lowercased()
        let importedCategory = ExerciseCategory(rawValue: muscleGroup)
        let inferredCategory = importedCategory ?? ExerciseMuscleRepository.category(for: name)

        if let existing = exercisesByName[key] {
            if existing.category == .other, inferredCategory != .other {
                existing.category = inferredCategory
            }
            return existing
        }

        let exercise = Exercise(name: name, category: inferredCategory, isCustom: true)
        context.insert(exercise)
        exercisesByName[key] = exercise
        return exercise
    }

    private func ensureTemplate(_ template: WorkoutTemplate, contains exercise: Exercise, context: ModelContext) {
        guard !template.templateExercises.contains(where: { $0.exercise?.id == exercise.id }) else { return }
        let templateExercise = TemplateExercise(exercise: exercise, orderIndex: template.orderedExercises.count)
        context.insert(templateExercise)
        template.templateExercises.append(templateExercise)
    }

    private func createSession(
        id: UUID,
        date: Date,
        template: WorkoutTemplate,
        context: ModelContext
    ) -> WorkoutSession {
        let plannedWorkout = PlannedWorkout(workoutTemplate: template, plannedDate: date.startOfDay, status: .completed)
        let session = WorkoutSession(
            id: id,
            workoutTemplate: template,
            plannedWorkout: plannedWorkout,
            date: date.startOfDay,
            completedAt: date.startOfDay
        )
        context.insert(plannedWorkout)
        context.insert(session)
        plannedWorkout.linkedSession = session
        return session
    }

    private func ensureSession(_ session: WorkoutSession, contains exercise: Exercise, context: ModelContext) -> SessionExercise {
        if let existing = session.sessionExercises.first(where: { $0.exercise?.id == exercise.id }) {
            return existing
        }

        let sessionExercise = SessionExercise(exercise: exercise, orderIndex: session.orderedExercises.count)
        context.insert(sessionExercise)
        session.sessionExercises.append(sessionExercise)
        return sessionExercise
    }

    private func value(_ column: String, in row: [String], headerLookup: [String: Int]) -> String {
        guard let index = headerLookup[column], row.indices.contains(index) else { return "" }
        return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func intValue(_ column: String, in row: [String], headerLookup: [String: Int]) -> Int? {
        Int(value(column, in: row, headerLookup: headerLookup))
    }

    private func doubleValue(_ column: String, in row: [String], headerLookup: [String: Int]) -> Double? {
        Double(value(column, in: row, headerLookup: headerLookup))
    }

    private func date(from string: String) -> Date? {
        DateFormatters.isoDay.date(from: string)
    }

    private func workoutColor(rawValue: String, workoutName: String) -> WorkoutColorTag {
        if let color = WorkoutColorTag(rawValue: rawValue) {
            return color
        }

        let normalizedName = workoutName.lowercased()
        if normalizedName.contains("leg") || normalizedName.contains("lower") {
            return .green
        }
        if normalizedName.contains("pull") || normalizedName.contains("back") {
            return .blue
        }
        if normalizedName.contains("shoulder") {
            return .violet
        }
        return .red
    }

    private func fetch<T: PersistentModel>(_ type: T.Type, context: ModelContext) -> [T] {
        (try? context.fetch(FetchDescriptor<T>())) ?? []
    }

    private func parse(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isInsideQuotes = false
        var iterator = csv.makeIterator()

        while let character = iterator.next() {
            if character == "\"" {
                if isInsideQuotes, let next = iterator.next() {
                    if next == "\"" {
                        field.append("\"")
                    } else {
                        isInsideQuotes = false
                        handle(next, rows: &rows, row: &row, field: &field, isInsideQuotes: &isInsideQuotes)
                    }
                } else {
                    isInsideQuotes.toggle()
                }
            } else {
                handle(character, rows: &rows, row: &row, field: &field, isInsideQuotes: &isInsideQuotes)
            }
        }

        row.append(field)
        rows.append(row)
        return rows
    }

    private func handle(
        _ character: Character,
        rows: inout [[String]],
        row: inout [String],
        field: inout String,
        isInsideQuotes: inout Bool
    ) {
        if character == "," && !isInsideQuotes {
            row.append(field)
            field = ""
        } else if character == "\n" && !isInsideQuotes {
            row.append(field)
            rows.append(row)
            row = []
            field = ""
        } else if character != "\r" {
            field.append(character)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
