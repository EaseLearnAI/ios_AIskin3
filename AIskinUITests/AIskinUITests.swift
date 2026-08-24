//
//  AIskinUITests.swift
//  AIskinUITests
//
//  Created by terry on 2025/11/3.
//

import XCTest

final class AIskinUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testForgotPasswordFlowShowsCompleteResetForm() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingResetSession"]
        app.launch()

        XCTAssertTrue(app.staticTexts["欢迎回来"].waitForExistence(timeout: 5))

        let forgotPasswordButton = app.buttons["忘记密码？"]
        XCTAssertTrue(forgotPasswordButton.exists)
        forgotPasswordButton.tap()

        XCTAssertTrue(app.staticTexts["找回密码"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["请输入注册手机号"].exists)
        XCTAssertTrue(app.textFields["6位短信验证码"].exists)
        XCTAssertTrue(app.buttons["获取验证码"].exists)
        XCTAssertTrue(app.buttons["确认修改密码"].exists)

        app.buttons["确认修改密码"].tap()
        XCTAssertTrue(app.staticTexts["请输入手机号"].exists)
        XCTAssertTrue(app.staticTexts["请输入6位短信验证码"].exists)
        XCTAssertTrue(app.staticTexts["密码长度至少6个字符"].exists)
        XCTAssertTrue(app.staticTexts["请再次输入新密码"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
