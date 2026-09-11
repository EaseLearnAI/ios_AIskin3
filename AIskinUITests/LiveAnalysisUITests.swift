import XCTest

/// Serial opt-in acceptance against a dedicated account on localhost.
/// Analysis is invoked by native UI; HTTP is used only to verify persistence.
final class LiveAnalysisUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        guard ProcessInfo.processInfo.environment["AISKIN_RUN_LIVE_UI"] == "1" else {
            throw XCTSkip("Set AISKIN_RUN_LIVE_UI=1 for real local analysis UI tests")
        }
    }

    @MainActor
    func testSavedProductReportShowsRealScoreAndConciseAdvice() async throws {
        let session = try AnalysisSession()
        let response = try await session.get("/conflicts")
        let records = try XCTUnwrap((response["data"] as? [String: Any])?["conflicts"] as? [[String: Any]])
        let record = try XCTUnwrap(records.first { ($0["reportVersion"] as? Int) == 2 })
        let id = try XCTUnwrap(AnalysisSession.identifier(record))
        let advice = try XCTUnwrap((record["recommendations"] as? [String: Any])?["advice"] as? [[String: Any]])
        let app = launch(session)
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 15))
        app.tabButton(1).tap()
        XCTAssertTrue(app.buttons["app.header.profile"].waitForExistence(timeout: 15))
        app.buttons["app.header.profile"].tap()
        XCTAssertTrue(app.buttons["profile.conflict-history"].waitForExistence(timeout: 10))
        app.buttons["profile.conflict-history"].tap()
        let row = app.buttons["profile.conflict-report.\(id)"]
        try reveal(row, in: app)
        row.tap()
        XCTAssertTrue(app.descendants(matching: .any)["conflict.summary"].waitForExistence(timeout: 15))
        if let score = record["riskScore"] as? Double {
            XCTAssertTrue(app.staticTexts[String(format: "%.1f", score)].exists)
        } else {
            XCTAssertTrue(app.staticTexts["暂时无法完成风险评分"].exists)
        }
        attach(app, name: "conflict-v2-real-score-products")
        XCTAssertTrue((1...3).contains(advice.count))
        for item in advice {
            let title = try XCTUnwrap(item["title"] as? String)
            try reveal(app.staticTexts[title], in: app)
            XCTAssertTrue(app.staticTexts[title].isHittable)
        }
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "可搭配组合")).firstMatch.exists)
        XCTAssertFalse(app.staticTexts["早间护肤"].exists)
        attach(app, name: "conflict-v2-real-product-conclusion-advice")
        let reloaded = try await session.get("/conflicts/\(id)")
        let detail = try XCTUnwrap((reloaded["data"] as? [String: Any])?["conflict"] as? [String: Any])
        XCTAssertEqual(detail["riskScore"] as? Double, record["riskScore"] as? Double)
        XCTAssertEqual(detail["summary"] as? String, record["summary"] as? String)
    }

    @MainActor
    func testSelectedProductsProducePersistedConflictReportAndHistory() async throws {
        let session = try AnalysisSession()
        let productsResponse = try await session.get("/products/user/\(session.userID)")
        let products = try XCTUnwrap((productsResponse["data"] as? [String: Any])?["products"] as? [[String: Any]])
        let analyzed = products.filter { ($0["ingredients"] as? [String])?.isEmpty == false && ($0["overallRating"] != nil || $0["safetyScore"] != nil || $0["efficacyScore"] != nil) }
        let selected = Array(analyzed.prefix(2))
        XCTAssertEqual(selected.count, 2, "Provide two genuinely analyzed products in the dedicated local account")
        let ids = try selected.map { try XCTUnwrap(AnalysisSession.identifier($0)) }
        let names = try selected.map { try XCTUnwrap($0["name"] as? String) }
        let before = try await session.get("/conflicts")
        let oldRecords = try XCTUnwrap((before["data"] as? [String: Any])?["conflicts"] as? [[String: Any]])
        let oldIDs = Set(oldRecords.compactMap(AnalysisSession.identifier))
        let app = launch(session)
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
        app.tabButton(1).tap()
        XCTAssertTrue(app.buttons["cabinet.conflict-mode"].waitForExistence(timeout: 10))
        if !app.buttons["cabinet.conflict-mode"].label.contains("取消") {
            app.buttons["cabinet.conflict-mode"].tap()
        }
        for id in ids {
            let product = app.buttons["cabinet.product.\(id)"]
            try reveal(product, in: app)
            product.tap()
            XCTAssertEqual(product.value as? String, "已选择")
        }
        let analyze = app.buttons["cabinet.analyze-conflict"]
        XCTAssertTrue(analyze.waitForExistence(timeout: 5))
        XCTAssertLessThan(analyze.frame.maxY, app.tabButton(0).frame.minY)
        analyze.tap()
        XCTAssertTrue(app.descendants(matching: .any)["conflict.summary"].waitForExistence(timeout: 120), "Real conflict analysis must return its report")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "本次检测产品")).firstMatch.exists)
        attach(app, name: "Live conflict analysis report")

        let after = try await session.get("/conflicts")
        let records = try XCTUnwrap((after["data"] as? [String: Any])?["conflicts"] as? [[String: Any]])
        let created = records.filter { AnalysisSession.identifier($0).map { !oldIDs.contains($0) } ?? false }
        XCTAssertEqual(created.count, 1, "One UI analysis must create one saved conflict record")
        let saved = try XCTUnwrap(created.first)
        let recordID = try XCTUnwrap(AnalysisSession.identifier(saved))
        let detailResponse = try await session.get("/conflicts/\(recordID)")
        let detail = try XCTUnwrap((detailResponse["data"] as? [String: Any])?["conflict"] as? [String: Any])
        let snapshots = try XCTUnwrap(detail["products"] as? [[String: Any]])
        XCTAssertEqual(Set(snapshots.compactMap(AnalysisSession.identifier)), Set(ids))
        XCTAssertEqual(Set(snapshots.compactMap { $0["name"] as? String }), Set(names))
        XCTAssertEqual(detail["reportVersion"] as? Int, 2)
        let pairs = try XCTUnwrap(detail["productPairs"] as? [[String: Any]])
        XCTAssertEqual(pairs.count, 1)
        XCTAssertEqual(Set(pairs.first?["productIds"] as? [String] ?? []), Set(ids))
        let recommendations = try XCTUnwrap(detail["recommendations"] as? [String: Any])
        let advice = try XCTUnwrap(recommendations["advice"] as? [[String: Any]])
        XCTAssertTrue((1...3).contains(advice.count))
        XCTAssertNil(recommendations["routines"])
        XCTAssertNil(detail["safeCombo"])
        if let score = detail["riskScore"] as? Double {
            XCTAssertTrue((0...5).contains(score))
            XCTAssertTrue(app.staticTexts[String(format: "%.1f", score)].exists)
        } else {
            XCTAssertEqual(pairs.first?["status"] as? String, "unknown")
            XCTAssertTrue(app.staticTexts["暂时无法完成风险评分"].exists)
        }
        for item in advice {
            let title = try XCTUnwrap(item["title"] as? String)
            try reveal(app.staticTexts[title], in: app)
            XCTAssertTrue(app.staticTexts[title].isHittable)
        }
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "可搭配组合")).firstMatch.exists)
        XCTAssertFalse(app.staticTexts["早间护肤"].exists)
        attach(app, name: "Live concise product advice")

        try back(app)
        XCTAssertTrue(app.buttons["cabinet.conflict-mode"].waitForExistence(timeout: 5))
        app.buttons["app.header.profile"].tap()
        XCTAssertTrue(app.buttons["profile.conflict-history"].waitForExistence(timeout: 5))
        app.buttons["profile.conflict-history"].tap()
        let savedRow = app.buttons["profile.conflict-report.\(recordID)"]
        try reveal(savedRow, in: app)
        savedRow.tap()
        XCTAssertTrue(app.descendants(matching: .any)["conflict.summary"].waitForExistence(timeout: 10))
        for name in Set(names) { XCTAssertTrue(app.staticTexts.matching(identifier: name).firstMatch.exists) }
        attach(app, name: "Live conflict report reopened from history")
        try back(app)
        XCTAssertTrue(savedRow.waitForExistence(timeout: 5))
        try back(app)
        XCTAssertTrue(app.buttons["profile.back"].waitForExistence(timeout: 5))
        app.buttons["profile.back"].tap()
        XCTAssertTrue(app.buttons["app.header.profile"].waitForExistence(timeout: 5))
        let finalReadback = try await session.get("/conflicts/\(recordID)")
        XCTAssertNotNil((finalReadback["data"] as? [String: Any])?["conflict"])
    }

    @MainActor
    func testExistingSkinHistoryOpensOverviewReportAndReturns() async throws {
        let session = try AnalysisSession()
        let response = try await session.get("/skin-analysis?page=1&limit=10")
        let records = try XCTUnwrap((response["data"] as? [String: Any])?["analyses"] as? [[String: Any]])
        let latestID = try XCTUnwrap(records.first.flatMap(AnalysisSession.identifier), "A saved skin analysis is required")
        let app = launch(session)
        XCTAssertTrue(app.tabButton(2).waitForExistence(timeout: 10))
        app.tabButton(2).tap()
        let report = app.buttons["skin.overview.report"]
        XCTAssertTrue(report.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["最近一次检测"].exists)
        attach(app, name: "Live existing skin overview")
        report.tap()
        XCTAssertTrue(app.staticTexts["肌肤报告"].waitForExistence(timeout: 10))
        assertIndependentSkinReport(app)
        attach(app, name: "Independent skin report with four anchors")
        app.buttons["skin.report.overview"].tap()
        XCTAssertTrue(report.waitForExistence(timeout: 5))
        let allHistory = app.buttons["skin.overview.history"]
        try reveal(allHistory, in: app)
        allHistory.tap()
        let row = app.buttons["skin.history.report.\(latestID)"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.staticTexts["肌肤报告"].waitForExistence(timeout: 5))
        let overview = app.buttons["skin.report.overview"]
        try reveal(overview, in: app)
        overview.tap()
        XCTAssertTrue(report.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSavedObservationsRemainVisibleInTheNativeReport() async throws {
        let session = try AnalysisSession()
        let recordsResponse = try await session.get("/skin-analysis?page=1&limit=50")
        let records = try XCTUnwrap((recordsResponse["data"] as? [String: Any])?["analyses"] as? [[String: Any]])
        let record = try XCTUnwrap(records.first {
            let issues = $0["otherIssues"] as? [String: Any]
            return (issues?["observations"] as? [[String: Any]])?.isEmpty == false
        }, "Keep a real saved record with additional observations for this regression")
        let id = try XCTUnwrap(AnalysisSession.identifier(record))
        let issues = try XCTUnwrap(record["otherIssues"] as? [String: Any])
        let observations = try XCTUnwrap(issues["observations"] as? [[String: Any]])
        XCTAssertFalse(observations.flatMap { $0["details"] as? [String] ?? [] }.isEmpty)
        let app = launch(session)
        XCTAssertTrue(app.buttons["app.header.profile"].waitForExistence(timeout: 10))
        app.buttons["app.header.profile"].tap()
        app.buttons["profile.skin-history"].tap()
        let row = app.buttons["profile.skin-report.\(id)"]
        try reveal(row, in: app)
        row.tap()
        let issuesTab = app.buttons["肌肤问题"]
        XCTAssertTrue(issuesTab.waitForExistence(timeout: 10))
        issuesTab.tap()
        try assertSavedObservationDetails(record, in: app)
        attach(app, name: "Live saved observation labels in scrollable report")
    }

    @MainActor
    func testExactFacePhotoProducesPersistedSkinReportAndHistory() async throws {
        guard let assetLabel = ProcessInfo.processInfo.environment["AISKIN_UI_FACE_PHOTO_LABEL"], !assetLabel.isEmpty else {
            throw XCTSkip("Set AISKIN_UI_FACE_PHOTO_LABEL to the exact visually verified face fixture label; no arbitrary asset is selected")
        }
        let session = try AnalysisSession()
        let before = try await session.get("/skin-analysis?page=1&limit=50")
        let oldRecords = try XCTUnwrap((before["data"] as? [String: Any])?["analyses"] as? [[String: Any]])
        let oldIDs = Set(oldRecords.compactMap(AnalysisSession.identifier))
        let app = launch(session)
        XCTAssertTrue(app.tabButton(2).waitForExistence(timeout: 10))
        app.tabButton(2).tap()
        let latest = app.buttons["skin.overview.report"]
        if !oldRecords.isEmpty {
            XCTAssertTrue(latest.waitForExistence(timeout: 10), "Saved skin history must load the recent-summary overview")
            attach(app, name: "Live skin overview with recent summary")
            latest.tap()
            XCTAssertTrue(app.buttons["skin.report.overview"].waitForExistence(timeout: 5))
            app.buttons["skin.report.overview"].tap()
            XCTAssertTrue(latest.waitForExistence(timeout: 5))
            app.buttons["skin.overview.capture"].tap()
        }
        XCTAssertTrue(app.buttons["skin.capture.start"].waitForExistence(timeout: 5))
        app.buttons["skin.capture.start"].tap()
        let album = app.buttons["从相册上传"]
        XCTAssertTrue(album.waitForExistence(timeout: 5))
        album.tap()
        let cancel = app.buttons.matching(NSPredicate(format: "label IN %@", ["Cancel", "取消", "Close", "关闭"])).firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 10))
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "Native face fixture picker accessibility tree"
        tree.lifetime = .keepAlways
        add(tree)
        attach(app, name: "Native face fixture picker")
        let asset = app.images.matching(NSPredicate(format: "label == %@ AND identifier == %@", assetLabel, "PXGGridLayout-Info"))
        guard asset.firstMatch.waitForExistence(timeout: 30), asset.count == 1, !asset.firstMatch.frame.isEmpty, app.frame.contains(asset.firstMatch.frame) else {
            cancel.tap()
            XCTFail("The explicitly configured face fixture must load uniquely in the native picker")
            return
        }
        // The system picker's virtual Image is not marked hittable; its unique
        // observed thumbnail frame identifies the actual native tap target.
        asset.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let result = app.staticTexts["肌肤报告"]
        let failure = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "分析失败：")).firstMatch
        let outcome = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in result.exists || failure.exists }, object: nil)
        await fulfillment(of: [outcome], timeout: 120)
        guard result.exists else {
            attach(app, name: "Live native face analysis failure")
            XCTFail("Native face selection must finish real skin analysis")
            return
        }
        try await waitForLoadedSkinReportLayout(app)
        attach(app, name: "Live newly captured skin analysis report")
        let after = try await session.get("/skin-analysis?page=1&limit=50")
        let records = try XCTUnwrap((after["data"] as? [String: Any])?["analyses"] as? [[String: Any]])
        let created = records.filter { AnalysisSession.identifier($0).map { !oldIDs.contains($0) } ?? false }
        XCTAssertEqual(created.count, 1)
        let record = try XCTUnwrap(created.first)
        let analysisID = try XCTUnwrap(AnalysisSession.identifier(record))
        let detailResponse = try await session.get("/skin-analysis/\(analysisID)")
        let detail = try XCTUnwrap((detailResponse["data"] as? [String: Any])?["analysis"] as? [String: Any])
        XCTAssertFalse((detail["imageUrl"] as? String ?? "").isEmpty)
        let assessment = try XCTUnwrap(detail["overallAssessment"] as? [String: Any])
        XCTAssertNotNil(assessment["healthScore"] as? NSNumber)
        XCTAssertFalse((assessment["summary"] as? String ?? "").isEmpty)

        assertIndependentSkinReport(app)
        app.buttons["skin.report.overview"].tap()
        XCTAssertTrue(app.buttons["app.header.profile"].waitForExistence(timeout: 5))
        app.buttons["app.header.profile"].tap()
        XCTAssertTrue(app.buttons["profile.skin-history"].waitForExistence(timeout: 5))
        app.buttons["profile.skin-history"].tap()
        let historyRow = app.buttons["profile.skin-report.\(analysisID)"]
        try reveal(historyRow, in: app)
        historyRow.tap()
        XCTAssertTrue(app.staticTexts["肌肤报告"].waitForExistence(timeout: 10))
        attach(app, name: "Live new skin report reopened from saved history")
        try back(app)
        XCTAssertTrue(historyRow.waitForExistence(timeout: 5))
        try back(app)
        XCTAssertTrue(app.buttons["profile.back"].waitForExistence(timeout: 5))
        app.buttons["profile.back"].tap()
        XCTAssertTrue(app.buttons["app.header.profile"].waitForExistence(timeout: 5))
    }

    /// Read-only acceptance of the three user-specified source images. Their
    /// source-to-OSS SHA checks are documented separately; this checks native UI.
    @MainActor
    func testSpecifiedMaterialReportsDisplaySavedContentAndPhotos() async throws {
        let session = try AnalysisSession()
        let defaultManifest = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("doc/联调验收/2026-09-09-原型逐页修正/specified-material-reports.json")
        let manifestURL = ProcessInfo.processInfo.environment["AISKIN_UI_MATERIAL_REPORTS_FILE"]
            .map { URL(fileURLWithPath: $0) } ?? defaultManifest
        let manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any])
        XCTAssertEqual(manifest["userId"] as? String, session.userID, "Use the dedicated local account that owns these saved source images")
        let productIDs = try XCTUnwrap(manifest["productIds"] as? [String])
        XCTAssertEqual(productIDs.count, 2)
        let faceID = try XCTUnwrap(manifest["faceId"] as? String)
        let app = launch(session)

        for (index, productID) in productIDs.enumerated() {
            let response = try await session.get("/products/\(productID)")
            let product = try XCTUnwrap((response["data"] as? [String: Any])?["product"] as? [String: Any])
            XCTAssertEqual(AnalysisSession.identifier(product), productID)
            let name = try XCTUnwrap(product["name"] as? String)
            let ingredients = try XCTUnwrap(product["ingredients"] as? [String])
            XCTAssertFalse(ingredients.isEmpty)
            XCTAssertEqual(URL(string: product["imageUrl"] as? String ?? "")?.scheme, "https")
            let analysisResponse = try await session.get("/products/\(productID)/ingredient-analysis")
            let analysisData = try XCTUnwrap(analysisResponse["data"] as? [String: Any])
            let ingredientAnalysis = try XCTUnwrap(analysisData["ingredientAnalysis"] as? [String: Any])

            if index > 0 { app.terminate(); app.launch() }
            XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 10))
            app.tabButton(1).tap()
            let card = app.buttons["cabinet.product.\(productID)"]
            try reveal(card, in: app)
            card.tap()
            XCTAssertTrue(app.buttons["ingredient.registration"].waitForExistence(timeout: 15))
            XCTAssertTrue(app.staticTexts[name].exists)
            XCTAssertTrue(app.images["ingredient.report.photo"].waitForExistence(timeout: 20), "The actual saved product photo must finish loading")
            XCTAssertFalse(app.tabButton(0).isHittable)
            attach(app, name: "specified-product-\(index + 1)-summary-and-photo")
            XCTAssertFalse(app.buttons["评分与风险明细"].exists)
            XCTAssertFalse(app.staticTexts["基于成分信息分析，仅供参考"].exists)
            let overallRating = try XCTUnwrap(ingredientAnalysis["overallRating"] as? NSNumber).doubleValue
            XCTAssertTrue(app.staticTexts[String(format: "%.1f", overallRating)].exists)
            for (anchor, sectionID) in [("功效", "effects"), ("成分", "ingredients"), ("风险", "risks"), ("建议", "advice")] {
                let button = app.buttons[anchor]
                try reveal(button, in: app)
                button.tap()
                let section = app.descendants(matching: .any)["ingredient.section.\(sectionID)"]
                XCTAssertTrue(section.waitForExistence(timeout: 5))
                XCTAssertTrue(app.buttons["ingredient.registration"].isHittable)
                attach(app, name: "specified-product-\(index + 1)-\(sectionID)")
            }
            app.buttons["成分"].tap()
            let firstIngredient = try XCTUnwrap(ingredients.first)
            guard app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", firstIngredient)).firstMatch.waitForExistence(timeout: 5) else {
                XCTFail("Returning to the ingredient anchor must show the saved ingredient: \(firstIngredient)")
                throw LiveAnalysisNavigationFailure.unavailableControl
            }
            try back(app)
            XCTAssertTrue(app.buttons["cabinet.conflict-mode"].waitForExistence(timeout: 5))
        }

        let skinResponse = try await session.get("/skin-analysis/\(faceID)")
        let skin = try XCTUnwrap((skinResponse["data"] as? [String: Any])?["analysis"] as? [String: Any])
        XCTAssertEqual(AnalysisSession.identifier(skin), faceID)
        XCTAssertEqual(URL(string: skin["imageUrl"] as? String ?? "")?.scheme, "https")
        app.terminate(); app.launch()
        XCTAssertTrue(app.tabButton(2).waitForExistence(timeout: 10))
        app.tabButton(2).tap()
        XCTAssertTrue(app.buttons["app.header.skin-history"].waitForExistence(timeout: 10))
        app.buttons["app.header.skin-history"].tap()
        let historyRow = app.buttons["skin.history.report.\(faceID)"]
        try reveal(historyRow, in: app)
        historyRow.tap()
        XCTAssertTrue(app.staticTexts["肌肤报告"].waitForExistence(timeout: 10))
        assertIndependentSkinReport(app)
        attach(app, name: "specified-face-report-issues-first")
        for anchor in ["肌肤问题", "肤况概览", "护肤建议", "前后对比"] {
            app.buttons[anchor].tap()
            XCTAssertTrue(app.buttons["skin.report.retake"].isHittable)
            attach(app, name: "specified-face-\(anchor)")
        }
        app.buttons["肌肤问题"].tap()
        XCTAssertTrue(app.images["skin.report.photo"].waitForExistence(timeout: 20), "The supplied face photograph must finish loading")
        try assertSavedObservationDetails(skin, in: app)
        app.buttons["肌肤问题"].tap()
        let photoLink = app.buttons["查看本次照片"]
        XCTAssertTrue(photoLink.isHittable)
        photoLink.tap()
        XCTAssertTrue(app.staticTexts["本次检测照片"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.images["skin.report.photo"].waitForExistence(timeout: 20))
        attach(app, name: "specified-face-full-saved-photo")
        app.buttons["完成"].tap()
        app.buttons["skin.report.overview"].tap()
        XCTAssertTrue(app.buttons["skin.overview.report"].waitForExistence(timeout: 5))
        app.buttons["app.header.skin-history"].tap()
        try reveal(historyRow, in: app)
        historyRow.tap()
        XCTAssertTrue(app.staticTexts["肌肤报告"].waitForExistence(timeout: 10))
        attach(app, name: "specified-face-reopened-from-history")
        app.buttons["skin.report.overview"].tap()
        let finalSkin = try await session.get("/skin-analysis/\(faceID)")
        let finalAnalysis = try XCTUnwrap((finalSkin["data"] as? [String: Any])?["analysis"] as? [String: Any])
        XCTAssertEqual(AnalysisSession.identifier(finalAnalysis), faceID)
        let initialPhoto = try XCTUnwrap(URL(string: try XCTUnwrap(skin["imageUrl"] as? String)))
        let finalPhoto = try XCTUnwrap(URL(string: try XCTUnwrap(finalAnalysis["imageUrl"] as? String)))
        // Temporary OSS signatures may refresh on every read. The persisted
        // photograph must still be the same HTTPS storage object.
        XCTAssertEqual(finalPhoto.scheme, "https")
        XCTAssertEqual(finalPhoto.host, initialPhoto.host)
        XCTAssertEqual(finalPhoto.port, initialPhoto.port)
        XCTAssertEqual(finalPhoto.path, initialPhoto.path)
    }

    @MainActor
    private func waitForLoadedSkinReportLayout(_ app: XCUIApplication) async throws {
        let photo = app.images["skin.report.photo"]
        guard photo.waitForExistence(timeout: 20) else {
            XCTFail("Capture the successful report only after its real photo loads")
            throw LiveAnalysisNavigationFailure.unavailableControl
        }
        let footer = app.buttons["skin-analysis.customize-plan"]
        let header = app.buttons["skin.report.overview"]
        var lastFrames: [CGRect] = []
        var unchangedSince = Date()
        let stable = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard photo.exists, footer.isHittable, header.isHittable,
                  app.frame.contains(footer.frame) else { return false }
            let frames = [header.frame, footer.frame]
            guard frames == lastFrames else {
                lastFrames = frames
                unchangedSince = Date()
                return false
            }
            return Date().timeIntervalSince(unchangedSince) >= 0.5
        }, object: nil)
        guard await XCTWaiter.fulfillment(of: [stable], timeout: 5) == .completed else {
            XCTFail("The report header and footer must settle on screen before its acceptance screenshot")
            throw LiveAnalysisNavigationFailure.unavailableControl
        }
    }

    @MainActor
    private func assertIndependentSkinReport(_ app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["肌肤报告"].waitForExistence(timeout: 10))
        for title in ["肌肤问题", "肤况概览", "护肤建议", "前后对比"] { XCTAssertTrue(app.buttons[title].exists) }
        XCTAssertLessThan(app.buttons["肌肤问题"].frame.minX, app.buttons["肤况概览"].frame.minX)
        XCTAssertFalse(app.tabButton(0).isHittable)
        XCTAssertFalse(app.buttons["app.header.profile"].isHittable)
        XCTAssertTrue(app.buttons["skin.report.retake"].isHittable)
        XCTAssertTrue(app.buttons["skin-analysis.customize-plan"].isHittable)
    }

    /// UI coverage checks every saved category and its summary/detail pair.
    /// SkinReportPresentationTests cover the content projection and legacy data.
    @MainActor
    private func assertSavedObservationDetails(_ record: [String: Any], in app: XCUIApplication) throws {
        let issues = record["otherIssues"] as? [String: Any] ?? [:]
        let knownFields = ["redness", "pores", "acne", "blackheads", "hyperpigmentation", "fineLines", "sensitivity", "skinToneEvenness"]
        var categories = knownFields.filter { field in
            guard let value = (record[field] ?? issues[field]) as? [String: Any] else { return false }
            return value.values.contains { !($0 is NSNull) }
        }
        for observation in issues["observations"] as? [[String: Any]] ?? [] {
            if let category = observation["category"] as? String,
               let details = observation["details"] as? [String],
               !details.isEmpty, !categories.contains(category) {
                categories.append(category)
            }
        }
        XCTAssertFalse(app.buttons["全部观察"].exists)
        XCTAssertFalse(app.staticTexts["观察详情与判断依据"].exists)
        let scroll = app.scrollViews["skin.report.observations"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(scroll.frame.height, 261, "Saved labels share an area no taller than 260 points")
        app.showSkinObservationList()
        for category in categories {
            let summary = app.revealSkinObservation(category)
            XCTAssertFalse(summary.label.isEmpty)
        }
    }

    @MainActor
    private func launch(_ session: AnalysisSession) -> XCUIApplication {
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
                throw LiveAnalysisNavigationFailure.unavailableControl
            }
            scroll.swipeUp()
        }
        guard element.exists && element.isHittable else {
            XCTFail("Required native control is not visible: \(element.identifier)")
            throw LiveAnalysisNavigationFailure.unavailableControl
        }
    }

    @MainActor
    private func back(_ app: XCUIApplication) throws {
        let button = app.buttons.matching(identifier: "返回").firstMatch
        guard button.waitForExistence(timeout: 5) else {
            XCTFail("The report must offer its native back control")
            throw LiveAnalysisNavigationFailure.unavailableControl
        }
        button.tap()
    }

    @MainActor
    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private struct AnalysisSession {
    let path: String
    let token: String
    let userID: String

    init() throws {
        path = ProcessInfo.processInfo.environment["AISKIN_UI_TEST_SESSION_FILE"] ?? "/tmp/aiskin-ui-test-session.json"
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as? [String: Any]
        token = try XCTUnwrap(json?["token"] as? String)
        let user = (json?["data"] as? [String: Any])?["user"] as? [String: Any]
        userID = try XCTUnwrap(user.flatMap(Self.identifier))
    }

    static func identifier(_ record: [String: Any]) -> String? { record["_id"] as? String ?? record["id"] as? String }

    func get(_ path: String) async throws -> [String: Any] {
        let url = try XCTUnwrap(URL(string: "http://127.0.0.1:5001/api" + path))
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200, "Real readback failed at \(url.path)")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["success"] as? Bool, true)
        return json
    }
}

private enum LiveAnalysisNavigationFailure: Error { case unavailableControl }
