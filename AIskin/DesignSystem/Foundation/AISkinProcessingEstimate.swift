import Foundation

/// A presentation estimate only. Actual request completion always takes priority.
/// A fast opening advances to about 60% in 3 seconds and 84% in 8 seconds;
/// the slow tail approaches 98% and never claims that a request has completed.
enum AISkinProcessingEstimate {
    static let ceiling = 98
    private static let openingWeight = 78.0
    private static let openingTime = 2.2
    private static let tailWeight = 20.0
    private static let tailTime = 16.0

    static func progress(elapsed seconds: TimeInterval) -> Double {
        guard seconds > 0 else { return 0 }
        let value = Double(ceiling) - openingWeight * exp(-seconds / openingTime)
            - tailWeight * exp(-seconds / tailTime)
        return value.rounded() >= Double(ceiling) ? Double(ceiling) : max(0, value)
    }

    static func percentage(elapsed seconds: TimeInterval) -> Int {
        Int(progress(elapsed: seconds).rounded())
    }
}
