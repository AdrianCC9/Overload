import Foundation

enum ExerciseMuscleRepository {
    static let commonExerciseSeeds: [(name: String, category: ExerciseCategory)] = [
        ("Ab Crunch Machine", .core),
        ("Ab Curl", .core),
        ("Ab Wheel Rollout", .core),
        ("Arnold Press", .shoulders),
        ("Back Extension", .back),
        ("Barbell Lunge", .quads),
        ("Barbell Curl", .biceps),
        ("Barbell Row", .back),
        ("Bench Press", .chest),
        ("Bent Over Row", .back),
        ("Bicep Curl", .biceps),
        ("Cable Curl", .biceps),
        ("Cable Fly", .chest),
        ("Cable Lateral Raise", .shoulders),
        ("Cable Row", .back),
        ("Tricep Extension", .triceps),
        ("Triceps Extension", .triceps),
        ("Calf Press", .calves),
        ("Calf Raise", .calves),
        ("Calf Raises", .calves),
        ("Chest Fly", .chest),
        ("Chest Press", .chest),
        ("Chin-Up", .back),
        ("Close Grip Bench Press", .triceps),
        ("Concentration Curl", .biceps),
        ("Crunch", .core),
        ("Deadlift", .hamstrings),
        ("Hamstring Curl", .hamstrings),
        ("Decline Bench Press", .chest),
        ("Dip", .triceps),
        ("Dips", .triceps),
        ("Dumbbell Bench Press", .chest),
        ("Dumbbell Curl", .biceps),
        ("Dumbbell Fly", .chest),
        ("Dumbbell Lateral Raise", .shoulders),
        ("Dumbbell Row", .back),
        ("Dumbbell Shoulder Press", .shoulders),
        ("Face Pull", .shoulders),
        ("Front Raise", .shoulders),
        ("Glute Bridge", .glutes),
        ("Goblet Squat", .quads),
        ("Good Morning", .hamstrings),
        ("Hack Squat", .quads),
        ("Hammer Curl", .biceps),
        ("Hammer Strength Row", .back),
        ("Hip Abduction", .glutes),
        ("Hip Adduction", .glutes),
        ("Hip Thrust", .glutes),
        ("Incline Bench Press", .chest),
        ("Incline Dumbbell Press", .chest),
        ("Incline Dumbbell Curl", .biceps),
        ("Lat Focused Row", .back),
        ("Lat Pulldown", .back),
        ("Lateral Raise", .shoulders),
        ("Leg Curl", .hamstrings),
        ("Leg Extension", .quads),
        ("Leg Press", .quads),
        ("Lunge", .quads),
        ("Machine Chest Press", .chest),
        ("Machine Row", .back),
        ("Machine Shoulder Press", .shoulders),
        ("Overhead Press", .shoulders),
        ("Overhead Triceps Extension", .triceps),
        ("Pec Deck", .chest),
        ("Plank", .core),
        ("Preacher Curl", .biceps),
        ("Pull-Up", .back),
        ("Push-Up", .chest),
        ("Rear Delt Fly", .shoulders),
        ("Reverse Curl", .forearms),
        ("Reverse Fly", .shoulders),
        ("Romanian Deadlift", .hamstrings),
        ("Seated Cable Row", .back),
        ("Seated Calf Raise", .calves),
        ("Shoulder Press", .shoulders),
        ("Shrug", .traps),
        ("Skull Crusher", .triceps),
        ("Split Squat", .quads),
        ("Squat", .quads),
        ("Standing Calf Raise", .calves),
        ("T-Bar Row", .back),
        ("Triceps Dip", .triceps),
        ("Triceps Pushdown", .triceps),
        ("Upper Back Row", .back),
        ("Wrist Curl", .forearms)
    ]

    static let standardAnalyticsCategories: [ExerciseCategory] = [
        .chest,
        .back,
        .shoulders,
        .biceps,
        .triceps,
        .forearms,
        .quads,
        .hamstrings,
        .glutes,
        .calves,
        .core,
        .traps
    ]

    static func categories(for exerciseName: String) -> [ExerciseCategory] {
        let normalizedName = normalized(exerciseName)
        if let exactMatch = multiCategoryLookup[normalizedName] {
            return exactMatch
        }

        return [category(for: exerciseName)]
    }

    static func category(for exerciseName: String) -> ExerciseCategory {
        let normalizedName = normalized(exerciseName)
        if let exactMatch = lookup[normalizedName] {
            return exactMatch
        }

        if normalizedName.contains("legcurl") || normalizedName.contains("hamstring") || normalizedName.contains("romaniandeadlift") || normalizedName.contains("goodmorning") {
            return .hamstrings
        }
        if normalizedName.contains("legextension") || normalizedName.contains("legpress") || normalizedName.contains("squat") || normalizedName.contains("lunge") {
            return .quads
        }
        if normalizedName.contains("hipthrust") || normalizedName.contains("glute") {
            return .glutes
        }
        if normalizedName.contains("calf") {
            return .calves
        }
        if normalizedName.contains("curl") {
            return normalizedName.contains("wrist") || normalizedName.contains("reverse") ? .forearms : .biceps
        }
        if normalizedName.contains("tricep") || normalizedName.contains("pushdown") || normalizedName.contains("skullcrusher") {
            return .triceps
        }
        if normalizedName.contains("bench") || normalizedName.contains("chest") || normalizedName.contains("pec") || normalizedName.contains("pushup") || normalizedName.contains("fly") {
            return .chest
        }
        if normalizedName.contains("pulldown") || normalizedName.contains("pullup") || normalizedName.contains("chinup") || normalizedName.contains("row") || normalizedName.contains("lat") {
            return .back
        }
        if normalizedName.contains("shoulder") || normalizedName.contains("overheadpress") || normalizedName.contains("lateralraise") || normalizedName.contains("reardelt") || normalizedName.contains("facepull") {
            return .shoulders
        }
        if normalizedName.contains("crunch") || normalizedName.contains("plank") || normalizedName.contains("ab") || normalizedName.contains("core") {
            return .core
        }
        if normalizedName.contains("shrug") {
            return .traps
        }

        return .other
    }

    static func normalized(_ name: String) -> String {
        name
            .lowercased()
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
    }

    private static let lookup: [String: ExerciseCategory] = Dictionary(
        uniqueKeysWithValues: commonExerciseSeeds.map { (normalized($0.name), $0.category) }
    )

    private static let multiCategorySeeds: [(name: String, categories: [ExerciseCategory])] = [
        ("Dips", [.triceps]),
        ("Calf Raises", [.calves]),
        ("Hack Squat", [.glutes, .quads]),
        ("Barbell Lunge", [.glutes, .quads]),
        ("Reverse Fly", [.back, .shoulders])
    ]

    private static let multiCategoryLookup: [String: [ExerciseCategory]] = Dictionary(
        uniqueKeysWithValues: multiCategorySeeds.map { (normalized($0.name), $0.categories) }
    )
}
