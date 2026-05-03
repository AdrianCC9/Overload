import Foundation

struct PlateauResult: Equatable {
    var isPlateau: Bool
    var title: String
    var message: String
}

struct ExerciseSessionMetrics: Identifiable, Equatable {
    var id: UUID
    var date: Date
    var exerciseName: String
    var estimatedOneRepMax: Double
    var topSetWeight: Double
    var volume: Double
    var reps: Int
    var averageWorkingWeight: Double
}

enum PlateauDetectionService {
    static func detectPlateau(metrics: [ExerciseSessionMetrics], referenceDate: Date = .now) -> PlateauResult {
        let cutoff = Calendar.overload.date(byAdding: .weekOfYear, value: -6, to: referenceDate) ?? referenceDate
        let recent = metrics
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }

        guard recent.count >= 4 else {
            return PlateauResult(
                isPlateau: false,
                title: "No plateau detected",
                message: "Log at least 4 sessions in 6 weeks for a reliable plateau check."
            )
        }

        let first = recent.first?.estimatedOneRepMax ?? 0
        let last = recent.last?.estimatedOneRepMax ?? 0
        let e1RMChange = AnalyticsMath.percentChange(from: first, to: last)

        if first > 0, e1RMChange < 2 {
            let changeText: String
            if e1RMChange >= 0 {
                changeText = "increased \(AnalyticsMath.rounded(e1RMChange))%"
            } else {
                changeText = "decreased \(abs(AnalyticsMath.rounded(e1RMChange)))%"
            }

            return PlateauResult(
                isPlateau: true,
                title: "Possible \(recent.last?.exerciseName.lowercased() ?? "exercise") plateau",
                message: "Estimated 1RM has \(changeText) over the last 6 weeks across \(recent.count) logged sessions. Consider adjusting volume, intensity, recovery, or exercise variation."
            )
        }

        let lastFour = Array(recent.suffix(4))
        if let firstTopSet = lastFour.first?.topSetWeight,
           firstTopSet > 0,
           lastFour.allSatisfy({ $0.topSetWeight <= firstTopSet }) {
            return PlateauResult(
                isPlateau: true,
                title: "Top set has stalled",
                message: "Top set weight has not increased across the last 4 sessions."
            )
        }

        if lastFour.count == 4 {
            let volumes = lastFour.map(\.volume)
            let volumeDeclined = volumes.allSatisfy { $0 > 0 } && zip(volumes, volumes.dropFirst()).allSatisfy { previous, current in
                current < previous
            }

            if volumeDeclined {
                return PlateauResult(
                    isPlateau: true,
                    title: "Volume trend is down",
                    message: "Total volume has decreased for 3 consecutive sessions."
                )
            }
        }

        return PlateauResult(
            isPlateau: false,
            title: "Progressing",
            message: "No plateau signal in the last 6 weeks."
        )
    }
}
