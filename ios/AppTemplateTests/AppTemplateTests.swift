import Testing
import SnapshotTesting
@testable import AppTemplate

/// Scaffold smoke test — proves the unit-test target builds, can `@testable import`
/// the app module, and links swift-snapshot-testing. Real coverage (model methods,
/// store commands, DTO round-trips, render snapshots) arrives in Phase 3.
/// See ios/docs/engineering/07-testing.md.
struct ScaffoldTests {
    @Test func appModuleIsTestable() {
        _ = AppTemplateApp.self
    }
}
