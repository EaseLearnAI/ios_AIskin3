import XCTest

/// Structural and interaction checks; screenshot review remains mandatory for fidelity.
final class ReportPrototypeUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testIngredientHasFourAnchorsAndPersistentSaveActions() {
        let app = XCUIApplication()
        app.launchEnvironment["AISKIN_BACKEND_MODE"] = "mock"
        app.launch()
        XCTAssertTrue(app.tabButton(1).waitForExistence(timeout: 8))
        app.tabButton(1).tap()
        let product = app.buttons["cabinet.product.mock-product-cleanser"]
        XCTAssertTrue(product.waitForExistence(timeout: 5))
        product.tap()
        let save = app.buttons["ingredient.registration"]
        let delete = app.buttons["ingredient.delete"]
        XCTAssertTrue(save.waitForExistence(timeout: 8))
        XCTAssertTrue(delete.isHittable)
        XCTAssertLessThan(delete.frame.maxX, save.frame.minX)
        keepScreenshot(app, name: "ingredient-report-top")
        for label in ["功效", "成分", "风险", "建议"] {
            let anchor = app.buttons[label]
            if !anchor.isHittable { app.swipeUp() }
            XCTAssertTrue(anchor.isHittable, "Missing report anchor: \(label)")
        }
        app.buttons["风险"].tap()
        XCTAssertTrue(save.isHittable)
        XCTAssertTrue(delete.isHittable)
        keepScreenshot(app, name: "ingredient-report-risks")
        for title in ["成分", "风险", "建议", "成分"] {
            XCTAssertTrue(app.buttons[title].isHittable, "The pinned anchor must remain tappable: \(title)")
            app.buttons[title].tap()
        }
        // The parent section identifier can replace the identifier of a combined heading.
        // Find the actual visible title, as the live report regression does.
        let heading = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "主要成分")).firstMatch
        let headingBelowDirectory = NSPredicate { _, _ in
            heading.exists && heading.frame.minY >= app.buttons["成分"].frame.maxY
                && heading.frame.maxY < save.frame.minY
        }
        let headingVisible = XCTNSPredicateExpectation(predicate: headingBelowDirectory, object: nil)
        let headingResult = XCTWaiter.wait(for: [headingVisible], timeout: 4)
        keepScreenshot(app, name: "ingredient-report-ingredients")
        let geometry = XCTAttachment(string: "heading exists: \(heading.exists)\nheading: \(heading.frame)\nanchor: \(app.buttons["成分"].frame)\nsave: \(save.frame)\n\n\(app.debugDescription)")
        geometry.name = "ingredient-anchor-geometry-and-hierarchy"
        geometry.lifetime = .keepAlways
        add(geometry)
        XCTAssertEqual(headingResult, .completed,
                       "The ingredient heading must remain visible below the pinned directory after tapping its anchor.")
        save.tap()
        XCTAssertTrue(app.buttons["ingredient.registration.save"].waitForExistence(timeout: 5))
        keepScreenshot(app, name: "ingredient-registration-sheet")
    }

    @MainActor
    private func keepScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
