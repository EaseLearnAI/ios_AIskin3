import XCTest

/// UI-only acceptance against the in-process debug backend. Live service
/// integration is tested separately; no fixture data is sent to production.
final class AIskinUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testLoginOffersOnlyAppleAuthentication() {
        let app = launch(resetSession: true)
        let apple = app.buttons["auth.apple-sign-in"]
        XCTAssertTrue(apple.waitForExistence(timeout: 8))
        XCTAssertTrue(apple.isEnabled)
        XCTAssertFalse(app.buttons["忘记密码？"].exists)
        XCTAssertFalse(app.buttons["获取验证码"].exists)
        XCTAssertEqual(app.textFields.count, 0)
        XCTAssertEqual(app.secureTextFields.count, 0)
        XCTAssertTrue(app.buttons["使用条款"].exists)
        XCTAssertTrue(app.buttons["隐私政策"].exists)
        XCTAssertFalse(app.tabButton(0).exists)
        keepScreenshot(app, name: "final-login")
    }

    @MainActor
    func testLoginReadsBothBundledPoliciesAndReturns() {
        let app = launch(resetSession: true)
        XCTAssertTrue(app.buttons["auth.apple-sign-in"].waitForExistence(timeout: 8))
        for (title, bodyText) in [
            ("使用条款", "关于服务能力、AI结果边界、账号责任与使用规则的约定。"),
            ("隐私政策", "我们希望把数据从哪里来、为什么使用、保存多久，以及如何删除，说得清楚而具体。")
        ] {
            app.buttons[title].tap()
            XCTAssertTrue(app.buttons["legal.back"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.webViews.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", bodyText)).firstMatch.waitForExistence(timeout: 15))
            XCTAssertEqual(app.webViews.textFields.count, 0)
            XCTAssertFalse(app.webViews.buttons["登录"].exists)
            keepScreenshot(app, name: "bundled-\(title)")
            app.buttons["legal.back"].tap()
            XCTAssertTrue(app.buttons["auth.apple-sign-in"].waitForExistence(timeout: 5))
        }
    }

    @MainActor
    func testThreeTabsAndCabinetCategoryFiltering() {
        let app = launch()
        XCTAssertTrue(app.tabButton(0).waitForExistence(timeout: 8))
        XCTAssertTrue(app.tabButton(1).exists)
        XCTAssertTrue(app.tabButton(2).exists)
        XCTAssertFalse(app.tabButton(3).exists)

        app.tabButton(1).tap()
        XCTAssertTrue(app.buttons["cabinet.category.洁面"].waitForExistence(timeout: 5))
        app.buttons["cabinet.category.洁面"].tap()
        XCTAssertTrue(app.staticTexts["共 1 件"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cabinet.product.mock-product-cleanser"].exists)
        XCTAssertFalse(app.buttons["cabinet.product.mock-product-serum"].exists)

        app.buttons["cabinet.category.精华"].tap()
        XCTAssertTrue(app.staticTexts["共 3 件"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cabinet.product.mock-product-serum"].exists)
        XCTAssertFalse(app.buttons["cabinet.product.mock-product-cleanser"].exists)

        app.tabButton(2).tap()
        XCTAssertTrue(app.buttons["skin.capture.start"].waitForExistence(timeout: 5))
        app.tabButton(0).tap()
        XCTAssertTrue(app.buttons["app.header.profile"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPhotoChooserCancellationReturnsToCaptureWithoutAddingProduct() {
        let app = launch()
        openCabinet(app)
        app.buttons["app.header.add-product"].tap()
        let choosePhoto = app.buttons["capture.choose-photo"]
        XCTAssertTrue(choosePhoto.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["cabinet.add.submit"].exists, "The add button must open capture before the product form")
        choosePhoto.tap()

        // PHPicker is a native system sheet and may use the device language.
        let cancelPicker = app.buttons.matching(NSPredicate(format: "NOT (identifier IN %@) AND label IN %@", ["cabinet.add.cancel", "capture.cancel", "DismissImagePickerButton"], ["Cancel", "取消", "Close", "关闭"])).firstMatch
        XCTAssertTrue(cancelPicker.waitForExistence(timeout: 8), app.debugDescription)
        cancelPicker.tap()
        XCTAssertTrue(choosePhoto.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["已选择图片"].exists)
        let cancelDraft = app.buttons["DismissImagePickerButton"].exists
            ? app.buttons["DismissImagePickerButton"] : app.buttons["capture.cancel"]
        XCTAssertTrue(cancelDraft.exists)
        cancelDraft.tap()
        XCTAssertTrue(app.staticTexts["共 5 件"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testConflictSelectionRequiresTwoProductsAndCanBeCancelled() {
        let app = launch()
        openCabinet(app)
        let mode = app.buttons["cabinet.conflict-mode"]
        mode.tap()
        XCTAssertTrue(app.staticTexts["请选择 2 个产品进行冲突检测"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["cabinet.analyze-conflict"].exists)

        let cleanser = app.buttons["cabinet.product.mock-product-cleanser"]
        let serum = app.buttons["cabinet.product.mock-product-serum"]
        cleanser.tap()
        XCTAssertEqual(cleanser.value as? String, "已选择")
        XCTAssertFalse(app.buttons["cabinet.analyze-conflict"].exists)
        serum.tap()
        XCTAssertTrue(app.buttons["cabinet.analyze-conflict"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cabinet.analyze-conflict"].isEnabled)
        mode.tap()
        XCTAssertFalse(app.buttons["cabinet.analyze-conflict"].exists)
        XCTAssertEqual(cleanser.value as? String, "查看成分分析")
    }

    @MainActor
    func testSelectedProductsOpenConflictReport() {
        let app = launch()
        openCabinet(app)
        app.buttons["cabinet.conflict-mode"].tap()
        app.buttons["cabinet.product.mock-product-cleanser"].tap()
        app.buttons["cabinet.product.mock-product-serum"].tap()
        let analyze = app.buttons["cabinet.analyze-conflict"]
        let aboveTabBar = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            analyze.exists && analyze.frame.maxY < app.tabButton(0).frame.minY
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [aboveTabBar], timeout: 3), .completed, "Conflict action must settle above the tab bar")
        analyze.tap()
        XCTAssertTrue(app.descendants(matching: .any)["conflict.summary"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "本次检测产品")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts["温和氨基酸洁面"].exists)
        XCTAssertTrue(app.staticTexts["烟酰胺修护精华"].exists)
        app.buttons.matching(identifier: "返回").firstMatch.tap()
        XCTAssertTrue(app.buttons["cabinet.conflict-mode"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cabinet.product.mock-product-cleanser"].exists)
        XCTAssertFalse(app.buttons["cabinet.analyze-conflict"].exists)
    }

    @MainActor
    func testSkinEntryAndEmptyHistoryCanBeClosed() {
        let app = launch()
        XCTAssertTrue(app.tabButton(2).waitForExistence(timeout: 8))
        app.tabButton(2).tap()
        XCTAssertTrue(app.buttons["skin.capture.start"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["一张照片，"].exists)
        app.buttons["skin.capture.start"].tap()
        let photoSource = app.buttons["从相册上传"]
        XCTAssertTrue(photoSource.waitForExistence(timeout: 5))
        let cancel = app.buttons["取消"]
        if cancel.exists {
            cancel.tap()
        } else {
            // iOS 26 presents this confirmation dialog as a popover. Its
            // native dismissal region replaces the separate cancel button.
            let dismissRegion = app.otherElements["PopoverDismissRegion"]
            XCTAssertTrue(dismissRegion.waitForExistence(timeout: 3), app.debugDescription)
            dismissRegion.tap()
        }
        let sourceClosed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: photoSource)
        XCTAssertEqual(XCTWaiter.wait(for: [sourceClosed], timeout: 5), .completed)
        XCTAssertTrue(app.buttons["skin.capture.start"].isHittable)
        XCTAssertTrue(app.staticTexts["一张照片，"].exists)
        XCTAssertFalse(app.staticTexts["肌肤报告"].exists)
        keepScreenshot(app, name: "skin-capture-cancelled")
        app.buttons["app.header.skin-history"].tap()
        XCTAssertTrue(app.staticTexts["暂无检测历史"].waitForExistence(timeout: 5))
        app.buttons["关闭检测历史"].tap()
        XCTAssertFalse(app.buttons["关闭检测历史"].exists)
        XCTAssertTrue(app.buttons["skin.capture.start"].exists)
    }

    @MainActor
    func testProfileOpensAccountAndConflictHistory() {
        let app = launch()
        XCTAssertTrue(app.buttons["app.header.profile"].waitForExistence(timeout: 8))
        app.buttons["app.header.profile"].tap()
        XCTAssertTrue(app.buttons["profile.account-security"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["profile.skin-history"].exists)
        app.buttons["profile.account-security"].tap()
        XCTAssertTrue(app.buttons["account-security.delete-account"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["account-security.nickname"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["account-security.sign-in-method"].exists)
        XCTAssertTrue(app.buttons["account-security.terms"].exists)
        XCTAssertTrue(app.buttons["account-security.privacy"].exists)
        keepScreenshot(app, name: "final-account-security")
        app.buttons.matching(identifier: "返回").firstMatch.tap()
        XCTAssertTrue(app.buttons["profile.conflict-history"].waitForExistence(timeout: 5))
        app.buttons["profile.conflict-history"].tap()
        XCTAssertTrue(app.staticTexts["还没有冲突检测报告"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["开始新的检测"].exists)
    }

    @MainActor
    private func keepScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func launch(resetSession: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "mock"
        if resetSession { app.launchArguments = ["-uiTestingResetSession"] }
        app.launch()
        return app
    }

    @MainActor
    private func openCabinet(_ app: XCUIApplication) {
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 8))
        app.tabButton(1).tap()
        XCTAssertTrue(app.buttons["cabinet.conflict-mode"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["共 5 件"].exists)
    }
}
