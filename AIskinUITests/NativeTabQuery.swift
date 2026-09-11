import XCTest

extension XCUIApplication {
    /// Query the system tab bar by its public accessibility role and title.
    /// Tests must not depend on the removed custom button implementation.
    @MainActor
    func tabButton(_ index: Int) -> XCUIElement {
        let titles = ["首页", "护肤柜", "肌肤检测", "个性化方案"]
        return tabBars.buttons[titles[index]]
    }
}
