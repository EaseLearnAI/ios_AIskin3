import XCTest

/// Exercises native sheets with disposable in-process Mock data, not live AI.
final class IngredientInteractionUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testCabinetMoreEditsProductWithoutOpeningReport() {
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseMockBackend"]
        app.launch()
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
        app.tabButton(1).tap()
        let more = app.buttons["cabinet.more.mock-product-cleanser"]
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        more.tap()
        app.buttons["编辑产品"].tap()
        let name = app.textFields["ingredient.registration.name"]
        let save = app.buttons["ingredient.registration.save"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        let originalName = name.value as? String
        XCTAssertFalse(app.buttons["ingredient.registration"].exists)
        replaceName(name, with: "Cancelled cabinet draft")
        name.typeText("\n")
        app.buttons["取消"].tap()
        waitUntilGone(save)
        more.tap()
        app.buttons["编辑产品"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, originalName)
        replaceName(name, with: "Cabinet edited serum")
        name.typeText("\n")
        app.buttons["ingredient.registration.category.精华"].tap()
        capture(app, "cabinet-edit-form")
        save.tap()
        waitUntilGone(save)
        let row = app.buttons["cabinet.product.mock-product-cleanser"]
        let updated = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "Cabinet edited serum"), object: row
        )
        XCTAssertEqual(XCTWaiter.wait(for: [updated], timeout: 8), .completed)
        app.buttons["cabinet.category.精华"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        more.tap()
        app.buttons["编辑产品"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "Cabinet edited serum")
        XCTAssertTrue(app.buttons["ingredient.registration.category.精华"].isSelected)
        app.buttons["取消"].tap()
        capture(app, "cabinet-edited-list")
    }

    @MainActor
    func testActionsRegistrationDatesAndDeleteCancellation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseMockBackend"]
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "mock"
        app.launch()
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
        app.tabButton(1).tap()
        let product = app.buttons["cabinet.product.mock-product-cleanser"]
        XCTAssertTrue(product.waitForExistence(timeout: 10))
        product.tap()
        let registration = app.buttons["ingredient.registration"]
        XCTAssertTrue(registration.waitForExistence(timeout: 8))
        let more = app.buttons["app.header.ellipsis"]
        more.tap()
        let edit = app.buttons["ingredient.actions.edit"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(edit.frame.minY, app.frame.height / 2)
        capture(app, "01-product-actions")
        edit.tap()
        let save = app.buttons["ingredient.registration.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        let name = app.textFields["ingredient.registration.name"]
        XCTAssertTrue(name.isHittable)
        let originalName = name.value as? String ?? ""
        XCTAssertFalse(originalName.isEmpty)
        capture(app, "02-save-sheet")
        for name in ["洁面", "精华", "面膜", "防晒", "面霜", "爽肤水", "乳液", "眼霜", "其他"] {
            let category = app.buttons["ingredient.registration.category.\(name)"]
            XCTAssertTrue(category.isHittable, "The entire category grid should be visible")
            let fullTapArea = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in category.frame.height >= 43.99 }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [fullTapArea], timeout: 3), .completed)
        }
        replaceName(name, with: "Cancelled draft")
        name.typeText("\n")
        app.buttons["ingredient.registration.category.眼霜"].tap()
        app.buttons["取消"].tap()
        XCTAssertTrue(registration.waitForExistence(timeout: 5))
        registration.tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["ingredient.registration.category.眼霜"].isSelected, "Cancel must discard the edit")
        XCTAssertEqual(name.value as? String, originalName, "Cancel must discard the name edit")
        replaceName(name, with: "   ")
        name.typeText("\n")
        save.tap()
        XCTAssertTrue(app.staticTexts["照片未识别到名称时，可以在这里手动填写。"].waitForExistence(timeout: 3))
        replaceName(name, with: "My daily serum")
        name.typeText("\n")
        let date = app.buttons["ingredient.registration.record-opening"]
        let previousDate = date.value as? String
        app.descendants(matching: .any).matching(identifier: "ingredient.registration.unopened").firstMatch.tap()
        XCTAssertFalse(date.isEnabled)
        app.descendants(matching: .any).matching(identifier: "ingredient.registration.unopened").firstMatch.tap()
        XCTAssertEqual(date.value as? String, previousDate, "Toggling unopened must not invent today's date")
        date.tap()
        XCTAssertTrue(app.buttons["ingredient.registration.confirm-date"].waitForExistence(timeout: 5))
        capture(app, "03-calendar")
        app.buttons["取消日期选择"].tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertEqual(date.value as? String, previousDate, "Cancel must discard pending calendar selection")
        date.tap()
        app.buttons["ingredient.registration.confirm-date"].tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertNotEqual(date.value as? String, "未记录")
        app.buttons["ingredient.registration.category.眼霜"].tap()
        app.descendants(matching: .any).matching(identifier: "ingredient.registration.unopened").firstMatch.tap()
        capture(app, "04-unopened-and-category")
        save.tap()
        waitUntilGone(save)
        XCTAssertTrue(registration.exists)
        registration.tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ingredient.registration.category.眼霜"].isSelected)
        XCTAssertFalse(date.isEnabled)
        XCTAssertEqual(name.value as? String, "My daily serum")
        capture(app, "05-reopened-saved-state")
        app.buttons["取消"].tap()
        more.tap()
        app.buttons["ingredient.actions.pair"].tap()
        XCTAssertTrue(app.staticTexts["选择检测产品"].waitForExistence(timeout: 5))
        let selected = app.buttons.matching(identifier: "cabinet.product.mock-product-cleanser").firstMatch
        XCTAssertTrue(selected.waitForExistence(timeout: 8))
        XCTAssertEqual(selected.value as? String, "已选择")
        capture(app, "06-pairing-preselected")
        app.buttons["返回"].firstMatch.tap()
        XCTAssertTrue(registration.waitForExistence(timeout: 5))
        more.tap()
        app.buttons["ingredient.actions.delete"].tap()
        XCTAssertTrue(app.alerts["确认删除"].waitForExistence(timeout: 5))
        capture(app, "07-delete-confirmation")
        app.alerts.buttons["取消"].tap()
        XCTAssertTrue(registration.isHittable)
        app.buttons["ingredient.delete"].tap()
        XCTAssertTrue(app.alerts["确认删除"].waitForExistence(timeout: 5))
        app.alerts.buttons["取消"].tap()
        XCTAssertTrue(registration.isHittable)
    }

    @MainActor
    func testAccountConfirmationsCanCancelAtTheirOwnEntry() {
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseMockBackend"]
        app.launch()
        XCTAssertTrue(app.buttons["app.header.profile"].waitForExistence(timeout: 10))
        app.buttons["app.header.profile"].tap()
        let logout = app.buttons["profile.logout"]
        reveal(logout, in: app)
        logout.tap()
        XCTAssertTrue(app.alerts["退出登录"].waitForExistence(timeout: 5))
        app.alerts.buttons["取消"].tap()
        app.buttons["profile.account-security"].tap()
        let delete = app.buttons["account-security.delete-account"]
        reveal(delete, in: app)
        delete.tap()
        XCTAssertTrue(app.alerts["注销账户"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts.buttons["确定注销"].exists, "The account screen must own its confirmation")
        capture(app, "08-account-delete-cancel-only")
        app.alerts.buttons["取消"].tap()
        XCTAssertTrue(delete.isHittable)
    }

    @MainActor
    func testExistingSkinContextAndPlanHistoryCanCancelWithoutSaving() throws {
        guard ProcessInfo.processInfo.environment["AISKIN_RUN_LIVE_UI"] == "1" else {
            throw XCTSkip("Requires the existing local read-only session")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseLiveBackend", "-AISkinUITestSession"]
        app.launchEnvironment["AISKIN_UI_TEST_SESSION_FILE"] = "/tmp/aiskin-ui-test-session.json"
        app.launch()
        XCTAssertTrue(app.buttons["护肤方案历史"].waitForExistence(timeout: 10))
        app.buttons["护肤方案历史"].tap()
        XCTAssertTrue(app.navigationBars["护肤方案历史"].waitForExistence(timeout: 5))
        capture(app, "09-plan-history")
        app.buttons["完成"].tap()
        app.tabButton(2).tap()
        let report = app.buttons["skin.overview.report"]
        reveal(report, in: app)
        report.tap()
        XCTAssertTrue(app.buttons["前后对比"].waitForExistence(timeout: 10))
        app.buttons["前后对比"].tap()
        let information = app.buttons.matching(NSPredicate(format: "label == %@", "本次记录信息")).firstMatch
        reveal(information, in: app)
        information.tap()
        let context = app.buttons["skin.context.open"]
        reveal(context, in: app)
        context.tap()
        let none = app.buttons["skin.context.feeling.无明显不适"]
        reveal(none, in: app)
        if !none.isSelected { none.tap() }
        XCTAssertTrue(none.isSelected)
        let sting = app.buttons["skin.context.feeling.刺痛"]
        XCTAssertFalse(sting.isSelected)
        sting.tap()
        XCTAssertFalse(none.isSelected)
        XCTAssertTrue(sting.isSelected)
        capture(app, "10-context-mutually-exclusive-feelings")
        app.buttons["取消"].tap()
        XCTAssertTrue(context.waitForExistence(timeout: 5))
    }

    @MainActor
    private func replaceName(_ field: XCUIElement, with text: String) {
        field.tap()
        let current = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + text)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        _ = element.waitForExistence(timeout: 8)
        for _ in 0..<10 {
            if element.exists && element.isHittable { return }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func waitUntilGone(_ element: XCUIElement) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 8), .completed)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "interaction-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
