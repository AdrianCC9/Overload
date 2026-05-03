import Foundation
import SwiftData

@MainActor
enum SeedDataService {
    static func seedIfNeeded(context: ModelContext) {
        let exerciseRepository = ExerciseRepository(context: context)
        try? exerciseRepository.seedExercisesIfNeeded()
    }
}

