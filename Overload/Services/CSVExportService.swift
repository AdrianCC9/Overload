import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct CSVExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }

    var csv: String

    init(csv: String = "") {
        self.csv = csv
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let text = String(data: data, encoding: .utf8) {
            self.csv = text
        } else {
            self.csv = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(csv.utf8))
    }
}

@MainActor
final class CSVExportService {
    func makeExportDocument(context: ModelContext) -> CSVExportDocument {
        CSVExportDocument(csv: loggedTrainingCSV(context))
    }

    private func loggedTrainingCSV(_ context: ModelContext) -> String {
        let sessions = fetch(WorkoutSession.self, context: context, sortBy: [SortDescriptor(\.date)])
        let rows = sessions.flatMap { session in
            session.orderedExercises.flatMap { sessionExercise in
                sessionExercise.orderedSets
                    .filter { $0.completed && $0.reps > 0 }
                    .map { set in
                        [
                            session.id.uuidString,
                            day(session.date),
                            session.date.formatted(.dateTime.weekday(.wide)),
                            session.workoutTemplate?.name ?? "Custom",
                            session.workoutTemplate?.colorTag.rawValue ?? WorkoutColorTag.red.rawValue,
                            sessionExercise.exercise?.name ?? "",
                            mainMuscleName(for: sessionExercise.exercise),
                            String(set.setNumber),
                            String(set.reps),
                            decimal(set.weight),
                            decimal(set.volume),
                            decimal(set.estimatedOneRepMax)
                        ]
                    }
            }
        }

        return makeCSV(
            header: [
                "session_id",
                "date",
                "day",
                "workout_name",
                "workout_color",
                "exercise_name",
                "muscle_group",
                "set_number",
                "reps",
                "weight_lbs",
                "volume_lbs",
                "estimated_1rm_lbs"
            ],
            rows: rows
        )
    }

    private func exercisesCSV(_ context: ModelContext) -> String {
        let exercises = fetch(Exercise.self, context: context, sortBy: [SortDescriptor(\.name)])
        return makeCSV(
            header: ["id", "name", "muscle_group", "default_unit", "is_custom", "created_at"],
            rows: exercises.map { exercise in
                [
                    exercise.id.uuidString,
                    exercise.name,
                    exercise.category.rawValue,
                    exercise.defaultUnit.rawValue,
                    String(exercise.isCustom),
                    day(exercise.createdAt)
                ]
            }
        )
    }

    private func workoutTemplatesCSV(_ context: ModelContext) -> String {
        let templates = fetch(WorkoutTemplate.self, context: context, sortBy: [SortDescriptor(\.createdAt)])
        return makeCSV(
            header: ["id", "name", "color_tag", "created_at", "updated_at"],
            rows: templates.map { template in
                [
                    template.id.uuidString,
                    template.name,
                    template.colorTag.rawValue,
                    day(template.createdAt),
                    day(template.updatedAt)
                ]
            }
        )
    }

    private func templateExercisesCSV(_ context: ModelContext) -> String {
        let templates = fetch(WorkoutTemplate.self, context: context)
        let rows = templates.flatMap { template in
            template.orderedExercises.map { templateExercise in
                [
                    templateExercise.id.uuidString,
                    template.id.uuidString,
                    template.name,
                    templateExercise.exercise?.id.uuidString ?? "",
                    templateExercise.exercise?.name ?? "",
                    String(templateExercise.orderIndex),
                    templateExercise.notes
                ]
            }
        }

        return makeCSV(
            header: ["id", "workout_template_id", "workout_name", "exercise_id", "exercise_name", "order_index", "notes"],
            rows: rows
        )
    }

    private func templateSetsCSV(_ context: ModelContext) -> String {
        let templates = fetch(WorkoutTemplate.self, context: context)
        let rows = templates.flatMap { template in
            template.orderedExercises.flatMap { templateExercise in
                templateExercise.orderedSets.map { set in
                    [
                        set.id.uuidString,
                        templateExercise.id.uuidString,
                        template.id.uuidString,
                        template.name,
                        templateExercise.exercise?.name ?? "",
                        String(set.orderIndex + 1),
                        decimal(set.targetWeight),
                        String(set.targetReps)
                    ]
                }
            }
        }

        return makeCSV(
            header: ["id", "template_exercise_id", "workout_template_id", "workout_name", "exercise_name", "set_number", "target_weight_lbs", "target_reps"],
            rows: rows
        )
    }

    private func plannedWorkoutsCSV(_ context: ModelContext) -> String {
        let planned = fetch(PlannedWorkout.self, context: context, sortBy: [SortDescriptor(\.plannedDate)])
        return makeCSV(
            header: ["id", "workout_template_id", "workout_name", "planned_date", "status", "linked_session_id"],
            rows: planned.map { workout in
                [
                    workout.id.uuidString,
                    workout.workoutTemplate?.id.uuidString ?? "",
                    workout.workoutTemplate?.name ?? "",
                    day(workout.plannedDate),
                    workout.status.rawValue,
                    workout.linkedSession?.id.uuidString ?? ""
                ]
            }
        )
    }

    private func workoutSessionsCSV(_ context: ModelContext) -> String {
        let sessions = fetch(WorkoutSession.self, context: context, sortBy: [SortDescriptor(\.date)])
        return makeCSV(
            header: ["id", "workout_template_id", "workout_name", "date", "duration_minutes", "bodyweight_lbs", "notes", "completed_at", "total_volume_lbs"],
            rows: sessions.map { session in
                [
                    session.id.uuidString,
                    session.workoutTemplate?.id.uuidString ?? "",
                    session.workoutTemplate?.name ?? "Custom",
                    day(session.date),
                    String(session.durationMinutes),
                    optional(session.bodyweight),
                    session.notes,
                    session.completedAt.map(day) ?? "",
                    decimal(session.totalVolume)
                ]
            }
        )
    }

    private func sessionExercisesCSV(_ context: ModelContext) -> String {
        let sessions = fetch(WorkoutSession.self, context: context, sortBy: [SortDescriptor(\.date)])
        let rows = sessions.flatMap { session in
            session.orderedExercises.map { sessionExercise in
                [
                    sessionExercise.id.uuidString,
                    session.id.uuidString,
                    day(session.date),
                    session.workoutTemplate?.name ?? "Custom",
                    sessionExercise.exercise?.id.uuidString ?? "",
                    sessionExercise.exercise?.name ?? "",
                    sessionExercise.exercise?.category.rawValue ?? "",
                    String(sessionExercise.orderIndex),
                    decimal(sessionExercise.exerciseVolume),
                    decimal(sessionExercise.bestEstimatedOneRepMax),
                    sessionExercise.notes
                ]
            }
        }

        return makeCSV(
            header: ["id", "session_id", "session_date", "workout_name", "exercise_id", "exercise_name", "muscle_group", "order_index", "exercise_volume_lbs", "best_estimated_1rm_lbs", "notes"],
            rows: rows
        )
    }

    private func sessionSetsCSV(_ context: ModelContext) -> String {
        let sessions = fetch(WorkoutSession.self, context: context, sortBy: [SortDescriptor(\.date)])
        let rows = sessions.flatMap { session in
            session.orderedExercises.flatMap { sessionExercise in
                sessionExercise.orderedSets.map { set in
                    [
                        session.id.uuidString,
                        day(session.date),
                        session.workoutTemplate?.name ?? "Custom",
                        sessionExercise.exercise?.name ?? "",
                        sessionExercise.exercise?.category.rawValue ?? "",
                        String(set.setNumber),
                        decimal(set.weight),
                        String(set.reps),
                        decimal(set.volume),
                        decimal(set.estimatedOneRepMax),
                        String(set.isWarmup),
                        String(set.isFailure),
                        String(set.completed),
                        sessionExercise.notes
                    ]
                }
            }
        }

        return makeCSV(
            header: [
                "session_id",
                "session_date",
                "workout_name",
                "exercise_name",
                "muscle_group",
                "set_number",
                "weight_lbs",
                "reps",
                "volume_lbs",
                "estimated_1rm_lbs",
                "is_warmup",
                "is_failure",
                "completed",
                "notes"
            ],
            rows: rows
        )
    }

    private func analyticsSnapshotsCSV(_ context: ModelContext) -> String {
        let snapshots = fetch(AnalyticsSnapshot.self, context: context, sortBy: [SortDescriptor(\.createdAt)])
        return makeCSV(
            header: ["id", "exercise_id", "exercise_name", "period_start", "period_end", "metric", "value", "notes", "created_at"],
            rows: snapshots.map { snapshot in
                [
                    snapshot.id.uuidString,
                    snapshot.exercise?.id.uuidString ?? "",
                    snapshot.exercise?.name ?? "",
                    day(snapshot.periodStart),
                    day(snapshot.periodEnd),
                    snapshot.metric.rawValue,
                    decimal(snapshot.value),
                    snapshot.notes,
                    day(snapshot.createdAt)
                ]
            }
        )
    }

    private func fetch<T: PersistentModel>(
        _ type: T.Type,
        context: ModelContext,
        sortBy: [SortDescriptor<T>] = []
    ) -> [T] {
        (try? context.fetch(FetchDescriptor<T>(sortBy: sortBy))) ?? []
    }

    private func makeCSV(header: [String], rows: [[String]]) -> String {
        ([header] + rows)
            .map { row in row.map(escape).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private func escape(_ field: String) -> String {
        let normalized = field.replacingOccurrences(of: "\r\n", with: "\n")
        let needsQuotes = normalized.contains(",") || normalized.contains("\"") || normalized.contains("\n")
        let escaped = normalized.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }

    private func day(_ date: Date) -> String {
        DateFormatters.isoDay.string(from: date)
    }

    private func optional(_ value: Double?) -> String {
        value.map(decimal) ?? ""
    }

    private func decimal(_ value: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    private func mainMuscleName(for exercise: Exercise?) -> String {
        guard let exercise else { return ExerciseCategory.other.rawValue }
        let inferredCategory = ExerciseMuscleRepository.category(for: exercise.name)
        return (inferredCategory == .other ? exercise.category : inferredCategory).rawValue
    }
}
