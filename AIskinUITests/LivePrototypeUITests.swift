import XCTest

/// Opt-in tests of native UI against the real local backend and a dedicated
/// test-account session. No mocked HTTP responses or production endpoints.
final class LivePrototypeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        guard ProcessInfo.processInfo.environment["AISKIN_RUN_LIVE_UI"] == "1" else {
            throw XCTSkip("Set AISKIN_RUN_LIVE_UI=1 to run the local live-account UI checks")
        }
    }

    @MainActor
    func testExistingPrerequisitesOpenPlanFormWithoutConfirmation() async throws {
        let session = try LiveSession()
        let history = try await session.get("/skin-analysis?page=1&limit=1")
        let analyses = try XCTUnwrap((history["data"] as? [String: Any])?["analyses"] as? [[String: Any]])
        XCTAssertFalse(analyses.isEmpty, "This live fixture must already have a skin report")
        let response = try await session.get("/products/user/\(session.userID)")
        let products = try XCTUnwrap((response["data"] as? [String: Any])?["products"] as? [[String: Any]])
        XCTAssertFalse(products.isEmpty, "This live fixture must already have products")
        let app = launch(session)
        XCTAssertTrue(app.buttons["home.feature.plan"].waitForExistence(timeout: 10))
        app.buttons["home.feature.plan"].tap()
        XCTAssertTrue(app.buttons["plan.form.generate"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["plan.form.prepare"].exists)
        XCTAssertFalse(app.buttons["plan-preparation.continue"].exists)
        XCTAssertFalse(app.staticTexts["定制资料"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "live-existing-prerequisites-plan-form"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testDailyTogglePersistsToBackendAndRelaunch() async throws {
        let session = try LiveSession()
        let active = try await session.get("/plans/active")
        let plan = try XCTUnwrap((active["data"] as? [String: Any])?["plan"] as? [String: Any])
        let planID = try XCTUnwrap(plan["_id"] as? String)
        let morning = try XCTUnwrap(plan["morning"] as? [[String: Any]])
        let step = try XCTUnwrap(morning.first)
        let stepNumber = step["step"] as? Int ?? 1
        let dailyPath = session.dailyPath(planID: planID)
        let before = try await session.get(dailyPath)
        let original = completed(before, step: stepNumber)
        let target = !original
        let expectedValue = target ? "已完成" : "未完成"

        let app = launch(session)
        let row = app.buttons["home.routine.morning.0"]
        try reveal(row, in: app)
        XCTAssertEqual(row.value as? String, original ? "已完成" : "未完成")
        row.tap()
        await waitForValue(row, expectedValue)
        let persisted = try await session.get(dailyPath)
        XCTAssertEqual(completed(persisted, step: stepNumber), target, "Native toggle must persist to the real daily record")

        app.terminate()
        app.launch()
        try reveal(row, in: app)
        XCTAssertEqual(row.value as? String, expectedValue, "Relaunch must restore the persisted daily value")
    }

    @MainActor
    func testChangingOnlyCategoryPreservesUnknownOpeningStatus() async throws {
        let session = try LiveSession()
        let response = try await session.get("/products/user/\(session.userID)")
        let products = try XCTUnwrap((response["data"] as? [String: Any])?["products"] as? [[String: Any]])
        let product = try XCTUnwrap(products.first { ($0["ingredients"] as? [String])?.isEmpty == false })
        let productID = try XCTUnwrap(product["_id"] as? String ?? product["id"] as? String)
        _ = try await session.put("/products/\(productID)", body: ["openingStatus": "unknown"])
        let app = launch(session)
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
        app.tabButton(1).tap()
        let card = app.buttons["cabinet.product.\(productID)"]
        try reveal(card, in: app)
        card.tap()
        XCTAssertTrue(app.buttons["ingredient.registration"].waitForExistence(timeout: 15))
        app.buttons["ingredient.registration"].tap()
        XCTAssertTrue(app.buttons["ingredient.registration.category.精华"].waitForExistence(timeout: 5))
        app.buttons["ingredient.registration.category.精华"].tap()
        XCTAssertTrue(app.buttons["ingredient.registration.record-opening"].exists)
        let save = app.buttons["ingredient.registration.save"]
        save.tap()
        await fulfillment(of: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: save)], timeout: 15)
        let savedResponse = try await session.get("/products/\(productID)")
        let saved = try XCTUnwrap((savedResponse["data"] as? [String: Any])?["product"] as? [String: Any])
        XCTAssertEqual(saved["label"] as? String, "精华")
        XCTAssertEqual(saved["openingStatus"] as? String, "unknown")
        XCTAssertTrue(saved["openingDate"] == nil || saved["openingDate"] is NSNull)
    }

    @MainActor
    func testProductRegistrationPersistsCategoryAndOpeningStatus() async throws {
        let session = try LiveSession()
        let response = try await session.get("/products/user/\(session.userID)")
        let products = try XCTUnwrap((response["data"] as? [String: Any])?["products"] as? [[String: Any]])
        let product = try XCTUnwrap(products.first { ($0["ingredients"] as? [String])?.isEmpty == false }, "Seed a real analyzed product before running this check")
        let productID = try XCTUnwrap(product["_id"] as? String ?? product["id"] as? String)
        let label = product["label"] as? String == "面霜" ? "精华" : "面霜"
        let unopened = product["openingStatus"] as? String != "unopened"

        let app = launch(session)
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
        app.tabButton(1).tap()
        let card = app.buttons["cabinet.product.\(productID)"]
        try reveal(card, in: app)
        card.tap()
        XCTAssertTrue(app.buttons["ingredient.registration"].waitForExistence(timeout: 15))
        attachScreenshot(app, name: "Live product ingredient report")
        for title in ["功效", "成分", "风险", "建议"] {
            try reveal(app.buttons[title], in: app)
        }
        app.buttons["成分"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "主要成分")).firstMatch.waitForExistence(timeout: 5))
        app.buttons["ingredient.registration"].tap()
        let category = app.buttons["ingredient.registration.category.\(label)"]
        XCTAssertTrue(category.waitForExistence(timeout: 5))
        category.tap()
        let toggle = app.switches["ingredient.registration.unopened"]
        try reveal(toggle, in: app)
        let currentlyOn = (toggle.value as? String) == "1"
        if currentlyOn != unopened { toggle.tap() }
        app.buttons["ingredient.registration.save"].tap()
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.buttons["ingredient.registration.save"])
        await fulfillment(of: [saved], timeout: 15)

        let storedResponse = try await session.get("/products/\(productID)")
        let stored = try XCTUnwrap((storedResponse["data"] as? [String: Any])?["product"] as? [String: Any])
        XCTAssertEqual(stored["label"] as? String, label)
        XCTAssertEqual(stored["openingStatus"] as? String, unopened ? "unopened" : "opened")
        if unopened { XCTAssertTrue(stored["openingDate"] == nil || stored["openingDate"] is NSNull) }
        else { XCTAssertNotNil(stored["openingDate"] as? String) }

        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
        app.tabButton(1).tap()
        try reveal(card, in: app)
        card.tap()
        XCTAssertTrue(app.buttons["ingredient.registration"].waitForExistence(timeout: 15))
        app.buttons["ingredient.registration"].tap()
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual((toggle.value as? String) == "1", unopened)
        app.buttons.matching(identifier: "取消").firstMatch.tap()
        XCTAssertTrue(app.buttons["ingredient.registration"].waitForExistence(timeout: 5))
        app.buttons.matching(identifier: "返回").firstMatch.tap()
        XCTAssertTrue(app.buttons["app.header.add-product"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSkinContextPersistsToBackendAndRelaunch() async throws {
        let session = try LiveSession()
        let ids = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: "/tmp/aiskin-ui-real-report-ids.json"))) as? [String: String]
        let analysisID = try XCTUnwrap(ids?["analysisId"])
        let initial = try await session.get("/skin-analysis/\(analysisID)")
        let record = try XCTUnwrap((initial["data"] as? [String: Any])?["analysis"] as? [String: Any])
        let oldContext = record["context"] as? [String: Any]
        let condition = oldContext?["condition"] as? String == "护肤后" ? "纯素颜" : "护肤后"
        let light = oldContext?["light"] as? String == "室内光" ? "自然光" : "室内光"
        let app = launch(session)
        try openSkinReport(analysisID, in: app)
        XCTAssertTrue(app.staticTexts["肌肤报告"].waitForExistence(timeout: 10))
        attachScreenshot(app, name: "Live skin report")
        try openSkinRecordInformation(in: app)
        let edit = app.buttons["skin.context.open"]
        try reveal(edit, in: app)
        edit.tap()
        let conditionOption = app.buttons["skin.context.option.\(condition)"]
        XCTAssertTrue(conditionOption.waitForExistence(timeout: 5))
        conditionOption.tap()
        await waitForValue(conditionOption, "已选择")
        let lightPicker = app.segmentedControls["skin.context.light"]
        try reveal(lightPicker, in: app)
        let lightOption = lightPicker.buttons[light]
        XCTAssertTrue(lightOption.waitForExistence(timeout: 5))
        lightOption.tap()
        XCTAssertTrue(lightOption.isSelected, "The native light picker must select the requested value")
        attachScreenshot(app, name: "Live skin context selected before save")
        let save = app.buttons["skin.context.save"]
        try reveal(save, in: app)
        save.tap()
        await fulfillment(of: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: save)], timeout: 15)
        let response = try await session.get("/skin-analysis/\(analysisID)")
        let analysis = try XCTUnwrap((response["data"] as? [String: Any])?["analysis"] as? [String: Any])
        let stored = try XCTUnwrap(analysis["context"] as? [String: Any])
        XCTAssertEqual(stored["condition"] as? String, condition)
        XCTAssertEqual(stored["light"] as? String, light)
        app.terminate()
        app.launch()
        try openSkinReport(analysisID, in: app)
        try openSkinRecordInformation(in: app)
        try reveal(edit, in: app)
        edit.tap()
        XCTAssertTrue(conditionOption.waitForExistence(timeout: 5))
        XCTAssertEqual(conditionOption.value as? String, "已选择")
        try reveal(lightPicker, in: app)
        XCTAssertTrue(lightPicker.buttons[light].isSelected)
        attachScreenshot(app, name: "Live skin context restored after relaunch")
        app.buttons.matching(identifier: "取消").firstMatch.tap()
        XCTAssertTrue(app.buttons["skin.context.open"].waitForExistence(timeout: 5))
        app.buttons.matching(identifier: "返回").firstMatch.tap()
        XCTAssertTrue(app.buttons["profile.skin-report.\(analysisID)"].waitForExistence(timeout: 5))
        app.buttons.matching(identifier: "返回").firstMatch.tap()
        XCTAssertTrue(app.buttons["profile.back"].waitForExistence(timeout: 5))
        app.buttons["profile.back"].tap()
        XCTAssertTrue(app.buttons["app.header.profile"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func openSkinRecordInformation(in app: XCUIApplication) throws {
        XCTAssertTrue(app.buttons["前后对比"].waitForExistence(timeout: 10))
        app.buttons["前后对比"].tap()
        let information = app.buttons.matching(NSPredicate(format: "label == %@", "本次记录信息")).firstMatch
        try reveal(information, in: app)
        information.tap()
        try reveal(app.buttons["skin.context.open"], in: app)
    }

    @MainActor
    private func openSkinReport(_ analysisID: String, in app: XCUIApplication) throws {
        XCTAssertTrue(app.buttons["app.header.profile"].waitForExistence(timeout: 10))
        app.buttons["app.header.profile"].tap()
        XCTAssertTrue(app.buttons["profile.skin-history"].waitForExistence(timeout: 5))
        app.buttons["profile.skin-history"].tap()
        let report = app.buttons["profile.skin-report.\(analysisID)"]
        try reveal(report, in: app)
        report.tap()
    }

    @MainActor
    func testSavedPlanPreviewCanBeInspectedWithoutGeneratingOrAdopting() async throws {
        let session = try LiveSession()
        let before = try await session.get("/plans/active")
        guard let plan = (before["data"] as? [String: Any])?["plan"] as? [String: Any] else {
            throw XCTSkip("A saved active local plan is required for read-only preview inspection")
        }
        let id = try XCTUnwrap(plan["_id"] as? String)
        let name = try XCTUnwrap(plan["name"] as? String)
        let beforeList = try await session.get("/plans")
        let beforePlans = try XCTUnwrap((beforeList["data"] as? [String: Any])?["plans"] as? [[String: Any]])
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseLiveBackend", "-AISkinUITestSession", "-AISkinPreviewSavedPlan"]
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "live"
        app.launchEnvironment["AISKIN_UI_TEST_SESSION_FILE"] = session.path
        app.launchEnvironment["AISKIN_UI_PREVIEW_PLAN_ID"] = id
        app.launch()
        XCTAssertTrue(app.buttons["home.feature.plan"].waitForExistence(timeout: 10))
        app.buttons["home.feature.plan"].tap()
        let adopt = app.buttons["personalized-plan.save"]
        XCTAssertTrue(adopt.waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts[name].exists)
        XCTAssertTrue(adopt.isHittable)
        attachScreenshot(app, name: "Read-only saved plan preview top")
        let evening = app.staticTexts["晚间护肤"]
        try reveal(evening, in: app)
        XCTAssertTrue(adopt.isHittable)
        XCTAssertLessThan(adopt.frame.maxY, app.frame.maxY)
        attachScreenshot(app, name: "Read-only saved plan preview evening and footer")
        app.terminate()
        let after = try await session.get("/plans/active")
        XCTAssertEqual(((after["data"] as? [String: Any])?["plan"] as? [String: Any])?["_id"] as? String, id)
        let afterList = try await session.get("/plans")
        let afterPlans = try XCTUnwrap((afterList["data"] as? [String: Any])?["plans"] as? [[String: Any]])
        XCTAssertEqual(Set(afterPlans.compactMap { $0["_id"] as? String }), Set(beforePlans.compactMap { $0["_id"] as? String }))
    }

    @MainActor
    func testGeneratedPlanRequiresAdoptionAndPersistsAfterRelaunch() async throws {
        let session = try LiveSession()
        let beforeResponse = try await session.get("/plans/active")
        let beforePlan = (beforeResponse["data"] as? [String: Any])?["plan"] as? [String: Any]
        let beforeID = beforePlan?["_id"] as? String
        let oldListResponse = try await session.get("/plans")
        let oldPlans = try XCTUnwrap((oldListResponse["data"] as? [String: Any])?["plans"] as? [[String: Any]])
        let priorIDs = Set(oldPlans.compactMap { $0["_id"] as? String })
        let app = launch(session)
        XCTAssertTrue(app.buttons["home.feature.plan"].waitForExistence(timeout: 10))
        app.buttons["home.feature.plan"].tap()

        // Existing report and products satisfy both prerequisites, including
        // the first plan: no manual confirmation sheet is required.
        XCTAssertTrue(app.buttons["plan.form.generate"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["plan.form.prepare"].exists)
        XCTAssertFalse(app.buttons["plan-preparation.continue"].exists)
        let personalState = app.buttons["其他个人状态"]
        if !app.buttons["plan.form.age"].exists {
            try reveal(personalState, in: app)
            personalState.tap()
        }
        let ageRow = app.buttons["plan.form.age"]
        try reveal(ageRow, in: app)
        ageRow.tap()
        let age = app.textFields["personal-information.age.input"]
        XCTAssertTrue(age.waitForExistence(timeout: 5))
        age.tap()
        let existingAge = age.value as? String ?? ""
        age.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: Int(existingAge) == nil ? 0 : existingAge.count) + "28")
        app.buttons["personal-information.age.save"].tap()
        XCTAssertTrue(ageRow.waitForExistence(timeout: 10))
        let hydration = app.buttons["plan.form.goal.hydration"]
        try reveal(hydration, in: app)
        hydration.tap()
        app.buttons["plan.form.goal.repair"].tap()
        let generate = app.buttons["plan.form.generate"]
        try reveal(generate, in: app)
        XCTAssertTrue(generate.isEnabled)
        generate.tap()
        let save = app.buttons["personalized-plan.save"]
        let generationOutcome = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            save.exists || app.staticTexts["暂时无法生成方案"].exists
        }, object: nil)
        await fulfillment(of: [generationOutcome], timeout: 120)
        guard save.exists else {
            attachScreenshot(app, name: "Live plan generation failure")
            XCTFail("Real plan generation must return a preview before adoption")
            return
        }
        for _ in 0..<6 {
            if app.staticTexts.matching(NSPredicate(format: "label == %@", "方案预览")).firstMatch.isHittable { break }
            app.scrollViews.firstMatch.swipeDown()
        }
        attachScreenshot(app, name: "Live generated plan preview before adoption")

        let stillActiveResponse = try await session.get("/plans/active")
        let stillActive = (stillActiveResponse["data"] as? [String: Any])?["plan"] as? [String: Any]
        XCTAssertEqual(stillActive?["_id"] as? String, beforeID, "Generating a preview must not adopt it")
        let generatedResponse = try await session.get("/plans")
        let plans = try XCTUnwrap((generatedResponse["data"] as? [String: Any])?["plans"] as? [[String: Any]])
        let created = plans.filter { ($0["_id"] as? String).map { !priorIDs.contains($0) } ?? false }
        XCTAssertEqual(created.count, 1, "This serial test must create exactly one real plan")
        let generated = try XCTUnwrap(created.first)
        let newID = try XCTUnwrap(generated["_id"] as? String)
        try reveal(save, in: app)
        save.tap()
        await fulfillment(of: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: save)], timeout: 20)
        let adoptedResponse = try await session.get("/plans/active")
        let adopted = try XCTUnwrap((adoptedResponse["data"] as? [String: Any])?["plan"] as? [String: Any])
        XCTAssertEqual(adopted["_id"] as? String, newID)

        app.terminate()
        app.launch()
        let firstStep = app.buttons["home.routine.morning.0"]
        try reveal(firstStep, in: app)
        let morning = try XCTUnwrap(adopted["morning"] as? [[String: Any]])
        let title = try XCTUnwrap(morning.first?["product"] as? String)
        XCTAssertTrue(firstStep.label.contains(title), "Home must render the adopted plan after relaunch")
        attachScreenshot(app, name: "Live Home with adopted plan after relaunch")
        let relaunchedResponse = try await session.get("/plans/active")
        let relaunched = (relaunchedResponse["data"] as? [String: Any])?["plan"] as? [String: Any]
        XCTAssertEqual(relaunched?["_id"] as? String, newID)
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Finishes registration for an already analyzed, explicitly selected mask.
    /// This path never selects an image or triggers another AI analysis.
    @MainActor
    func testExistingMaskRegistrationPersistsWithoutRepeatingAnalysis() async throws {
        guard let productID = ProcessInfo.processInfo.environment["AISKIN_UI_EXISTING_MASK_PRODUCT_ID"], !productID.isEmpty else {
            throw XCTSkip("Set AISKIN_UI_EXISTING_MASK_PRODUCT_ID to the previously uploaded mask record")
        }
        let session = try LiveSession()
        let listResponse = try await session.get("/products/user/\(session.userID)")
        let products = try XCTUnwrap((listResponse["data"] as? [String: Any])?["products"] as? [[String: Any]])
        let original = try XCTUnwrap(products.first { ($0["_id"] as? String ?? $0["id"] as? String) == productID }, "Use a saved record owned by the local test account")
        let originalIngredients = try XCTUnwrap(original["ingredients"] as? [String])
        XCTAssertFalse(originalIngredients.isEmpty)
        let originalStatus = original["openingStatus"] as? String ?? "unknown"
        let reportResponse = try await session.get("/products/\(productID)/ingredient-analysis")
        let originalReport = try XCTUnwrap((reportResponse["data"] as? [String: Any])?["ingredientAnalysis"] as? [String: Any])

        let app = launch(session)
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
        app.tabButton(1).tap()
        let card = app.buttons["cabinet.product.\(productID)"]
        try reveal(card, in: app)
        card.tap()
        XCTAssertTrue(app.buttons["ingredient.registration"].waitForExistence(timeout: 15))
        attachScreenshot(app, name: "Previously uploaded mask report before registration")
        app.buttons["ingredient.registration"].tap()
        let mask = app.buttons["ingredient.registration.category.面膜"]
        XCTAssertTrue(mask.waitForExistence(timeout: 5))
        mask.tap()
        attachScreenshot(app, name: "Mask category selected in registration")
        let save = app.buttons["ingredient.registration.save"]
        try reveal(save, in: app)
        save.tap()
        await fulfillment(of: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: save)], timeout: 15)

        let savedResponse = try await session.get("/products/\(productID)")
        let saved = try XCTUnwrap((savedResponse["data"] as? [String: Any])?["product"] as? [String: Any])
        XCTAssertEqual(saved["label"] as? String, "面膜")
        XCTAssertEqual(saved["openingStatus"] as? String, originalStatus)
        XCTAssertEqual(saved["ingredients"] as? [String], originalIngredients)
        let readbackReportResponse = try await session.get("/products/\(productID)/ingredient-analysis")
        let readbackReport = try XCTUnwrap((readbackReportResponse["data"] as? [String: Any])?["ingredientAnalysis"] as? [String: Any])
        XCTAssertTrue(NSDictionary(dictionary: readbackReport).isEqual(to: originalReport), "Category registration must keep the existing AI report")
        attachScreenshot(app, name: "Existing mask registration saved")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
        app.tabButton(1).tap()
        try reveal(card, in: app)
        card.tap()
        XCTAssertTrue(app.buttons["ingredient.registration"].waitForExistence(timeout: 15))
        app.buttons["ingredient.registration"].tap()
        XCTAssertTrue(mask.waitForExistence(timeout: 5))
        XCTAssertTrue(mask.isSelected || (mask.value as? String) == "已选择")
        app.buttons["取消"].tap()
        app.buttons.matching(identifier: "返回").firstMatch.tap()
        XCTAssertTrue(app.buttons["cabinet.conflict-mode"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testNativeProductPhotoUploadAnalysisAndRegistrationPersist() async throws {
        guard let exactLabel = ProcessInfo.processInfo.environment["AISKIN_UI_PRODUCT_PHOTO_LABEL"] else {
            throw XCTSkip("Set AISKIN_UI_PRODUCT_PHOTO_LABEL to the visually verified product fixture accessibility label")
        }
        let productCategory = ProcessInfo.processInfo.environment["AISKIN_UI_PRODUCT_CATEGORY"] ?? "精华"
        XCTAssertTrue(["洁面", "精华", "面膜", "防晒", "面霜"].contains(productCategory), "Choose a supported product registration category")
        let session = try LiveSession()
        let before = try await session.get("/products/user/\(session.userID)")
        let oldProducts = try XCTUnwrap((before["data"] as? [String: Any])?["products"] as? [[String: Any]])
        let oldIDs = Set(oldProducts.compactMap { $0["id"] as? String ?? $0["_id"] as? String })
        let app = launch(session)
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
        app.tabButton(1).tap()
        app.buttons["app.header.add-product"].tap()
        let choose = app.buttons["capture.choose-photo"]
        XCTAssertTrue(choose.waitForExistence(timeout: 5))
        choose.tap()
        let cancel = app.buttons.matching(NSPredicate(format: "NOT (identifier IN %@) AND label IN %@", ["cabinet.add.cancel", "capture.cancel", "DismissImagePickerButton"], ["Cancel", "取消", "Close", "关闭"])).firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 10))
        let tree = app.debugDescription
        let treeAttachment = XCTAttachment(string: tree)
        treeAttachment.name = "Native product photo picker accessibility tree"
        treeAttachment.lifetime = .keepAlways
        add(treeAttachment)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Native product photo picker"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let matching = app.images.matching(NSPredicate(format: "label == %@ AND identifier == %@", exactLabel, "PXGGridLayout-Info"))
        let didLoadFixture = matching.firstMatch.waitForExistence(timeout: 30)
        attachScreenshot(app, name: "Loaded native product photo picker")
        guard didLoadFixture, matching.count == 1, !matching.firstMatch.frame.isEmpty, app.frame.contains(matching.firstMatch.frame) else {
            cancel.tap()
            XCTFail("The explicitly configured product fixture must load uniquely in the native picker")
            return
        }
        // Photos exposes its visible thumbnails as virtual Image elements with
        // isHittable=false. Tap the center of the uniquely identified, verified
        // fixture's on-screen frame, then assert the real picker result.
        matching.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertFalse(app.buttons["cabinet.add.submit"].exists, "Photo selection must upload automatically")
        let registration = app.buttons["ingredient.registration"]
        XCTAssertTrue(registration.waitForExistence(timeout: 180), "Real image upload, OCR and ingredient analysis must finish")
        attachScreenshot(app, name: "Live uploaded product ingredient report")
        registration.tap()
        XCTAssertTrue(app.buttons["ingredient.registration.category.\(productCategory)"].waitForExistence(timeout: 5))
        app.buttons["ingredient.registration.category.\(productCategory)"].tap()
        let unopened = app.switches["ingredient.registration.unopened"]
        try reveal(unopened, in: app)
        if (unopened.value as? String) != "1" { unopened.tap() }
        let save = app.buttons["ingredient.registration.save"]
        save.tap()
        await fulfillment(of: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: save)], timeout: 20)
        let after = try await session.get("/products/user/\(session.userID)")
        let products = try XCTUnwrap((after["data"] as? [String: Any])?["products"] as? [[String: Any]])
        let newProducts = products.filter { ($0["id"] as? String ?? $0["_id"] as? String).map { !oldIDs.contains($0) } ?? false }
        XCTAssertEqual(newProducts.count, 1, "Native upload should create exactly one product")
        let newProduct = try XCTUnwrap(newProducts.first)
        let productID = try XCTUnwrap(newProduct["id"] as? String ?? newProduct["_id"] as? String)
        XCTAssertEqual(newProduct["label"] as? String, productCategory)
        XCTAssertEqual(newProduct["openingStatus"] as? String, "unopened")
        XCTAssertFalse((newProduct["ingredients"] as? [String] ?? []).isEmpty)
        let analysisResponse = try await session.get("/products/\(productID)/ingredient-analysis")
        let analysis = try XCTUnwrap((analysisResponse["data"] as? [String: Any])?["ingredientAnalysis"] as? [String: Any])
        XCTAssertFalse((analysis["summary"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        app.buttons.matching(identifier: "返回").firstMatch.tap()
        XCTAssertTrue(app.buttons["app.header.add-product"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func launch(_ session: LiveSession) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseLiveBackend", "-AISkinUITestSession"]
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "live"
        app.launchEnvironment["AISKIN_UI_TEST_SESSION_FILE"] = session.path
        app.launch()
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) throws {
        _ = element.waitForExistence(timeout: 5)
        for _ in 0..<10 {
            if element.exists && element.isHittable { return }
            guard let scroll = app.scrollViews.allElementsBoundByIndex.last(where: { $0.isHittable }) else {
                XCTFail("No visible scroll view can reveal \(element.identifier)")
                throw LivePrototypeNavigationFailure.unavailableControl
            }
            scroll.swipeUp()
        }
        guard element.exists && element.isHittable else {
            XCTFail("Required native control must be visible: \(element.identifier)")
            throw LivePrototypeNavigationFailure.unavailableControl
        }
    }

    @MainActor
    private func waitForValue(_ element: XCUIElement, _ value: String) async {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: element)
        await fulfillment(of: [expectation], timeout: 15)
    }

    private func completed(_ response: [String: Any], step: Int) -> Bool {
        let data = response["data"] as? [String: Any]
        let daily = data?["daily"] as? [String: Any]
        let morning = daily?["morning"] as? [[String: Any]]
        return morning?.first { ($0["step"] as? Int) == step }?["completed"] as? Bool ?? false
    }
}

private struct LiveSession {
    let path: String
    let token: String
    let userID: String

    init() throws {
        path = ProcessInfo.processInfo.environment["AISKIN_UI_TEST_SESSION_FILE"] ?? "/tmp/aiskin-ui-test-session.json"
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as? [String: Any]
        token = try XCTUnwrap(json?["token"] as? String, "The local test session must include a real access token")
        let user = (json?["data"] as? [String: Any])?["user"] as? [String: Any]
        userID = try XCTUnwrap(user?["_id"] as? String ?? user?["id"] as? String)
    }

    func get(_ path: String) async throws -> [String: Any] {
        try await request(path)
    }

    func put(_ path: String, body: [String: Any]) async throws -> [String: Any] {
        try await request(path, method: "PUT", body: body)
    }

    private func request(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> [String: Any] {
        let url = try XCTUnwrap(URL(string: "http://127.0.0.1:5001/api" + path))
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200, "Live readback failed at \(url.path)")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["success"] as? Bool, true)
        return json
    }

    func dailyPath(planID: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        var components = URLComponents()
        components.path = "/plans/\(planID)/daily"
        components.queryItems = [URLQueryItem(name: "date", value: formatter.string(from: Date())), URLQueryItem(name: "timezone", value: TimeZone.current.identifier)]
        return components.string!
    }
}

private enum LivePrototypeNavigationFailure: Error { case unavailableControl }
