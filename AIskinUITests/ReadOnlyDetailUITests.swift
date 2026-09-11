import XCTest

/// Uses an existing local session with an adopted plan and saved skin report; performs no mutations.
final class ReadOnlyDetailUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testCurrentPlanDetailsAndScoreInformationHaveHonestActions() throws {
        guard ProcessInfo.processInfo.environment["AISKIN_RUN_LIVE_UI"] == "1" else {
            throw XCTSkip("Requires the explicit local live UI test session")
        }
        let sessionPath = ProcessInfo.processInfo.environment["AISKIN_UI_TEST_SESSION_FILE"] ?? "/tmp/aiskin-ui-test-session.json"
        guard FileManager.default.fileExists(atPath: sessionPath) else {
            throw XCTSkip("Provide an existing local session with an adopted plan and skin report")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseLiveBackend", "-AISkinUITestSession"]
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "live"
        app.launchEnvironment["AISKIN_UI_TEST_SESSION_FILE"] = sessionPath
        app.launch()

        let openPlan = app.buttons["home.current-plan.open"]
        XCTAssertTrue(openPlan.waitForExistence(timeout: 15), "This check requires an adopted plan")
        openPlan.tap()
        XCTAssertTrue(app.navigationBars["当前护肤方案"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["早间护理"].exists)
        XCTAssertFalse(app.textFields["plan.form.age"].exists)
        XCTAssertFalse(app.buttons["plan.form.generate"].exists)
        XCTAssertFalse(app.buttons["personalized-plan.save"].exists)
        capture(app, name: "current-plan-read-only-details")
        app.buttons["home.current-plan.done"].tap()
        XCTAssertTrue(openPlan.waitForExistence(timeout: 5))

        app.tabButton(2).tap()
        let scoreLabel = NSPredicate(format: "label BEGINSWITH %@", "综合评分，")
        let staticScore = app.staticTexts.matching(scoreLabel).firstMatch
        capture(app, name: "overview-before-score-assertion")
        XCTAssertTrue(staticScore.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertFalse(app.buttons["skin.summary.score"].exists)
        XCTAssertFalse(app.buttons.matching(scoreLabel).firstMatch.exists)
        XCTAssertFalse(app.buttons["skin.summary.score-info"].exists)
        capture(app, name: "overview-static-score")

        let openReport = app.buttons["skin.overview.report"]
        for _ in 0..<3 where !openReport.isHittable { app.swipeUp() }
        XCTAssertTrue(openReport.isHittable)
        openReport.tap()
        let overview = app.buttons["肤况概览"]
        XCTAssertTrue(overview.waitForExistence(timeout: 10))
        overview.tap()
        let scoreInfo = app.buttons["skin.summary.score-info"]
        XCTAssertTrue(scoreInfo.waitForExistence(timeout: 10))
        scoreInfo.tap()
        XCTAssertTrue(app.staticTexts["这项评分如何理解？"].waitForExistence(timeout: 5))
        capture(app, name: "report-functional-score-information")
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
