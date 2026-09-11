import XCTest

/// Checks the real shared controls in the existing local account's skin pages.
/// This route reads saved analysis only; it never captures, generates or adopts.
final class SharedActionLayoutUITests: XCTestCase {
    @MainActor
    func testSkinHeaderLinkStaysCompactAndPrimaryLabelsStayReadable() throws {
        continueAfterFailure = false
        guard ProcessInfo.processInfo.environment["AISKIN_RUN_LIVE_UI"] == "1" else {
            throw XCTSkip("Requires the explicit local live UI test session")
        }
        let sessionPath = ProcessInfo.processInfo.environment["AISKIN_UI_TEST_SESSION_FILE"] ?? "/tmp/aiskin-ui-test-session.json"
        guard FileManager.default.fileExists(atPath: sessionPath) else {
            throw XCTSkip("The local live UI test session is missing")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseLiveBackend", "-AISkinUITestSession"]
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "live"
        app.launchEnvironment["AISKIN_UI_TEST_SESSION_FILE"] = sessionPath
        app.launch()
        XCTAssertTrue(app.tabButton(2).waitForExistence(timeout: 10))
        app.tabButton(2).tap()
        let report = app.buttons["skin.overview.report"]
        XCTAssertTrue(report.waitForExistence(timeout: 10), "Use the existing account with a saved analysis")
        assertReadableTitle("重新检测", in: app.buttons["skin.overview.capture"])
        let customize = app.buttons["skin.overview.customize-plan"]
        try reveal(customize, in: app)
        assertReadableTitle("定制我的护肤方案", in: customize)

        let all = app.buttons["skin.overview.history"]
        try reveal(all, in: app)
        let heading = app.staticTexts["检测历史"]
        XCTAssertTrue(heading.exists)
        XCTAssertLessThanOrEqual(all.frame.width, 88, "A header link must not consume the remaining row")
        XCTAssertGreaterThan(all.frame.minX, app.frame.width * 0.70)
        XCTAssertLessThan(heading.frame.maxX, all.frame.minX)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Shared action layout - skin overview"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        all.tap()
        XCTAssertTrue(app.buttons["关闭检测历史"].waitForExistence(timeout: 5))
        app.buttons["关闭检测历史"].tap()
        XCTAssertTrue(customize.waitForExistence(timeout: 5))
    }

    @MainActor
    private func assertReadableTitle(_ title: String, in button: XCUIElement) {
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        // Native bordered buttons expose their title on the button itself,
        // without a separate staticText child. Visual alignment is checked
        // using the retained screenshot, not fabricated child geometry.
        XCTAssertEqual(button.label, title)
        XCTAssertTrue(button.isHittable)
        XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        XCTAssertEqual(button.images.count, 0)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) throws {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTFail("The expected skin overview control is not visible")
        throw LayoutNavigationFailure.unavailableControl
    }

    private enum LayoutNavigationFailure: Error { case unavailableControl }
}
