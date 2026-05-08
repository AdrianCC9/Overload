import SwiftData
import XCTest
@testable import Overload

@MainActor
final class BuilderAndResetTests: XCTestCase {
    func testCreateTemplateReturnsTemplateAndReloadsBuilderList() throws {
        let context = try makeContext()
        let viewModel = WorkoutBuilderViewModel(context: context)

        XCTAssertTrue(viewModel.templates.isEmpty)

        let template = viewModel.createTemplate(name: "Push", colorTag: .red)

        XCTAssertEqual(template?.name, "Push")
        XCTAssertEqual(viewModel.templates.map(\.name), ["Push"])
    }

    func testAddCustomExerciseOnlyNeedsExerciseName() throws {
        let context = try makeContext()
        let viewModel = WorkoutBuilderViewModel(context: context)
        let template = try XCTUnwrap(viewModel.createTemplate(name: "Push", colorTag: .blue))

        viewModel.addCustomExercise(named: "Adrian Curl", to: template)

        XCTAssertEqual(template.orderedExercises.map { $0.exercise?.name }, ["Adrian Curl"])
        XCTAssertEqual(template.orderedExercises.first?.exercise?.category, .biceps)
        XCTAssertEqual(template.orderedExercises.first?.exercise?.isCustom, true)
    }

    func testAnalyticsCountsInProgressSetsByMainMuscleThisWeek() throws {
        let context = try makeContext()
        let builder = WorkoutBuilderViewModel(context: context)
        let template = try XCTUnwrap(builder.createTemplate(name: "Upper", colorTag: .red))

        builder.addCustomExercise(named: "Preacher Curl", to: template)
        builder.addCustomExercise(named: "Chest Press", to: template)

        let plannedWorkout = try WorkoutRepository(context: context).plan(template: template, on: .now)
        let session = try WorkoutLoggingService(context: context).session(for: plannedWorkout)

        for sessionExercise in session.orderedExercises {
            try WorkoutLoggingService(context: context).addSet(to: sessionExercise)
            let set = try XCTUnwrap(sessionExercise.orderedSets.first)
            set.reps = 10
            set.weight = 100
            set.completed = true
        }
        try context.save()

        let summaries = AnalyticsService(context: context).muscleGroupSetSummaries()
        let biceps = try XCTUnwrap(summaries.first { $0.muscleGroup == "Biceps" })
        let chest = try XCTUnwrap(summaries.first { $0.muscleGroup == "Chest" })

        XCTAssertEqual(biceps.currentWeekSets, 1)
        XCTAssertEqual(chest.currentWeekSets, 1)
    }

    func testAnalyticsCountsMultiMuscleExercisesAndIncludesZeroRows() throws {
        let context = try makeContext()
        let builder = WorkoutBuilderViewModel(context: context)
        let template = try XCTUnwrap(builder.createTemplate(name: "Legs", colorTag: .green))

        builder.addCustomExercise(named: "Hack Squat", to: template)

        let plannedWorkout = try WorkoutRepository(context: context).plan(template: template, on: .now)
        let session = try WorkoutLoggingService(context: context).session(for: plannedWorkout)
        let sessionExercise = try XCTUnwrap(session.orderedExercises.first)

        try WorkoutLoggingService(context: context).addSet(to: sessionExercise)
        let set = try XCTUnwrap(sessionExercise.orderedSets.first)
        set.reps = 10
        set.weight = 225
        set.completed = true
        try context.save()

        let summaries = AnalyticsService(context: context).muscleGroupSetSummaries()
        let glutes = try XCTUnwrap(summaries.first { $0.muscleGroup == "Glutes" })
        let quads = try XCTUnwrap(summaries.first { $0.muscleGroup == "Quads" })
        let chest = try XCTUnwrap(summaries.first { $0.muscleGroup == "Chest" })

        XCTAssertEqual(glutes.currentWeekSets, 1)
        XCTAssertEqual(quads.currentWeekSets, 1)
        XCTAssertEqual(chest.currentWeekSets, 0)
    }

    func testAnalyticsWeekIntervalRunsSundayThroughSaturday() throws {
        let context = try makeContext()
        let referenceDate = try XCTUnwrap(DateFormatters.isoDay.date(from: "2026-05-06"))
        let interval = AnalyticsService(context: context).currentWeekInterval(referenceDate: referenceDate)

        XCTAssertEqual(DateFormatters.isoDay.string(from: interval.start), "2026-05-03")
        XCTAssertEqual(DateFormatters.isoDay.string(from: interval.end), "2026-05-09")
    }

    func testCalendarReloadShowsWorkoutPlannedFromWeekViewModel() throws {
        let context = try makeContext()
        let builder = WorkoutBuilderViewModel(context: context)
        let template = try XCTUnwrap(builder.createTemplate(name: "Push", colorTag: .blue))
        let week = WeekViewModel(context: context, referenceDate: .now)
        let calendar = CalendarViewModel(context: context, monthDate: .now)

        week.plan(template, on: week.selectedDate)
        calendar.reload()

        XCTAssertEqual(calendar.selectedWorkouts.first?.workoutTemplate?.name, "Push")
    }

    func testFocusedLoggerOnlyShowsAndUpdatesTappedExercise() throws {
        let context = try makeContext()
        let builder = WorkoutBuilderViewModel(context: context)
        let template = try XCTUnwrap(builder.createTemplate(name: "Pull", colorTag: .red))

        builder.addCustomExercise(named: "Upper Back Row", to: template)
        builder.addCustomExercise(named: "Lat Pulldown", to: template)

        let plannedWorkout = try WorkoutRepository(context: context).plan(template: template, on: .now)
        let targetExerciseID = try XCTUnwrap(template.orderedExercises.last?.exercise?.id)
        let viewModel = WorkoutLoggerViewModel(
            context: context,
            plannedWorkout: plannedWorkout,
            focusedExerciseID: targetExerciseID
        )

        viewModel.load()
        let session = try XCTUnwrap(viewModel.session)
        let visibleExercises = viewModel.visibleExercises(in: session)

        XCTAssertEqual(visibleExercises.count, 1)
        XCTAssertEqual(visibleExercises.first?.exercise?.name, "Lat Pulldown")

        let focusedExercise = try XCTUnwrap(visibleExercises.first)
        viewModel.addSet(to: focusedExercise)

        XCTAssertEqual(focusedExercise.orderedSets.count, 1)
        XCTAssertEqual(session.orderedExercises.first?.orderedSets.count, 0)
    }

    func testDoneCompletesCopiedSetValuesWithoutEditingAgain() throws {
        let context = try makeContext()
        let builder = WorkoutBuilderViewModel(context: context)
        let template = try XCTUnwrap(builder.createTemplate(name: "Push", colorTag: .red))
        builder.addCustomExercise(named: "Chest Press", to: template)

        let plannedWorkout = try WorkoutRepository(context: context).plan(template: template, on: .now)
        let exerciseID = try XCTUnwrap(template.orderedExercises.first?.exercise?.id)
        let viewModel = WorkoutLoggerViewModel(
            context: context,
            plannedWorkout: plannedWorkout,
            focusedExerciseID: exerciseID
        )

        viewModel.load()
        let sessionExercise = try XCTUnwrap(viewModel.session?.orderedExercises.first)
        viewModel.addSet(to: sessionExercise)

        let firstSet = try XCTUnwrap(sessionExercise.orderedSets.first)
        firstSet.reps = 10
        firstSet.weight = 100
        firstSet.completed = true

        viewModel.addSet(to: sessionExercise)
        let copiedSet = try XCTUnwrap(sessionExercise.orderedSets.last)

        XCTAssertEqual(copiedSet.reps, 10)
        XCTAssertEqual(copiedSet.weight, 100)
        XCTAssertFalse(copiedSet.completed)

        viewModel.completeVisibleSetsAndSave()

        XCTAssertTrue(copiedSet.completed)
    }

    func testLoggerCanAddSessionOnlyExerciseWithoutChangingTemplate() throws {
        let context = try makeContext()
        let builder = WorkoutBuilderViewModel(context: context)
        let template = try XCTUnwrap(builder.createTemplate(name: "Push", colorTag: .red))
        builder.addCustomExercise(named: "Chest Press", to: template)

        let plannedWorkout = try WorkoutRepository(context: context).plan(template: template, on: .now)
        let viewModel = WorkoutLoggerViewModel(context: context, plannedWorkout: plannedWorkout)
        viewModel.load()

        let addedExercise = viewModel.addExercise(named: "Wrist Curl")

        XCTAssertEqual(addedExercise?.exercise?.name, "Wrist Curl")
        XCTAssertEqual(viewModel.session?.orderedExercises.map { $0.exercise?.name }, ["Chest Press", "Wrist Curl"])
        XCTAssertEqual(template.orderedExercises.map { $0.exercise?.name }, ["Chest Press"])
    }

    func testExportCreatesSingleLoggedSetCSVOnly() throws {
        let context = try makeContext()
        let builder = WorkoutBuilderViewModel(context: context)
        let template = try XCTUnwrap(builder.createTemplate(name: "Upper", colorTag: .red))
        builder.addCustomExercise(named: "Preacher Curl", to: template)

        let plannedWorkout = try WorkoutRepository(context: context).plan(template: template, on: .now)
        let session = try WorkoutLoggingService(context: context).session(for: plannedWorkout)
        let sessionExercise = try XCTUnwrap(session.orderedExercises.first)

        try WorkoutLoggingService(context: context).addSet(to: sessionExercise)
        let loggedSet = try XCTUnwrap(sessionExercise.orderedSets.first)
        loggedSet.reps = 7
        loggedSet.weight = 100
        loggedSet.completed = true

        try WorkoutLoggingService(context: context).addSet(to: sessionExercise)
        try context.save()

        let export = CSVExportService().makeExportDocument(context: context).csv

        XCTAssertTrue(export.contains("workout_name,workout_color,exercise_name,muscle_group,set_number,reps,weight_lbs"))
        XCTAssertTrue(export.contains("Upper,red,Preacher Curl,Biceps,1,7,100.00"))
        XCTAssertFalse(export.contains(",2,"))
    }

    func testImportLoggedDataRebuildsWorkoutSessionAndTemplate() throws {
        let context = try makeContext()
        let csv = """
        session_id,date,day,workout_name,workout_color,exercise_name,muscle_group,set_number,reps,weight_lbs,volume_lbs,estimated_1rm_lbs
        11111111-1111-1111-1111-111111111111,2026-05-03,Sunday,Pull,blue,Lat Pulldown,Back,1,8,120.00,960.00,152.00
        11111111-1111-1111-1111-111111111111,2026-05-03,Sunday,Pull,blue,Lat Pulldown,Back,2,9,125.00,1125.00,162.50
        """

        let result = try CSVImportService().importLoggedData(csv: csv, context: context)

        XCTAssertEqual(result.importedSetCount, 2)

        let session = try XCTUnwrap(fetch(WorkoutSession.self, context: context).first)
        XCTAssertEqual(session.workoutTemplate?.name, "Pull")
        XCTAssertEqual(session.workoutTemplate?.colorTag, .blue)
        XCTAssertEqual(session.orderedExercises.first?.exercise?.category, .back)
        XCTAssertEqual(session.orderedExercises.first?.orderedSets.count, 2)
        XCTAssertEqual(fetch(PlannedWorkout.self, context: context).first?.status, .completed)
    }

    func testImportInfersWorkoutColorWhenOlderExportHasNoColorColumn() throws {
        let context = try makeContext()
        let csv = """
        session_id,date,day,workout_name,exercise_name,muscle_group,set_number,reps,weight_lbs,volume_lbs,estimated_1rm_lbs
        22222222-2222-2222-2222-222222222222,2026-05-04,Monday,Legs,Leg Press,Quads,1,10,300.00,3000.00,400.00
        """

        _ = try CSVImportService().importLoggedData(csv: csv, context: context)

        XCTAssertEqual(fetch(WorkoutTemplate.self, context: context).first?.colorTag, .green)
    }

    func testImportCanRestoreSessionOnlyExercisesWithoutAddingThemToTemplate() throws {
        let context = try makeContext()
        let csv = """
        session_id,date,day,workout_name,workout_color,exercise_name,muscle_group,set_number,reps,weight_lbs,volume_lbs,estimated_1rm_lbs,is_template_exercise
        33333333-3333-3333-3333-333333333333,2026-05-05,Tuesday,Push,red,Forearm Curl,Forearms,1,12,35.00,420.00,49.00,false
        """

        _ = try CSVImportService().importLoggedData(csv: csv, context: context)

        let session = try XCTUnwrap(fetch(WorkoutSession.self, context: context).first)
        let template = try XCTUnwrap(session.workoutTemplate)

        XCTAssertEqual(session.orderedExercises.map { $0.exercise?.name }, ["Forearm Curl"])
        XCTAssertTrue(template.orderedExercises.isEmpty)
    }

    func testScreenshotExercisesAreSeededByExactName() throws {
        let expectedExercises: [(name: String, category: ExerciseCategory)] = [
            ("Chest Fly", .chest),
            ("Shoulder Press", .shoulders),
            ("Tricep Extension", .triceps),
            ("Chest Press", .chest),
            ("Lateral Raise", .shoulders),
            ("Triceps Dip", .triceps),
            ("Preacher Curl", .biceps),
            ("Upper Back Row", .back),
            ("Lat Pulldown", .back),
            ("Reverse Fly", .shoulders),
            ("Hammer Curl", .biceps),
            ("Lat Focused Row", .back),
            ("Ab Curl", .core),
            ("Leg Extension", .quads),
            ("Hack Squat", .quads),
            ("Barbell Lunge", .quads),
            ("Hamstring Curl", .hamstrings),
            ("Hip Thrust", .glutes),
            ("Calf Raise", .calves),
            ("Calf Raises", .calves),
            ("Dips", .triceps)
        ]
        let seedsByName = ExerciseMuscleRepository.commonExerciseSeeds.reduce(into: [String: ExerciseCategory]()) {
            $0[$1.name] = $1.category
        }

        for expectedExercise in expectedExercises {
            XCTAssertEqual(
                seedsByName[expectedExercise.name],
                expectedExercise.category,
                "\(expectedExercise.name) should be seeded with the right muscle group"
            )
            XCTAssertEqual(
                ExerciseMuscleRepository.category(for: expectedExercise.name),
                expectedExercise.category,
                "\(expectedExercise.name) should resolve to the right muscle group"
            )
        }
    }

    func testClearTrainingDataRemovesTemplatesPlansAndSessionsButKeepsExercises() throws {
        let context = try makeContext()
        let viewModel = WorkoutBuilderViewModel(context: context)
        let exercise = try XCTUnwrap(viewModel.exercises.first { $0.name == "Bench Press" })
        let template = try XCTUnwrap(viewModel.createTemplate(name: "Push", colorTag: .red))

        viewModel.addExercise(exercise, to: template)

        let workoutRepository = WorkoutRepository(context: context)
        try workoutRepository.plan(template: template, on: .now)
        let plannedWorkout = try XCTUnwrap(workoutRepository.fetchPlannedWorkouts().first)

        let loggingService = WorkoutLoggingService(context: context)
        let session = try loggingService.session(for: plannedWorkout)
        let sessionExercise = try XCTUnwrap(session.orderedExercises.first)
        try loggingService.addSet(to: sessionExercise)
        let set = try XCTUnwrap(sessionExercise.orderedSets.first)
        set.weight = 185
        set.reps = 8
        set.completed = true
        try loggingService.finish(session)

        try TrainingDataResetService(context: context).clearTrainingData()

        XCTAssertFalse(fetch(Exercise.self, context: context).isEmpty)
        XCTAssertTrue(fetch(WorkoutTemplate.self, context: context).isEmpty)
        XCTAssertTrue(fetch(PlannedWorkout.self, context: context).isEmpty)
        XCTAssertTrue(fetch(WorkoutSession.self, context: context).isEmpty)
        XCTAssertTrue(fetch(SessionExercise.self, context: context).isEmpty)
        XCTAssertTrue(fetch(SessionSet.self, context: context).isEmpty)
    }

    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            UserProfile.self,
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            TemplateSet.self,
            PlannedWorkout.self,
            WorkoutSession.self,
            SessionExercise.self,
            SessionSet.self,
            AnalyticsSnapshot.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func fetch<T: PersistentModel>(_ type: T.Type, context: ModelContext) -> [T] {
        (try? context.fetch(FetchDescriptor<T>())) ?? []
    }
}
