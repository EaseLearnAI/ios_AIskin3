import XCTest

final class OnboardingUITests: XCTestCase {
    @MainActor
    func testAutoAdvanceWrapsAndPausesForLegalDocument() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseMockBackend", "-AISkinShowLogin"]
        app.launch()
        let second = app.buttons["onboarding.page.1"]
        XCTAssertTrue(second.waitForExistence(timeout: 10))
        let selected = NSPredicate(format: "isSelected == true")
        let autoSecond = XCTNSPredicateExpectation(predicate: selected, object: second)
        let secondResult = XCTWaiter.wait(for: [autoSecond], timeout: 8)
        capture(app, "auto-second-page")
        XCTAssertEqual(secondResult, .completed, app.debugDescription)
        app.buttons["onboarding.page.2"].tap()
        let third = app.buttons["onboarding.page.2"]
        app.buttons["auth.legal.privacy"].tap()
        XCTAssertTrue(app.buttons["legal.back"].waitForExistence(timeout: 5))
        // Keep the document open beyond one interval; it must retain page 3.
        let delay = expectation(description: "Read privacy document")
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { delay.fulfill() }
        waitForExpectations(timeout: 7)
        app.buttons["legal.back"].tap()
        XCTAssertTrue(third.waitForExistence(timeout: 5))
        XCTAssertTrue(third.isSelected)
        let autoFirst = XCTNSPredicateExpectation(predicate: selected, object: app.buttons["onboarding.page.0"])
        let firstResult = XCTWaiter.wait(for: [autoFirst], timeout: 8)
        capture(app, "auto-resumed-first-page")
        XCTAssertEqual(firstResult, .completed, app.debugDescription)
    }

    @MainActor
    func testThreePagesSwipePaginationAndLegalReturn() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseMockBackend", "-AISkinShowLogin"]
        app.launch()
        let signIn = app.buttons["auth.apple-sign-in"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["01"].exists)
        capture(app, "onboarding-01")
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["02"].waitForExistence(timeout: 5))
        capture(app, "onboarding-02")
        app.buttons["onboarding.page.2"].tap()
        XCTAssertTrue(app.staticTexts["03"].waitForExistence(timeout: 5))
        XCTAssertTrue(signIn.isHittable)
        capture(app, "onboarding-03")
        app.buttons["auth.legal.privacy"].tap()
        let back = app.buttons["legal.back"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 5))
        back.tap()
        XCTAssertTrue(signIn.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["03"].exists)
        app.buttons["auth.legal.terms"].tap()
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        app.buttons["onboarding.page.0"].tap()
        XCTAssertTrue(app.staticTexts["01"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onboarding.page.3"].exists)
    }

    @MainActor
    func testAuthenticatedPreviewRetainsSessionAndReturnsHome() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseMockBackend", "-AISkinPreviewOnboarding"]
        app.launch()
        let enter = app.buttons["onboarding.continue-session"]
        XCTAssertTrue(enter.waitForExistence(timeout: 10))
        enter.tap()
        XCTAssertTrue(app.buttons["home.feature.plan"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["-AISkinUseMockBackend"]
        app.launch()
        XCTAssertTrue(app.buttons["home.feature.plan"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["onboarding.page.0"].exists)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
