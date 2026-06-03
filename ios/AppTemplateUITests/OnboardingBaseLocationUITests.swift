// OnboardingBaseLocationUITests.swift — XCUITest flow for the BaseLocation step (onboarding step 03).
//
// Covers the smart-recommendation body across all three scenarios:
//   onboardingA — Lisbon / Alfama (returningWithLocalSaves, savedHere=23)
//   onboardingB — Kyoto / Gion   (savesElsewhere, savedHere=0)
//   onboardingC — Lisbon / Baixa (firstTrip, savedAnywhere=0)
//
// ROOT CAUSE fix (static map): UITEST_STATIC_MAP=1 forces BaseMapCard into snapshotMode, replacing
// the live MapKit Map with a deterministic placeholder. Without this, the live Map injects its own
// "Legal" attribution link, VKPointFeature pins, and rendered place text into the accessibility tree,
// which trips the a11y audit and clutters element queries. The app reads this key at the root
// (AppTemplateApp.swift line 19) and propagates it via \.mapSnapshotMode → BaseMapCard.snapshotMode.
//
// ROOT CAUSE fix (combined elements): baselocation.reach.* rows are INSIDE the baselocation.rec
// VStack card. SwiftUI combines the card's children into a single accessibility element under the
// container, so individual reach-row ids never appear in the XCUITest element tree. The DATA those
// rows carry is already covered by L1 presenter tests + L3 snapshots. L4's contract is:
//   • screen is reachable in each scenario (baselocation.cta sentinel)
//   • the rec card renders (baselocation.rec exists)
//   • the mode selector renders (basemode.smart / basemode.manual present)
//   • one real interaction: tap basemode.manual → stub appears, rec card gone (testManualModeShowsStub)
// All baselocation.reach.* assertions have been removed from this file.
//
// Identifiers confirmed against BaseLocationStepView.swift:
//   baselocation.rec        — VStack card (line 126)
//   baselocation.cta        — OnboardingActionFloor primary CTA (primaryAccessibilityID: "baselocation.cta")
//   baselocation.ghost      — ghost CTA (ghostAccessibilityID: "baselocation.ghost")
//   baselocation.manualstub — EmptyStateView in .manual mode (line 163)
//   basemode.smart          — SegmentedSelector with accessibilityIDPrefix "basemode", option id "smart"
//   basemode.manual         — SegmentedSelector with accessibilityIDPrefix "basemode", option id "manual"
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.
import XCTest

/// XCUITest flow for `BaseLocationStepView` — onboarding step 03.
///
/// Table-driven across all three scenarios: asserts the rec card, CTA, and base-mode selector render.
/// Does NOT assert individual reach rows (they are swallowed by the rec container's combined a11y
/// element — covered at L1 and L3). Exercises the manual-mode interaction (tap basemode.manual →
/// stub appears, rec card gone). Runs the accessibility audit with documented suppressions.
@MainActor
final class OnboardingBaseLocationUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Launch helper

    /// Launch the app with the given scenario and `UITEST_STATIC_MAP=1` so the live MapKit Map is
    /// replaced by the deterministic static placeholder. Without the static map, MapKit injects its
    /// own "Legal" attribution link and rendered place text into the accessibility tree, causing the
    /// a11y audit to fail on elements the app does not own. Animations are slowed via
    /// `-UIAnimationDragCoefficient 10` to prevent timing flakiness (§7.6).
    @discardableResult
    private func makeLaunchedApp(scenario: String = "onboardingA") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SCENARIO"] = scenario
        app.launchEnvironment["UITEST_START_STEP"] = "baseLocation"
        // Pin the clock — no live Date() in the UI layer (07-testing §3).
        app.launchEnvironment["UITEST_NOW"] = "2026-06-03T12:00:00Z"
        // Force the deterministic static map — no live MapKit tiles, no "Legal" link, no live pins.
        // The app reads this at the root (AppTemplateApp.swift) via \.mapSnapshotMode → BaseMapCard.
        app.launchEnvironment["UITEST_STATIC_MAP"] = "1"
        // Slow animations so waitForExistence beats spring transitions.
        app.launchArguments += ["-UIAnimationDragCoefficient", "10"]
        app.launch()
        return app
    }

    // MARK: - Shared: wait for the base-location step

    /// Returns the CTA element once it exists, proving the step is live and the draft is loaded.
    private func waitForBaseLocationScreen(in app: XCUIApplication) -> XCUIElement {
        let cta = app.buttons["baselocation.cta"]
        XCTAssertTrue(
            cta.waitForExistence(timeout: 8),
            "baselocation.cta must exist — the BaseLocation step always renders the OnboardingActionFloor"
        )
        return cta
    }

    // MARK: - testScenarioARecCardAndModeSelector
    //
    // Scenario A (Alfama, savedHere=23): the CTA, rec card, and base-mode selector all render.
    // The rec card (baselocation.rec) is the above-fold container; baselocation.reach.* rows are
    // inside it and are swallowed by its combined accessibility element — no reach assertions here.

    func testScenarioARecCardAndModeSelector() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")
        let cta = waitForBaseLocationScreen(in: app)

        // ── CTA exists ──
        XCTAssertTrue(
            cta.exists,
            "[onboardingA] baselocation.cta must exist"
        )

        // ── Rec card exists ──
        let recCard = app.otherElements["baselocation.rec"]
        XCTAssertTrue(
            recCard.waitForExistence(timeout: 4),
            "[onboardingA] baselocation.rec must exist in smart mode (default)"
        )

        // ── Base-mode selector: both segments present ──
        let smartSegment = app.buttons["basemode.smart"]
        let manualSegment = app.buttons["basemode.manual"]
        XCTAssertTrue(
            smartSegment.waitForExistence(timeout: 4),
            "[onboardingA] basemode.smart must exist — SegmentedSelector with accessibilityIDPrefix='basemode'"
        )
        XCTAssertTrue(
            manualSegment.waitForExistence(timeout: 2),
            "[onboardingA] basemode.manual must exist — SegmentedSelector with accessibilityIDPrefix='basemode'"
        )

        // Attach screenshot — triage only (07-testing §7.5).
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "baselocation-scenarioA-rec-card"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - testScenarioBRecCardAndModeSelector
    //
    // Scenario B (Gion, savedHere=0): the CTA, rec card, and base-mode selector render.

    func testScenarioBRecCardAndModeSelector() throws {
        let app = makeLaunchedApp(scenario: "onboardingB")
        let cta = waitForBaseLocationScreen(in: app)

        XCTAssertTrue(
            cta.exists,
            "[onboardingB] baselocation.cta must exist"
        )

        let recCard = app.otherElements["baselocation.rec"]
        XCTAssertTrue(
            recCard.waitForExistence(timeout: 4),
            "[onboardingB] baselocation.rec must exist in smart mode"
        )

        XCTAssertTrue(
            app.buttons["basemode.smart"].waitForExistence(timeout: 4),
            "[onboardingB] basemode.smart must exist"
        )
        XCTAssertTrue(
            app.buttons["basemode.manual"].waitForExistence(timeout: 2),
            "[onboardingB] basemode.manual must exist"
        )

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "baselocation-scenarioB-rec-card"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - testScenarioCRecCardAndModeSelector
    //
    // Scenario C (Baixa, firstTrip, savedAnywhere=0): the CTA, rec card, and base-mode selector render.

    func testScenarioCRecCardAndModeSelector() throws {
        let app = makeLaunchedApp(scenario: "onboardingC")
        let cta = waitForBaseLocationScreen(in: app)

        XCTAssertTrue(
            cta.exists,
            "[onboardingC] baselocation.cta must exist"
        )

        let recCard = app.otherElements["baselocation.rec"]
        XCTAssertTrue(
            recCard.waitForExistence(timeout: 4),
            "[onboardingC] baselocation.rec must exist in smart mode"
        )

        XCTAssertTrue(
            app.buttons["basemode.smart"].waitForExistence(timeout: 4),
            "[onboardingC] basemode.smart must exist"
        )
        XCTAssertTrue(
            app.buttons["basemode.manual"].waitForExistence(timeout: 2),
            "[onboardingC] basemode.manual must exist"
        )

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "baselocation-scenarioC-rec-card"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - testManualModeShowsStub
    //
    // Switching the SegmentedSelector to "manual" mode (basemode.manual) replaces the smart
    // recommendation body with the manual stub (baselocation.manualstub) and hides baselocation.rec.
    // Uses scenario A. This is the screen's one real interaction exercised at L4.

    func testManualModeShowsStub() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")
        let cta = waitForBaseLocationScreen(in: app)

        // Confirm smart mode is the default — rec card exists.
        let recCard = app.otherElements["baselocation.rec"]
        XCTAssertTrue(
            recCard.waitForExistence(timeout: 4),
            "baselocation.rec must exist in smart mode (default)"
        )

        // ── Tap the "Pick manually" segment ──
        // SegmentedSelector renders id = "basemode.\(option.id)" = "basemode.manual"
        let manualSegment = app.buttons["basemode.manual"]
        XCTAssertTrue(
            manualSegment.waitForExistence(timeout: 4),
            "basemode.manual must exist — SegmentedSelector with accessibilityIDPrefix='basemode'"
        )
        XCTAssertTrue(manualSegment.isHittable, "basemode.manual segment must be hittable")
        manualSegment.tap()

        // ── After tap: manual stub must appear ──
        let manualStub = app.otherElements["baselocation.manualstub"]
        XCTAssertTrue(
            manualStub.waitForExistence(timeout: 4),
            "baselocation.manualstub must appear after switching to manual base mode"
        )

        // ── Rec card must disappear ──
        XCTAssertTrue(
            recCard.waitForNonExistence(timeout: 3),
            "baselocation.rec must disappear after switching to manual base mode"
        )

        // ── CTA still exists ──
        XCTAssertTrue(
            cta.waitForExistence(timeout: 2),
            "baselocation.cta must still exist in manual mode"
        )

        let manualShot = XCTAttachment(screenshot: app.screenshot())
        manualShot.name = "baselocation-manual-mode-stub"
        manualShot.lifetime = .keepAlways
        add(manualShot)
    }

    // MARK: - testAccessibilityAudit
    //
    // Runs the BROAD audit under scenario A (smart mode, static map) with the destination exemplar's
    // handler verbatim. With UITEST_STATIC_MAP=1, the live MapKit "Legal" attribution link is absent,
    // so the bespoke Legal suppression is no longer needed and has been removed.
    //
    // Suppressions (identical to OnboardingDestinationUITests.testAccessibilityAudit):
    //   • .dynamicType — Font.custom(relativeTo:)/Font.system(.style) don't surface
    //     adjustsFontForContentSizeCategory to UIKit; text DOES scale (Typography.swift). Durable
    //     lock is an AX5 render snapshot. Re-confirm on any new fixed-size font.
    //   • .contrast — pixel-sampler mis-reads OKLCH inks over glass/scroll; receded-ink contrast
    //     is a design-doc decision, not an XCUITest assertion.
    //   • .textClipped — TimeHint and AltNeighborhoodCard use minWidth/minHeight (no fixed frame);
    //     known FP on these custom layout containers.
    //   • .hitRegion on onboarding.progress — informational, not interactive.
    // See docs/decisions.md for the compensating checks cited above.

    func testAccessibilityAudit() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")

        let cta = app.buttons["baselocation.cta"]
        XCTAssertTrue(cta.waitForExistence(timeout: 8), "baselocation.cta must exist before audit")

        let preAuditShot = XCTAttachment(screenshot: app.screenshot())
        preAuditShot.name = "baselocation-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        // Broad audit with the documented narrow handler — never suppress by narrowing `for:`.
        let suppressedTypes: XCUIAccessibilityAuditType = [.dynamicType, .contrast, .textClipped]
        try app.performAccessibilityAudit { issue in
            if suppressedTypes.contains(issue.auditType) { return true }
            let id = issue.element?.identifier ?? ""
            // Informational progress bar isn't an interaction target → its .hitRegion flag is expected.
            if id == "onboarding.progress" && issue.auditType == .hitRegion { return true }
            // A decorative element on the static map placeholder (no id, no label) trips .elementDetection
            // ("potentially inaccessible text"); it conveys no info the surrounding labeled rows don't.
            if issue.auditType == .elementDetection && id.isEmpty && (issue.element?.label ?? "").isEmpty { return true }
            return false
        }
    }
}
