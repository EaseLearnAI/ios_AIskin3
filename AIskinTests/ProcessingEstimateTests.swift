import XCTest
@testable import AIskin

final class ProcessingEstimateTests: XCTestCase {
    func testEstimateNeverSignalsRequestCompletionEvenAfterLongWait() {
        for elapsed in [0.0, 1, 30, 120, 600, 86_400, .infinity] {
            let percentage = AISkinProcessingEstimate.percentage(elapsed: elapsed)
            XCTAssertGreaterThanOrEqual(percentage, 0)
            XCTAssertLessThanOrEqual(percentage, 98)
            XCTAssertLessThan(percentage, 100)
        }
    }

    func testProgressAdvancesWithoutMovingBackwards() {
        let values = (0...600).map { AISkinProcessingEstimate.percentage(elapsed: Double($0)) }
        XCTAssertEqual(values.first, 0)
        XCTAssertGreaterThan(values[10], 0)
        XCTAssertGreaterThan(values[60], values[10])
        XCTAssertEqual(values.last, 98)
        XCTAssertTrue(zip(values, values.dropFirst()).allSatisfy { $0 <= $1 })
    }

    func testOpeningFeelsFastAndTailSlowsDown() {
        let value = AISkinProcessingEstimate.percentage
        XCTAssertTrue((55...70).contains(value(3)))
        XCTAssertTrue((80...90).contains(value(8)))
        XCTAssertGreaterThan(value(3) - value(0), value(8) - value(3))
        XCTAssertGreaterThan(value(8) - value(3), value(20) - value(8))
        XCTAssertEqual(value(120), 98)
    }

    func testNewRequestAndInvalidElapsedTimeStartAtZero() {
        _ = AISkinProcessingEstimate.percentage(elapsed: 600)
        for elapsed in [0.0, -1, -.infinity, .nan] {
            XCTAssertEqual(AISkinProcessingEstimate.percentage(elapsed: elapsed), 0)
        }
    }
}
