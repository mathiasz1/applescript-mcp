import XCTest

final class FamilyAppUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAppLaunchesAndShowsSidebar() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Dashboard"].waitForExistence(timeout: 5),
            "Expected the Dashboard sidebar entry to be visible on launch."
        )
    }
}
