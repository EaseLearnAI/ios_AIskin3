import XCTest

extension XCUIApplication {
    /// Nested SwiftUI descendants can report hittable outside their clipped
    /// viewport. Check actual frames and use short drags without momentum.
    @MainActor
    func showSkinObservationList() {
        let list = scrollViews["skin.report.observations"]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        let top = buttons["肌肤问题"].frame.maxY + 12
        let bottom = buttons["skin.report.retake"].frame.minY - 20
        let viewport = CGRect(x: 0, y: top, width: frame.width, height: bottom - top)
        for _ in 0..<4 where !viewport.contains(list.frame) {
            let distance = min(viewport.height * 0.65, abs(list.frame.midY - viewport.midY))
            let upwards = list.frame.midY > viewport.midY
            let startY = upwards ? bottom - 10 : top + 10
            let start = coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 8, dy: startY))
            let end = start.withOffset(CGVector(dx: 0, dy: upwards ? -distance : distance))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        XCTAssertTrue(viewport.contains(list.frame), "The complete detail viewport must be above the footer before scrolling inside it")
    }

    @MainActor
    func revealSkinObservation(_ id: String) -> XCUIElement {
        let list = scrollViews["skin.report.observations"]
        let summary = staticTexts["skin.report.summary.\(id)"]
        let body = staticTexts["skin.report.detail.\(id)"]
        XCTAssertTrue(summary.exists, "Every saved observation needs a summary: \(id)")
        for _ in 0..<30 {
            let readableFrame = body.exists ? summary.frame.union(body.frame) : summary.frame
            let target = readableFrame.height < list.frame.height - 12 ? readableFrame : summary.frame
            if list.frame.insetBy(dx: 0, dy: 4).contains(target) { return summary }
            let upwards = target.midY > list.frame.midY
            let start = list.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: upwards ? 0.85 : 0.3))
            let end = list.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: upwards ? 0.4 : 0.75))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        XCTFail("The saved summary must become visible inside the detail viewport: \(id)")
        return summary
    }
}
