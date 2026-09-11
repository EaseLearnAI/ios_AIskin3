import XCTest

final class NativeTabInteractionUITests: XCTestCase {
    @MainActor
    func testSystemTabBarSwitchesAndRestoresAfterNavigation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "mock"
        app.launch()

        XCTAssertTrue(app.tabButton(0).waitForExistence(timeout: 10))
        XCTAssertEqual(app.tabBars.count, 1)
        XCTAssertEqual(app.tabBars.buttons.count, 3)
        XCTAssertTrue(app.tabButton(0).isSelected)
        capture(app, "native-tabs-home")
        for index in [1, 2, 0, 2, 1, 0] {
            app.tabButton(index).tap()
            let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "selected == true"), object: app.tabButton(index))
            XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed)
            for other in 0...2 where other != index {
                XCTAssertFalse(app.tabButton(other).isSelected)
            }
            XCTAssertEqual(app.tabBars.count, 1)
        }

        app.buttons["home.feature.plan"].tap()
        XCTAssertTrue(app.buttons["plan.form.goal.hydration"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.tabButton(0).isHittable)
        app.buttons["返回"].firstMatch.tap()
        XCTAssertTrue(app.tabButton(0).waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabButton(0).isHittable)

        app.buttons["home.feature.products"].tap()
        XCTAssertTrue(app.buttons["cabinet.conflict-mode"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabButton(1).isSelected)
        capture(app, "native-tabs-cabinet")

        app.tabButton(0).tap()
        app.buttons["home.feature.conflicts"].tap()
        let conflictMode = app.buttons["cabinet.conflict-mode"]
        assertLabel("取消检测", on: conflictMode)
        XCTAssertTrue(app.tabButton(1).isSelected)
        app.buttons["cabinet.product.mock-product-cleanser"].tap()
        app.buttons["cabinet.product.mock-product-serum"].tap()
        let analyze = app.buttons["cabinet.analyze-conflict"]
        XCTAssertTrue(analyze.waitForExistence(timeout: 5))
        XCTAssertTrue(analyze.isHittable)
        XCTAssertLessThanOrEqual(analyze.frame.maxY, app.tabBars.firstMatch.frame.minY)
        capture(app, "native-tabs-conflict-action-safe-area")
        conflictMode.tap()
        assertLabel("冲突检测", on: conflictMode)
        XCTAssertFalse(analyze.exists)

        // Consuming the launch request must allow the same home entry again.
        app.tabButton(0).tap()
        app.buttons["home.feature.conflicts"].tap()
        assertLabel("取消检测", on: conflictMode)
        XCTAssertTrue(app.staticTexts["已选 0 件"].exists)
        XCTAssertFalse(analyze.exists)
        app.buttons["cabinet.product.mock-product-cleanser"].tap()

        // A library entry clears selection mode in the existing product screen.
        app.tabButton(0).tap()
        app.buttons["home.feature.products"].tap()
        assertLabel("冲突检测", on: conflictMode)
        XCTAssertEqual(app.buttons["cabinet.product.mock-product-cleanser"].value as? String, "查看成分分析")

        // Header capture is another consumed entry; cancel returns to the cabinet.
        app.buttons["cabinet.category.精华"].tap()
        XCTAssertTrue(app.staticTexts["共 3 件"].waitForExistence(timeout: 5))
        for _ in 0..<2 {
            app.buttons["app.header.add-product"].tap()
            XCTAssertTrue(app.buttons["capture.choose-photo"].waitForExistence(timeout: 5))
            let cancel = app.buttons["DismissImagePickerButton"].exists
                ? app.buttons["DismissImagePickerButton"] : app.buttons["capture.cancel"]
            XCTAssertTrue(cancel.exists)
            cancel.tap()
            XCTAssertTrue(conflictMode.waitForExistence(timeout: 5))
            XCTAssertTrue(app.tabButton(1).isSelected)
            XCTAssertTrue(app.tabButton(1).isHittable)
            XCTAssertFalse(cancel.exists)
            XCTAssertTrue(app.staticTexts["共 3 件"].waitForExistence(timeout: 5),
                          "Opening capture must preserve the cabinet store and its active category")
            XCTAssertFalse(app.buttons["cabinet.product.mock-product-cleanser"].exists)
        }
        capture(app, "native-tabs-cabinet-after-entry-cancellation")

        app.tabButton(0).tap()
        app.buttons["home.feature.skin"].tap()
        XCTAssertTrue(app.tabButton(2).isSelected)
        XCTAssertTrue(app.buttons["skin.capture.start"].waitForExistence(timeout: 5))
        capture(app, "native-tabs-skin")
        app.buttons["app.header.profile"].tap()
        XCTAssertTrue(app.buttons["profile.account-security"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabButton(2).isHittable)
        app.buttons["返回"].firstMatch.tap()
        XCTAssertTrue(app.tabButton(2).waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabButton(2).isSelected)
        XCTAssertTrue(app.tabButton(2).isHittable)
    }

    @MainActor
    private func assertLabel(_ label: String, on element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let expectedLabel = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectedLabel], timeout: 5), .completed, file: file, line: line)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
