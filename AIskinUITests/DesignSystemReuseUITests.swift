import XCTest

/// Opt-in visual evidence for the temporary centralized-token reuse probe.
/// Run against the separately built probe artifact; never changes app settings.
final class DesignSystemReuseUITests: XCTestCase {
    @MainActor
    func testCaptureSharedThemeAcrossRootPages() throws {
        guard ProcessInfo.processInfo.environment["AISKIN_REUSE_PROBE"] == "1" else {
            throw XCTSkip("Set AISKIN_REUSE_PROBE=1 in this test target's environment to capture the isolated visual probe")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "mock"
        app.launch()
        XCTAssertTrue(app.staticTexts["还没有护肤计划"].waitForExistence(timeout: 10))
        capture(app, name: "reuse-home-feature-cards-and-accent")
        app.tabButton(1).tap()
        XCTAssertTrue(app.staticTexts["共 5 件"].waitForExistence(timeout: 10))
        capture(app, name: "reuse-cabinet-product-cards-and-accent")
        app.tabButton(2).tap()
        XCTAssertTrue(app.buttons["skin.capture.start"].waitForExistence(timeout: 10))
        capture(app, name: "reuse-skin-capture-guide-and-accent")
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let screen = app.windows.firstMatch.frame
        for index in 0...2 {
            let tab = app.tabButton(index)
            XCTAssertTrue(tab.isHittable)
            XCTAssertGreaterThanOrEqual(tab.frame.minX, screen.minX)
            XCTAssertLessThanOrEqual(tab.frame.maxX, screen.maxX)
            XCTAssertGreaterThanOrEqual(tab.frame.minY, screen.minY)
            XCTAssertLessThanOrEqual(tab.frame.maxY, screen.maxY)
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
