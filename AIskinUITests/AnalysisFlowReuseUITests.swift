import XCTest

/// Native interaction regression against the explicit in-process Mock backend.
/// The first visible system-library photo is a UI fixture only: these tests do
/// not validate image recognition or a live backend. Seed at least one photo in
/// the Simulator library before running; a missing picker asset fails the test.
final class AnalysisFlowReuseUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testUnifiedProcessingPagesFinishBeforeEstimatedCeiling() async throws {
        let app = launchMockApp(latencyMilliseconds: 10000)
        try tap(app.tabButton(1))
        try await chooseProductPhoto(in: app)
        try assertUnifiedWaitingPage(app, title: "成分分析", screenshot: "unified-product-fast-progress")
        XCTAssertTrue(app.descendants(matching: .any)["ingredient.summary"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.descendants(matching: .any)["analysis.processing"].exists)
        try back(app)
        try tap(app.tabButton(2))
        try tap(app.buttons["skin.capture.start"])
        try tap(app.buttons["capture.choose-photo"])
        try selectFirstNativePhoto(in: app)
        try assertUnifiedWaitingPage(app, title: "肌肤检测", screenshot: "unified-skin-fast-progress")
        let reportBack = app.buttons["skin.report.overview"]
        XCTAssertTrue(reportBack.waitForExistence(timeout: 15), "The response must replace loading before estimated progress reaches its ceiling")
        XCTAssertFalse(app.descendants(matching: .any)["analysis.processing"].exists)
        capture(app, "unified-skin-completed")
        try tap(app.buttons["skin.report.retake"])
        try tap(app.buttons["capture.choose-photo"])
        try selectFirstNativePhoto(in: app)
        try assertUnifiedWaitingPage(app, title: "肌肤检测", screenshot: "unified-skin-retake-no-overlay")
        XCTAssertFalse(app.buttons["skin.overview.report"].isHittable)
        try tap(app.buttons["analysis.processing.cancel"])
        XCTAssertTrue(app.buttons["skin.overview.report"].waitForExistence(timeout: 5))
        let noLateReport = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            reportBack.exists || app.descendants(matching: .any)["analysis.processing"].exists
        }, object: nil)
        noLateReport.isInverted = true
        await fulfillment(of: [noLateReport], timeout: 6)
    }

    @MainActor
    func testConflictAndPlanReuseFullPageProcessing() throws {
        let app = launchMockApp(prerequisites: "complete", latencyMilliseconds: 10000)
        try tap(app.tabButton(1))
        try tap(app.buttons["cabinet.conflict-mode"])
        let products = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "cabinet.product."))
        XCTAssertGreaterThanOrEqual(products.count, 2)
        try tap(products.element(boundBy: 0))
        try tap(products.element(boundBy: 1))
        try tap(app.buttons["cabinet.analyze-conflict"])
        try assertUnifiedWaitingPage(app, title: "冲突检测", screenshot: "unified-conflict")
        XCTAssertTrue(app.descendants(matching: .any)["conflict.summary"].waitForExistence(timeout: 15))
        try back(app)
        try tap(app.tabButton(0))
        try tap(app.buttons["home.feature.plan"])
        let goal = app.buttons["plan.form.goal.hydration"]
        XCTAssertTrue(goal.waitForExistence(timeout: 15))
        for _ in 0..<5 where !goal.isHittable { app.swipeUp() }
        try tap(goal)
        let age = app.buttons["plan.form.age"]
        for _ in 0..<5 where !age.isHittable { app.swipeUp() }
        try tap(age)
        let ageInput = app.textFields["personal-information.age.input"]
        try tap(ageInput)
        ageInput.typeText("28")
        try tap(app.buttons["personal-information.age.save"])
        let generate = app.buttons["plan.form.generate"]
        XCTAssertTrue(generate.waitForExistence(timeout: 5))
        XCTAssertTrue(generate.isEnabled)
        try tap(generate)
        try assertUnifiedWaitingPage(app, title: "定制方案", screenshot: "unified-plan")
        XCTAssertTrue(app.buttons["personalized-plan.save"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.descendants(matching: .any)["analysis.processing"].exists)
    }

    @MainActor
    private func assertUnifiedWaitingPage(_ app: XCUIApplication, title: String, screenshot: String) throws {
        let screen = app.descendants(matching: .any)["analysis.processing.screen"]
        XCTAssertTrue(screen.waitForExistence(timeout: 5))
        let panels = app.descendants(matching: .any).matching(identifier: "analysis.processing")
        XCTAssertEqual(panels.count, 1)
        XCTAssertTrue(app.staticTexts[title].exists)
        XCTAssertTrue(app.buttons["analysis.processing.cancel"].isHittable)
        XCTAssertFalse(app.tabButton(0).isHittable, "A full page must cover the old content and Tab Bar")
        let progress = app.descendants(matching: .any)["analysis.processing.estimated-progress"]
        let advanced = NSPredicate { _, _ in
            let value = Int((progress.value as? String ?? "").replacingOccurrences(of: "%", with: "")) ?? 0
            return value >= 50 && value < 98
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: advanced, object: nil)], timeout: 4)
        XCTAssertEqual(result, .completed, "Progress should visibly advance in the opening seconds")
        capture(app, screenshot)
    }

    @MainActor
    func testProductProcessingCanCancelRetryAndSaveWithoutReloadingReport() async throws {
        let app = launchMockApp()
        try tap(app.tabButton(1))
        try await chooseProductPhoto(in: app)

        let processing = app.descendants(matching: .any).matching(identifier: "analysis.processing")
        XCTAssertTrue(processing.firstMatch.waitForExistence(timeout: 5), "Product submission must use the shared processing panel")
        XCTAssertEqual(processing.count, 1, "Show one processing panel for the active job")
        XCTAssertFalse(app.buttons["cabinet.add.submit"].exists, "Selecting a photo must start analysis without another confirmation")
        XCTAssertFalse(app.staticTexts["已选择图片"].exists)
        XCTAssertFalse(app.staticTexts["创建产品"].exists, "The removed page-specific progress checklist must not return")
        capture(app, "product-shared-processing")
        try tap(app.buttons["analysis.processing.cancel"])

        XCTAssertTrue(app.buttons["app.header.add-product"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cabinet.conflict-mode"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["analysis.processing.cancel"].exists)
        let noLateReport = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.buttons["ingredient.registration"].exists ||
            app.staticTexts["成分分析结果"].exists ||
            processing.firstMatch.exists
        }, object: nil)
        noLateReport.isInverted = true
        await fulfillment(of: [noLateReport], timeout: 3.5)
        capture(app, "product-cancelled-without-late-report")

        try await chooseProductPhoto(in: app)
        let registration = app.buttons["ingredient.registration"]
        XCTAssertTrue(registration.waitForExistence(timeout: 15), "A fresh submission after cancellation must open its ingredient report")
        XCTAssertTrue(app.staticTexts["AI 识别修护精华"].exists, "The new Mock analysis result must be shown")
        XCTAssertFalse(app.buttons["analysis.processing.cancel"].exists)
        XCTAssertFalse(processing.firstMatch.exists)
        capture(app, "product-retry-completed-report")

        try tap(registration)
        let save = app.buttons["ingredient.registration.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        let category = app.buttons["ingredient.registration.category.精华"]
        try tap(category)
        XCTAssertTrue(category.isSelected)
        // This checks the visible report lifecycle; store unit tests separately
        // verify that registration saving does not request analysis again.
        let noReportReload = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            processing.firstMatch.exists
        }, object: nil)
        noReportReload.isInverted = true
        save.tap()
        await fulfillment(of: [noReportReload], timeout: 3)
        XCTAssertFalse(save.exists, "Successful registration must dismiss the editor")
        XCTAssertTrue(registration.exists && registration.isHittable)
        XCTAssertTrue(app.staticTexts["AI 识别修护精华"].exists)
        capture(app, "product-registration-preserves-loaded-report")

        try tap(registration)
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(category.isSelected, "Reopening the editor must retain the saved classification")
        try tap(app.buttons["取消"])
    }

    @MainActor
    func testSkinReportRestoresPhotoPinsAndScrollsAllObservationDetails() throws {
        let app = launchMockApp(prerequisites: "complete")
        try tap(app.tabButton(2))
        try tap(app.buttons["skin.overview.report"])
        XCTAssertTrue(app.staticTexts["肌肤报告"].waitForExistence(timeout: 10))
        capture(app, "skin-restored-photo-pins")
        try assertCompleteSkinReport(in: app)
    }

    @MainActor
    private func assertCompleteSkinReport(in app: XCUIApplication) throws {
        let issuesTab = app.buttons["肌肤问题"]
        let overviewTab = app.buttons["肤况概览"]
        XCTAssertLessThan(issuesTab.frame.minX, overviewTab.frame.minX)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "skin.report.pin.")).count, 3)
        let firstPin = app.buttons["skin.report.pin.redness"]
        XCTAssertLessThan(firstPin.staticTexts["泛红"].frame.maxX, firstPin.staticTexts["轻度"].frame.minX)
        XCTAssertEqual(firstPin.staticTexts["泛红"].frame.midY, firstPin.staticTexts["轻度"].frame.midY, accuracy: 1)
        XCTAssertTrue(app.staticTexts["本次有 5 项需要关注"].exists)
        let observations = app.scrollViews["skin.report.observations"]
        app.showSkinObservationList()
        XCTAssertLessThanOrEqual(observations.frame.height, 261)
        XCTAssertFalse(app.buttons["全部观察"].exists)
        let initialFrame = observations.frame
        for id in ["redness", "pores", "acne", "blackheads", "hyperpigmentation", "fineLines", "sensitivity", "skinToneEvenness", "assessment.肤质判断依据"] {
            _ = app.revealSkinObservation(id)
            if id == "blackheads" { capture(app, "skin-other-issues-with-summary-and-detail") }
        }
        XCTAssertEqual(observations.frame.minY, initialFrame.minY, accuracy: 1, "Inner scrolling must leave the report position unchanged")
        capture(app, "skin-all-observations-scrolled")
        try tap(issuesTab)
        try tap(app.buttons["skin.report.pin.acne"])
        XCTAssertTrue(observations.frame.contains(app.staticTexts["skin.report.summary.acne"].frame), "A photo label must locate its entry in the full detail list: viewport=\(observations.frame), summary=\(app.staticTexts["skin.report.summary.acne"].frame)")
        try tap(overviewTab)
        XCTAssertTrue(app.buttons["skin.summary.score-info"].isHittable)
        try tap(issuesTab)
    }

    @MainActor
    func testSkinCaptureHistoryAndPlanSourceReuseTheRetakeEntry() async throws {
        let app = launchMockApp()
        try tap(app.tabButton(2))
        try tap(app.buttons["skin.capture.start"])
        try tap(app.buttons["capture.choose-photo"])
        try selectFirstNativePhoto(in: app)

        let processing = app.descendants(matching: .any).matching(identifier: "analysis.processing")
        XCTAssertTrue(processing.firstMatch.waitForExistence(timeout: 5), "Skin analysis must use the same processing component as product analysis")
        XCTAssertEqual(processing.count, 1)
        capture(app, "skin-shared-processing")
        let reportBack = app.buttons["skin.report.overview"]
        XCTAssertTrue(reportBack.waitForExistence(timeout: 15), "Selecting the photo must generate the in-process Mock report")
        XCTAssertTrue(app.staticTexts["肌肤报告"].exists)
        XCTAssertFalse(processing.firstMatch.exists)
        capture(app, "skin-generated-mock-report")
        try assertCompleteSkinReport(in: app)
        try tap(app.buttons["skin.report.retake"])
        try assertCaptureEntry(in: app, screenshot: "skin-main-report-retake")
        try cancelNativeCapture(in: app)
        XCTAssertTrue(app.buttons["skin.overview.report"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["skin.capture.start"].exists)
        XCTAssertFalse(app.buttons["skin.capture.overview"].exists)
        try tap(app.buttons["skin.overview.capture"])
        try assertCaptureEntry(in: app, screenshot: "skin-overview-retake")
        try cancelNativeCapture(in: app)
        XCTAssertTrue(app.buttons["skin.overview.report"].waitForExistence(timeout: 5))
        try tap(app.buttons["skin.overview.report"])
        try tap(app.buttons["skin-analysis.customize-plan"])
        XCTAssertTrue(app.buttons["plan.form.goal.hydration"].waitForExistence(timeout: 10), "A full-screen skin report must dismiss before pushing the plan form")
        XCTAssertTrue(app.buttons["plan.form.generate"].waitForExistence(timeout: 15), "Existing report and products must allow first-time creation without confirmations")
        XCTAssertFalse(app.buttons["plan.form.prepare"].exists)
        XCTAssertFalse(app.buttons["plan-preparation.continue"].exists)
        try back(app)
        XCTAssertTrue(app.tabButton(2).isHittable)
        XCTAssertTrue(app.tabButton(2).isSelected)
        try tap(app.buttons["skin.overview.report"])
        try tap(reportBack)

        try tap(app.buttons["app.header.profile"])
        try tap(app.buttons["profile.skin-history"])
        let historyRows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "profile.skin-report."))
        XCTAssertTrue(historyRows.firstMatch.waitForExistence(timeout: 10), "The analysis created through the native picker must appear in history")
        XCTAssertEqual(historyRows.count, 1, "A fresh Mock process starts without skin analyses")
        let savedReportID = historyRows.firstMatch.identifier
        try tap(historyRows.firstMatch)
        XCTAssertTrue(reportBack.waitForExistence(timeout: 5))
        try tap(app.buttons["skin.report.retake"])
        try assertCaptureEntry(in: app, screenshot: "skin-profile-history-retake-entry")
        try cancelNativeCapture(in: app)
        XCTAssertTrue(app.buttons["skin.overview.report"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["skin.capture.start"].exists)

        try back(app)
        XCTAssertTrue(app.buttons[savedReportID].waitForExistence(timeout: 5), "Leaving retake must return to the saved history row")
        try back(app)
        try tap(app.buttons["profile.back"])
        try tap(app.tabButton(0))
        try tap(app.buttons["home.feature.plan"])
        XCTAssertTrue(app.buttons["查看"].waitForExistence(timeout: 10), "The plan form must expose the report created earlier in this same Mock process")
        try tap(app.buttons["查看"])
        XCTAssertTrue(reportBack.waitForExistence(timeout: 10))
        try tap(app.buttons["skin.report.retake"])
        try assertCaptureEntry(in: app, screenshot: "skin-plan-source-retake-entry")
        try cancelNativeCapture(in: app)
        XCTAssertTrue(app.buttons["skin.overview.report"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["skin.capture.start"].exists)
    }

    @MainActor
    func testMissingReportOnlyGuidesSkinWithExistingProducts() throws {
        let app = launchMockApp()
        try tap(app.buttons["home.feature.plan"])
        // Entering the plan must automatically present the missing-data guide.
        let next = app.buttons["plan-preparation.continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertEqual(next.label, "开始肌肤检测")
        XCTAssertTrue(app.staticTexts["已有 5 件已分析护肤品，可直接使用。"].exists)
        XCTAssertFalse(app.buttons["plan.form.generate"].exists)
        capture(app, "plan-only-missing-skin")
    }

    @MainActor
    func testEmptyAccountAutomaticallyOpensPreparationOnEveryPlanEntry() throws {
        let app = launchMockApp(prerequisites: "empty")
        for entry in 1...2 {
            try tap(app.buttons["home.feature.plan"])
            let next = app.buttons["plan-preparation.continue"]
            XCTAssertTrue(next.waitForExistence(timeout: 15))
            XCTAssertEqual(next.label, "开始肌肤检测")
            XCTAssertTrue(app.staticTexts["至少添加 2 件并完成成分分析，已有 0 件，还差 2 件。"].exists)
            XCTAssertFalse(app.buttons["plan.form.generate"].exists)
            capture(app, "empty-account-automatic-guide-\(entry)")
            try back(app)
            XCTAssertTrue(app.buttons["plan.form.prepare"].waitForExistence(timeout: 5))
            try back(app)
        }
    }

    @MainActor
    func testReportWithoutProductsAutomaticallyGuidesProductAddition() throws {
        let app = launchMockApp(prerequisites: "report-only")
        try tap(app.buttons["home.feature.plan"])
        let next = app.buttons["plan-preparation.continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        XCTAssertEqual(next.label, "添加我的护肤品")
        XCTAssertTrue(app.staticTexts["已有肌肤报告，可直接用于定制。"].exists)
        XCTAssertFalse(app.buttons["plan.form.generate"].exists)
        capture(app, "report-only-automatic-guide")
    }

    @MainActor
    func testPreparationRequiresTwoAnalyzedProductsBeforeContinuing() throws {
        let app = launchMockApp(prerequisites: "report-only", latencyMilliseconds: 900)
        try tap(app.buttons["home.feature.plan"])
        try tap(app.buttons["plan-preparation.continue"])
        let finish = app.buttons["plan-preparation.activity.continue"]
        XCTAssertTrue(finish.waitForExistence(timeout: 10))
        XCTAssertFalse(finish.isEnabled)
        XCTAssertEqual(finish.label, "还需添加并分析 2 件护肤品")
        let upload = app.buttons["cabinet.empty.choose-photo"]
        XCTAssertTrue(upload.waitForExistence(timeout: 10))
        for _ in 0..<4 where !upload.isHittable { app.swipeUp() }
        try tap(upload)
        try selectFirstNativePhoto(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["ingredient.summary"].waitForExistence(timeout: 20))
        try backFromPreparationActivity(app)
        XCTAssertTrue(finish.waitForExistence(timeout: 10))
        XCTAssertFalse(finish.isEnabled)
        XCTAssertEqual(finish.label, "还需添加并分析 1 件护肤品")
        capture(app, "one-product-cannot-complete-step-two")
        // Returning through the back button must also keep the plan gate closed.
        try backFromPreparationActivity(app)
        let next = app.buttons["plan-preparation.continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertEqual(next.label, "继续添加护肤品（还差 1 件）")
        XCTAssertFalse(app.buttons["plan.form.generate"].exists)
        try tap(next)
        let add = app.buttons["app.header.plus"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        try tap(add)
        try tap(app.buttons["capture.choose-photo"])
        try selectFirstNativePhoto(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["ingredient.summary"].waitForExistence(timeout: 20))
        try backFromPreparationActivity(app)
        let enabled = NSPredicate { _, _ in finish.exists && finish.isEnabled }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: enabled, object: nil)], timeout: 10), .completed)
        XCTAssertEqual(finish.label, "完成第二步，继续")
        capture(app, "two-products-can-complete-step-two")
        try tap(finish)
        XCTAssertTrue(app.buttons["plan.form.generate"].waitForExistence(timeout: 15))
        XCTAssertFalse(next.exists)
    }

    @MainActor
    func testReportAndProductsSkipPreparationOnFirstPlanEntry() throws {
        let app = launchMockApp(prerequisites: "complete")
        try tap(app.buttons["home.feature.plan"])
        XCTAssertTrue(app.buttons["plan.form.generate"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["plan-preparation.continue"].exists)
        XCTAssertFalse(app.buttons["plan.form.prepare"].exists)
        capture(app, "complete-data-first-plan-entry")
    }

    @MainActor
    private func backFromPreparationActivity(_ app: XCUIApplication) throws {
        let buttons = app.buttons.matching(NSPredicate(format: "label == %@", "返回"))
        let visible = NSPredicate { _, _ in buttons.allElementsBoundByIndex.contains { $0.isHittable } }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: visible, object: nil)], timeout: 10), .completed)
        guard let back = buttons.allElementsBoundByIndex.first(where: { $0.isHittable }) else {
            throw FlowNavigationError.missingControl
        }
        try tap(back)
    }

    @MainActor
    private func launchMockApp(prerequisites: String? = nil, latencyMilliseconds: Int = 5000) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseMockBackend"]
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "mock"
        app.launchEnvironment["AISKIN_MOCK_ANALYSIS_LATENCY_MS"] = String(latencyMilliseconds)
        app.launchEnvironment["AISKIN_MOCK_PLAN_PREREQUISITES"] = prerequisites
        app.launch()
        XCTAssertTrue(app.tabButton(0).waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    private func chooseProductPhoto(in app: XCUIApplication) async throws {
        try tap(app.buttons["app.header.add-product"])
        try tap(app.buttons["capture.choose-photo"])
        try selectFirstNativePhoto(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["analysis.processing"].waitForExistence(timeout: 10),
                      "Selecting a native photo must start product analysis automatically")
        XCTAssertFalse(app.buttons["cabinet.add.submit"].exists)
        XCTAssertFalse(app.staticTexts["已选择图片"].exists)
    }

    @MainActor
    private func selectFirstNativePhoto(in app: XCUIApplication) throws {
        let nativeCancel = app.buttons.matching(NSPredicate(
            format: "NOT (identifier IN %@) AND label IN %@", ["analysis.processing.cancel", "capture.cancel", "DismissImagePickerButton"], ["Cancel", "取消", "Close", "关闭"]
        )).firstMatch
        XCTAssertTrue(nativeCancel.waitForExistence(timeout: 10), "The native photo picker must be presented")
        let thumbnails = app.images.matching(identifier: "PXGGridLayout-Info")
        guard thumbnails.firstMatch.waitForExistence(timeout: 30) else {
            recordPickerFailure(app, message: "No native photo thumbnail was available. Seed a Simulator photo before running this Mock UI regression.")
            throw FlowNavigationError.missingPhoto
        }
        guard let firstVisible = thumbnails.allElementsBoundByIndex.first(where: {
            !$0.frame.isEmpty && app.frame.contains($0.frame)
        }) else {
            recordPickerFailure(app, message: "The native picker exposed no fully visible thumbnail frame; refusing a guessed coordinate tap.")
            throw FlowNavigationError.missingPhoto
        }
        // The native picker's virtual image is not marked hittable. Its real,
        // observed accessibility frame determines this coordinate tap.
        firstVisible.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    @MainActor
    private func assertCaptureEntry(in app: XCUIApplication, screenshot: String) throws {
        // Both the native camera and the permission fallback expose the shared album entry.
        XCTAssertTrue(app.buttons["capture.choose-photo"].waitForExistence(timeout: 10),
                      "One retake tap must open capture without an intermediate welcome page")
        XCTAssertTrue(app.buttons["DismissImagePickerButton"].exists || app.buttons["capture.cancel"].exists)
        XCTAssertFalse(app.buttons["skin.capture.start"].exists)
        XCTAssertFalse(app.buttons["skin.capture.overview"].exists)
        XCTAssertFalse(app.buttons["拍照检测"].exists)
        capture(app, screenshot)
    }

    @MainActor
    private func cancelNativeCapture(in app: XCUIApplication) throws {
        let nativeClose = app.buttons["DismissImagePickerButton"]
        try tap(nativeClose.exists ? nativeClose : app.buttons["capture.cancel"])
    }

    @MainActor
    private func tap(_ element: XCUIElement) throws {
        guard element.waitForExistence(timeout: 10), element.isHittable else {
            XCTFail("Expected a visible, tappable control: \(element.identifier)")
            throw FlowNavigationError.missingControl
        }
        element.tap()
    }

    @MainActor
    private func back(_ app: XCUIApplication) throws {
        try tap(app.buttons.matching(identifier: "返回").firstMatch)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "mock-analysis-reuse-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func recordPickerFailure(_ app: XCUIApplication, message: String) {
        capture(app, "native-picker-failure")
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "Native picker accessibility tree"
        tree.lifetime = .keepAlways
        add(tree)
        XCTFail(message)
    }

    private enum FlowNavigationError: Error {
        case missingControl, missingPhoto
    }
}
