import XCTest

final class PersonalInformationUITests: XCTestCase {
    @MainActor
    func testAgeIsSharedAcrossPlanAndPersonalInformationAndRequirementsUseTextKeyboard() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseMockBackend"]
        app.launch()
        XCTAssertTrue(app.buttons["home.feature.plan"].waitForExistence(timeout: 10))
        app.buttons["home.feature.plan"].tap()
        let ageRow = app.buttons["plan.form.age"]
        reveal(ageRow, in: app)
        ageRow.tap()
        setAge("28", in: app)
        XCTAssertTrue(ageRow.waitForExistence(timeout: 10))
        XCTAssertTrue(ageRow.label.contains("28"), ageRow.label)
        capture(app, "plan-saved-age")

        let requirements = app.textViews["plan.form.requirements"]
        reveal(requirements, in: app)
        requirements.tap()
        requirements.typeText("Keep the routine simple.")
        XCTAssertEqual(requirements.value as? String, "Keep the routine simple.")
        XCTAssertFalse(app.buttons["plan.form.keyboard-done"].exists)
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        capture(app, "requirements-text-keyboard")
        let dismissKeyboard = app.buttons["plan.form.dismiss-keyboard"]
        reveal(dismissKeyboard, in: app)
        dismissKeyboard.tap()
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        app.buttons["返回"].firstMatch.tap()

        app.buttons["app.header.profile"].tap()
        app.buttons["profile.personal-information"].tap()
        let profileAge = app.buttons["personal-information.age"]
        XCTAssertTrue(profileAge.waitForExistence(timeout: 5))
        XCTAssertTrue(profileAge.label.contains("28"), profileAge.label)
        capture(app, "personal-information-age")
        profileAge.tap()
        setAge("31", in: app)
        XCTAssertTrue(profileAge.waitForExistence(timeout: 10))
        XCTAssertTrue(profileAge.label.contains("31"), profileAge.label)
        app.buttons["返回"].firstMatch.tap()
        app.buttons["返回"].firstMatch.tap()
        app.buttons["home.feature.plan"].tap()
        let disclosure = app.buttons["其他个人状态"]
        reveal(disclosure, in: app)
        disclosure.tap()
        reveal(ageRow, in: app)
        XCTAssertTrue(ageRow.label.contains("31"), ageRow.label)
        capture(app, "plan-reuses-profile-age")
    }

    @MainActor
    private func setAge(_ value: String, in app: XCUIApplication) {
        let input = app.textFields["personal-information.age.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        let existing = input.value as? String ?? ""
        input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: Int(existing) == nil ? 0 : existing.count) + value)
        let save = app.buttons["personal-information.age.save"]
        XCTAssertTrue(save.isEnabled)
        save.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: save)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 10), .completed)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<4 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable, app.debugDescription)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
