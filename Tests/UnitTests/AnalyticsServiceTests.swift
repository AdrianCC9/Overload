import XCTest
@testable import Overload

final class AnalyticsServiceTests: XCTestCase {
    func testEpleyEstimatedOneRepMax() {
        let result = AnalyticsMath.estimatedOneRepMax(weight: 185, reps: 8)
        XCTAssertEqual(result, 234.333, accuracy: 0.01)
    }

    func testPercentChange() {
        let result = AnalyticsMath.percentChange(from: 200, to: 220)
        XCTAssertEqual(result, 10, accuracy: 0.001)
    }

    func testPlateauDetectedWhenOneRepMaxImprovesLessThanTwoPercent() {
        let now = Date.now
        let metrics = [
            metric(date: now.addingDays(-35), e1RM: 250, topSet: 185, volume: 3_000),
            metric(date: now.addingDays(-28), e1RM: 251, topSet: 185, volume: 3_050),
            metric(date: now.addingDays(-21), e1RM: 252, topSet: 185, volume: 3_100),
            metric(date: now.addingDays(-14), e1RM: 253, topSet: 185, volume: 3_200)
        ]

        let result = PlateauDetectionService.detectPlateau(metrics: metrics, referenceDate: now)

        XCTAssertTrue(result.isPlateau)
        XCTAssertTrue(result.message.contains("last 6 weeks"))
    }

    func testPlateauNotDetectedWhenProgressClearlyIncreases() {
        let now = Date.now
        let metrics = [
            metric(date: now.addingDays(-35), e1RM: 250, topSet: 185, volume: 3_000),
            metric(date: now.addingDays(-28), e1RM: 260, topSet: 195, volume: 3_200),
            metric(date: now.addingDays(-21), e1RM: 270, topSet: 205, volume: 3_500),
            metric(date: now.addingDays(-14), e1RM: 280, topSet: 215, volume: 3_800)
        ]

        let result = PlateauDetectionService.detectPlateau(metrics: metrics, referenceDate: now)

        XCTAssertFalse(result.isPlateau)
    }

    func testZeroWeightBodyweightExerciseDoesNotTriggerWeightPlateau() {
        let now = Date.now
        let metrics = [
            metric(date: now.addingDays(-35), e1RM: 0, topSet: 0, volume: 0),
            metric(date: now.addingDays(-28), e1RM: 0, topSet: 0, volume: 0),
            metric(date: now.addingDays(-21), e1RM: 0, topSet: 0, volume: 0),
            metric(date: now.addingDays(-14), e1RM: 0, topSet: 0, volume: 0)
        ]

        let result = PlateauDetectionService.detectPlateau(metrics: metrics, referenceDate: now)

        XCTAssertFalse(result.isPlateau)
    }

    private func metric(date: Date, e1RM: Double, topSet: Double, volume: Double) -> ExerciseSessionMetrics {
        ExerciseSessionMetrics(
            id: UUID(),
            date: date,
            exerciseName: "Bench Press",
            estimatedOneRepMax: e1RM,
            topSetWeight: topSet,
            volume: volume,
            reps: 24,
            averageWorkingWeight: topSet
        )
    }
}
