import XCTest

/// Screenshot inventory only. All app mutations below use the explicit,
/// in-process Mock backend and are discarded when the process exits.
final class MockPageVisualAuditUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        guard ProcessInfo.processInfo.environment["AISKIN_RUN_MOCK_VISUAL"] == "1" else {
            throw XCTSkip("Set AISKIN_RUN_MOCK_VISUAL=1 for the isolated native page screenshot audit")
        }
    }

    @MainActor
    func testReachablePrototypePagesWithExistingMockAccount() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["home.feature.plan"].waitForExistence(timeout: 10))
        capture(app, "01-home")
        app.buttons["home.feature.plan"].tap()
        XCTAssertTrue(app.buttons["plan-preparation.continue"].waitForExistence(timeout: 15))
        capture(app, "10-plan-automatic-prerequisites")
        back(app)
        XCTAssertTrue(app.buttons["plan.form.goal.hydration"].waitForExistence(timeout: 10))
        capture(app, "10-plan-form-before-prerequisites")
        let goalIDs = ["hydration", "repair", "oil-control", "anti-aging", "brightening", "acne"]
        let goals = goalIDs.map { app.buttons["plan.form.goal.\($0)"] }
        let goalWidth = goals[0].frame.width
        for goal in goals {
            XCTAssertEqual(goal.frame.width, goalWidth, accuracy: 1, "Every goal cell must fill an equal grid column")
            XCTAssertGreaterThanOrEqual(goal.frame.height, 44)
        }
        goals[0].tap()
        goals[1].tap()
        XCTAssertTrue(goals[0].isSelected)
        XCTAssertTrue(goals[1].isSelected)
        XCTAssertFalse(goals[2].isSelected)
        capture(app, "10b-plan-goals-two-selected")
        app.buttons["plan.form.prepare"].tap()
        XCTAssertTrue(app.buttons["plan-preparation.continue"].waitForExistence(timeout: 8))
        capture(app, "10a-plan-prerequisites-no-skin-report")
        back(app)
        back(app)

        app.tabButton(1).tap()
        XCTAssertTrue(app.staticTexts["共 5 件"].waitForExistence(timeout: 8))
        capture(app, "02-cabinet-populated")
        app.buttons["cabinet.product.mock-product-cleanser"].tap()
        XCTAssertTrue(app.buttons["ingredient.registration"].waitForExistence(timeout: 10))
        capture(app, "04-ingredient-overview")
        for anchor in ["功效", "成分", "风险", "建议"] {
            reveal(app.buttons[anchor], in: app)
            app.buttons[anchor].tap()
            capture(app, "04-ingredient-\(anchor)")
        }
        app.buttons["ingredient.registration"].tap()
        XCTAssertTrue(app.buttons["ingredient.registration.save"].waitForExistence(timeout: 5))
        capture(app, "04a-ingredient-registration")
        app.buttons["取消"].tap()
        back(app)

        XCTAssertTrue(app.buttons["cabinet.conflict-mode"].waitForExistence(timeout: 5))
        app.buttons["cabinet.conflict-mode"].tap()
        capture(app, "05a-conflict-selection-empty")
        app.buttons["cabinet.product.mock-product-cleanser"].tap()
        app.buttons["cabinet.product.mock-product-serum"].tap()
        capture(app, "05b-conflict-selection-ready")
        app.buttons["cabinet.analyze-conflict"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["conflict.summary"].waitForExistence(timeout: 10))
        capture(app, "05-conflict-report")
        back(app)

        app.tabButton(2).tap()
        XCTAssertTrue(app.buttons["skin.capture.start"].waitForExistence(timeout: 8))
        capture(app, "07-skin-empty")
        app.buttons["app.header.skin-history"].tap()
        XCTAssertTrue(app.staticTexts["暂无检测历史"].waitForExistence(timeout: 5))
        capture(app, "07a-skin-empty-history")
        app.buttons["关闭检测历史"].tap()
        app.buttons["app.header.profile"].tap()
        XCTAssertTrue(app.buttons["profile.account-security"].waitForExistence(timeout: 5))
        capture(app, "09-profile")
        app.buttons["profile.conflict-history"].tap()
        let savedConflict = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "profile.conflict-report.")).firstMatch
        XCTAssertTrue(savedConflict.waitForExistence(timeout: 8))
        capture(app, "15-conflict-history")
        savedConflict.tap()
        XCTAssertTrue(app.descendants(matching: .any)["conflict.summary"].waitForExistence(timeout: 8))
        capture(app, "15a-conflict-history-report")
        back(app)
        back(app)
        app.buttons["profile.account-security"].tap()
        XCTAssertTrue(app.buttons["account-security.terms"].waitForExistence(timeout: 5))
        capture(app, "12-account-security")
        for (document, bodyText) in [
            ("terms", "关于服务能力、AI结果边界、账号责任与使用规则的约定。"),
            ("privacy", "我们希望把数据从哪里来、为什么使用、保存多久，以及如何删除，说得清楚而具体。")
        ] {
            app.buttons["account-security.\(document)"].tap()
            XCTAssertTrue(app.buttons["legal.back"].waitForExistence(timeout: 5))
            let body = app.webViews.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", bodyText)).firstMatch
            XCTAssertTrue(body.waitForExistence(timeout: 15), "The packaged original policy body must be readable")
            XCTAssertEqual(app.webViews.textFields.count, 0)
            XCTAssertFalse(app.webViews.buttons["登录"].exists)
            capture(app, "13-legal-\(document)-native-reader")
            app.buttons["legal.back"].tap()
            XCTAssertTrue(app.buttons["account-security.terms"].waitForExistence(timeout: 5))
        }

        let coverage = XCTAttachment(string: """
        This is a Mock UI screenshot audit, not a real backend/AI acceptance run.
        Captured: Home, populated cabinet, ingredient and registration, conflict report/selection/history,
        empty skin/history, Profile, plan form and prerequisites, account and bundled native legal reader.
        Empty cabinet and login are covered by the other two methods in this class.
        Existing Mock starts with analyses=[] and plans=[]. Filled skin overview/report and plan preview
        are intentionally left to live tests, preserving the skin-report prerequisite and data flow.
        Legal content is the original public-pages HTML packaged by Xcode and read by WKWebView; its text is not mocked.
        """)
        coverage.name = "mock-page-coverage-and-live-boundaries"
        coverage.lifetime = .keepAlways
        add(coverage)
    }

    @MainActor
    func testEmptyCabinetAfterDeletingOnlyInProcessMockProducts() {
        let app = launch()
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
        app.tabButton(1).tap()
        for id in ["cleanser", "serum", "retinol", "acid", "sunscreen"] {
            let product = app.buttons["cabinet.product.mock-product-\(id)"]
            reveal(product, in: app)
            product.tap()
            XCTAssertTrue(app.buttons["ingredient.delete"].waitForExistence(timeout: 8))
            app.buttons["ingredient.delete"].tap()
            app.alerts.buttons["确认删除"].tap()
            XCTAssertTrue(app.buttons["app.header.add-product"].waitForExistence(timeout: 8))
        }
        XCTAssertTrue(app.buttons["cabinet.empty.choose-photo"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["拍一张，就能分析"].exists)
        capture(app, "03-cabinet-empty")
        app.buttons["cabinet.empty.risk"].tap()
        XCTAssertTrue(app.buttons["添加成分表照片"].waitForExistence(timeout: 5))
        capture(app, "03a-cabinet-empty-risk-explanation")
        app.buttons["关闭"].tap()
        XCTAssertTrue(app.buttons["cabinet.add-product"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAppleOnlyLoginScreenshot() {
        let app = launch(resetSession: true)
        XCTAssertTrue(app.buttons["auth.apple-sign-in"].waitForExistence(timeout: 10))
        capture(app, "14-login")
    }

    @MainActor
    private func launch(resetSession: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseMockBackend"]
        if resetSession { app.launchArguments.append("-uiTestingResetSession") }
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "mock"
        app.launch()
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        _ = element.waitForExistence(timeout: 5)
        for _ in 0..<10 {
            if element.exists && element.isHittable { return }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable, app.debugDescription)
    }

    @MainActor
    private func back(_ app: XCUIApplication) {
        let button = app.buttons.matching(identifier: "返回").firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "mock-audit-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
