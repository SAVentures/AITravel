import XCTest

/// Scaffold UI smoke test — proves the UITest target builds and can launch the app
/// against the (future) MockProvider scenarios. Real flows arrive in Phase 3.
/// See ios/docs/engineering/07-testing.md §7.
final class AppTemplateUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
}
