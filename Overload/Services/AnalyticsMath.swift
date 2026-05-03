import Foundation

enum AnalyticsMath {
    static func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        return weight * (1 + Double(reps) / 30)
    }

    static func percentChange(from start: Double, to end: Double) -> Double {
        guard start != 0 else { return end == 0 ? 0 : 100 }
        return ((end - start) / start) * 100
    }

    static func rounded(_ value: Double, places: Int = 1) -> Double {
        let divisor = pow(10.0, Double(places))
        return (value * divisor).rounded() / divisor
    }
}

