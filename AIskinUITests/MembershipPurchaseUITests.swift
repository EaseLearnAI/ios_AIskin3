import XCTest

final class MembershipPurchaseUITests: XCTestCase {
    @MainActor
    func testUnavailablePaymentShowsServerCatalogWithoutAllowingCheckout() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AISkinUseMockBackend"]
        app.launch()
        let profile = app.buttons["app.header.profile"]
        XCTAssertTrue(profile.waitForExistence(timeout: 10))
        profile.tap()
        let upgrade = app.buttons["profile.upgrade"]
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5))
        upgrade.tap()

        let yearly = app.buttons["membership.period.year"]
        XCTAssertTrue(yearly.waitForExistence(timeout: 5))
        let priceLoaded = NSPredicate(format: "label CONTAINS %@", "¥88")
        expectation(for: priceLoaded, evaluatedWith: yearly)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(yearly.label.contains("单次付款"))
        XCTAssertFalse(yearly.label.contains("连续包年"))
        yearly.tap()
        XCTAssertTrue(yearly.isSelected)
        XCTAssertFalse(app.buttons["membership.subscribe"].isEnabled)

        app.buttons["membership.restore"].tap()
        let status = app.descendants(matching: .any)["membership.payment-status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["membership.active"].exists)
        XCTAssertFalse(app.alerts["确认购买"].exists)

        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Membership - unavailable payment and server catalog"
        image.lifetime = .keepAlways
        add(image)
    }
}
