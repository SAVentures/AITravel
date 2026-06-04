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
//   • manual-mode interaction: tap basemode.manual → rec card gone, first baselocation.manual.* Button
//     appears (baselocation.manualpicker VStack is NOT queryable), a row is selectable → CTA enabled
//   • ghost-button interaction: tap baselocation.ghost → addresspicker.search appears (sheet proven);
//     Map NOT asserted (SwiftUI Map unreliable in XCUITest); cancel → sheet dismissed
// All baselocation.reach.* assertions have been removed from this file.
//
// Identifiers confirmed against BaseLocationStepView.swift:
//   baselocation.rec          — VStack card (.cardSurface, line 146)
//   baselocation.cta          — OnboardingActionFloor primary CTA (line 30)
//   baselocation.ghost        — ghost CTA that opens ManualAddressPickerSheet (line 33)
//   baselocation.manualpicker — VStack wrapping neighborhood rows (line 187); NOT queryable in XCUITest
//                               (plain VStack, no .accessibilityElement(children:)) — NOT asserted
//   baselocation.manual.<id>  — individual neighborhood row buttons (line 271); ARE queryable and asserted
//   basemode.smart            — SegmentedSelector segment, accessibilityIDPrefix "basemode" (line 116)
//   basemode.manual           — SegmentedSelector segment, accessibilityIDPrefix "basemode" (line 116)
//
// Identifiers confirmed against ManualAddressPickerSheet.swift:
//   addresspicker.map         — MapReader Map element (line 72); NOT queryable in XCUITest
//                               (SwiftUI Map doesn't reliably surface as an element) — NOT asserted
//   addresspicker.search      — SearchWell's inner TextField (line 97); TextField carries .isSearchField
//                               → resolves as app.searchFields["addresspicker.search"]
//   addresspicker.cancel      — Cancel toolbar button (line 48)
//   addresspicker.use         — "Use this location" confirm bar (line 173)
//   addresspicker.result.<id> — result rows (live MKLocalSearch — NOT asserted in tests)
//
// C1 migration (Wave C): file-local makeLaunchedApp / scrollToElement / inline audit handler deleted;
// all three replaced by OnboardingRobot. UITEST_STATIC_MAP=1 is forwarded via robot.launch(staticMap: true).
// C5 (forwarding): UITEST_FAILURE_RATE is no longer forwarded locally; the robot owns it via its
// optional failureRate param — passing nil (default) means the key is absent, which is the same
// unconsumed-seam behavior as before (see docs/decisions.md Task C5 entry).
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.
import XCTest

/// XCUITest flow for `BaseLocationStepView` — onboarding step 03.
///
/// Table-driven across all three scenarios: asserts the rec card, CTA, and base-mode selector render.
/// Does NOT assert individual reach rows (they are swallowed by the rec container's combined a11y
/// element — covered at L1 and L3). Exercises the manual-mode interaction (tap basemode.manual →
/// neighborhood picker appears, rec card gone, a row is selectable → CTA enabled). Exercises the
/// ghost-button sheet (tap baselocation.ghost → addresspicker.search appears proving presentation;
/// Map NOT queried — SwiftUI Map not reliably queryable in XCUITest; tap addresspicker.cancel →
/// sheet dismissed). Runs the accessibility audit with documented suppressions.
@MainActor
final class OnboardingBaseLocationUITests: XCTestCase {

    private var robot: OnboardingRobot!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        robot = OnboardingRobot()
    }

    override func tearDown() {
        robot.app.terminate()
        robot = nil
        super.tearDown()
    }

    // MARK: - Shared: wait for the base-location step

    /// Returns the CTA element once it exists, proving the step is live and the draft is loaded.
    private func waitForBaseLocationScreen() -> XCUIElement {
        let cta = robot.app.buttons["baselocation.cta"]
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
        robot.launch(scenario: "onboardingA", startStep: "baseLocation", staticMap: true)
        let cta = waitForBaseLocationScreen()

        // ── CTA exists ──
        XCTAssertTrue(
            cta.exists,
            "[onboardingA] baselocation.cta must exist"
        )

        // ── Rec card exists ──
        let recCard = robot.app.otherElements["baselocation.rec"]
        XCTAssertTrue(
            recCard.waitForExistence(timeout: 4),
            "[onboardingA] baselocation.rec must exist in smart mode (default)"
        )

        // ── Base-mode selector: both segments present ──
        let smartSegment = robot.app.buttons["basemode.smart"]
        let manualSegment = robot.app.buttons["basemode.manual"]
        XCTAssertTrue(
            smartSegment.waitForExistence(timeout: 4),
            "[onboardingA] basemode.smart must exist — SegmentedSelector with accessibilityIDPrefix='basemode'"
        )
        XCTAssertTrue(
            manualSegment.waitForExistence(timeout: 2),
            "[onboardingA] basemode.manual must exist — SegmentedSelector with accessibilityIDPrefix='basemode'"
        )

        // Attach screenshot — triage only (07-testing §7.5).
        let shot = XCTAttachment(screenshot: robot.app.screenshot())
        shot.name = "baselocation-scenarioA-rec-card"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - testScenarioBRecCardAndModeSelector
    //
    // Scenario B (Gion, savedHere=0): the CTA, rec card, and base-mode selector render.

    func testScenarioBRecCardAndModeSelector() throws {
        robot.launch(scenario: "onboardingB", startStep: "baseLocation", staticMap: true)
        let cta = waitForBaseLocationScreen()

        XCTAssertTrue(
            cta.exists,
            "[onboardingB] baselocation.cta must exist"
        )

        let recCard = robot.app.otherElements["baselocation.rec"]
        XCTAssertTrue(
            recCard.waitForExistence(timeout: 4),
            "[onboardingB] baselocation.rec must exist in smart mode"
        )

        XCTAssertTrue(
            robot.app.buttons["basemode.smart"].waitForExistence(timeout: 4),
            "[onboardingB] basemode.smart must exist"
        )
        XCTAssertTrue(
            robot.app.buttons["basemode.manual"].waitForExistence(timeout: 2),
            "[onboardingB] basemode.manual must exist"
        )

        let shot = XCTAttachment(screenshot: robot.app.screenshot())
        shot.name = "baselocation-scenarioB-rec-card"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - testScenarioCRecCardAndModeSelector
    //
    // Scenario C (Baixa, firstTrip, savedAnywhere=0): the CTA, rec card, and base-mode selector render.

    func testScenarioCRecCardAndModeSelector() throws {
        robot.launch(scenario: "onboardingC", startStep: "baseLocation", staticMap: true)
        let cta = waitForBaseLocationScreen()

        XCTAssertTrue(
            cta.exists,
            "[onboardingC] baselocation.cta must exist"
        )

        let recCard = robot.app.otherElements["baselocation.rec"]
        XCTAssertTrue(
            recCard.waitForExistence(timeout: 4),
            "[onboardingC] baselocation.rec must exist in smart mode"
        )

        XCTAssertTrue(
            robot.app.buttons["basemode.smart"].waitForExistence(timeout: 4),
            "[onboardingC] basemode.smart must exist"
        )
        XCTAssertTrue(
            robot.app.buttons["basemode.manual"].waitForExistence(timeout: 2),
            "[onboardingC] basemode.manual must exist"
        )

        let shot = XCTAttachment(screenshot: robot.app.screenshot())
        shot.name = "baselocation-scenarioC-rec-card"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - testManualModeShowsNeighborhoodPicker
    //
    // Switching the SegmentedSelector to "manual" mode (basemode.manual) hides baselocation.rec and
    // shows the neighborhood picker. baselocation.manualpicker (plain VStack) is NOT queryable in
    // XCUITest — instead we wait for the first baselocation.manual.* Button, which proves the picker
    // rendered. Tapping the first neighborhood row (predicate BEGINSWITH 'baselocation.manual.')
    // enables the CTA. Uses scenario A. This is the screen's primary write-path interaction at L4.
    //
    // Note: baselocation.manual.pinned is intentionally excluded from the BEGINSWITH predicate match
    // because that row only appears when a specific address has already been pinned via the ghost sheet;
    // in the default launch state no address is pinned so only neighborhood rows exist. The predicate
    // correctly matches only baselocation.manual.<neighborhoodId> rows.

    func testManualModeShowsNeighborhoodPicker() throws {
        robot.launch(scenario: "onboardingA", startStep: "baseLocation", staticMap: true)
        let cta = waitForBaseLocationScreen()

        // ── Confirm smart mode is default — rec card exists ──
        let recCard = robot.app.otherElements["baselocation.rec"]
        XCTAssertTrue(
            recCard.waitForExistence(timeout: 4),
            "baselocation.rec must exist in smart mode (default)"
        )

        // ── Tap the "Pick manually" segment ──
        // SegmentedSelector renders id = "basemode.\(option.id)" = "basemode.manual"
        let manualSegment = robot.app.buttons["basemode.manual"]
        XCTAssertTrue(
            manualSegment.waitForExistence(timeout: 4),
            "basemode.manual must exist — SegmentedSelector with accessibilityIDPrefix='basemode'"
        )
        XCTAssertTrue(manualSegment.isHittable, "basemode.manual segment must be hittable")
        manualSegment.tap()

        // ── After tap: baselocation.rec must be gone ──
        XCTAssertTrue(
            recCard.waitForNonExistence(timeout: 3),
            "baselocation.rec must disappear after switching to manual mode"
        )

        // ── At least one neighborhood row must appear — proves manual mode rendered ──
        // baselocation.manualpicker is a plain VStack and never surfaces as a queryable otherElements
        // node in XCUITest (no .accessibilityElement(children:) wrapper). The neighborhood row Buttons
        // ARE real interactive elements and DO appear; waiting for the first one is the correct sentinel.

        // ── At least one neighborhood row must exist (predicate, never hardcoded id) ──
        // Rows are rendered as buttons with id = "baselocation.manual.<neighborhoodId>".
        // We exclude the pinned row (baselocation.manual.pinned) which only appears after a specific
        // address has been chosen via the ghost sheet — not present at initial launch.
        let neighborhoodPredicate = NSPredicate(format: "identifier BEGINSWITH 'baselocation.manual.'")
        let neighborhoodRows = robot.app.descendants(matching: .any).matching(neighborhoodPredicate)
        // Wait for the first row to appear — this is the waitable sentinel that proves manual mode
        // rendered. The count check that follows is synchronous so we must wait first.
        // .any-type query: rows use .accessibilityElement(children: .combine) so XCUITest may
        // classify them as a non-button element type; app.buttons misses them. descendants(matching: .any)
        // matches regardless of how the combined element is classified.
        XCTAssertTrue(
            neighborhoodRows.firstMatch.waitForExistence(timeout: 4),
            "At least one neighborhood row (id BEGINSWITH 'baselocation.manual.') must appear in manual mode"
        )

        let manualPickerShot = XCTAttachment(screenshot: robot.app.screenshot())
        manualPickerShot.name = "baselocation-manual-mode-picker"
        manualPickerShot.lifetime = .keepAlways
        add(manualPickerShot)

        // ── Tap the first neighborhood row ──
        let firstRow = neighborhoodRows.element(boundBy: 0)
        XCTAssertTrue(firstRow.isHittable, "First neighborhood row must be hittable")
        firstRow.tap()

        // ── After selection: CTA must be enabled ──
        XCTAssertTrue(
            cta.waitForExistence(timeout: 2),
            "baselocation.cta must still exist after tapping a neighborhood row"
        )
        XCTAssertTrue(
            cta.isEnabled,
            "baselocation.cta must be enabled after a neighborhood is selected"
        )

        // ── CTA label starts with "Use " (stable text from presenter.ctaTitle, if reachable) ──
        // Guard: only assert the label when the element exposes it (not all button proxies surface .label
        // on first access; the isEnabled check above is the load-bearing signal).
        let ctaLabel = cta.label
        if !ctaLabel.isEmpty {
            XCTAssertTrue(
                ctaLabel.hasPrefix("Use "),
                "baselocation.cta label should start with 'Use ' after a neighborhood selection, got: '\(ctaLabel)'"
            )
        }

        let postSelectionShot = XCTAttachment(screenshot: robot.app.screenshot())
        postSelectionShot.name = "baselocation-manual-mode-row-selected"
        postSelectionShot.lifetime = .keepAlways
        add(postSelectionShot)
    }

    // MARK: - testManualBaseCTADisabledBeforePick (C4)
    //
    // Asserts that baselocation.cta is DISABLED immediately after entering manual mode (basemode.manual)
    // but BEFORE any baselocation.manual.<id> row is tapped. The CTA is gated by presenter.canContinue
    // (BaseLocationStepView.swift line 29), which requires a neighborhood selection in manual mode.
    //
    // Manual-mode entry: tap "basemode.manual" — the SegmentedSelector segment confirmed in
    // BaseLocationStepView.swift (line 116, accessibilityIDPrefix: "basemode"). "basemode.manual" is
    // the stable existing a11y id; no new production id was needed (Track A is test-only).
    //
    // After confirming the disabled state, tapping the first available neighborhood row proves the gate
    // becomes enabled (CTA.isEnabled transitions from false → true on pick).

    func testManualBaseCTADisabledBeforePick() throws {
        robot.launch(scenario: "onboardingA", startStep: "baseLocation", staticMap: true)

        // ── Wait for the step to be live ──
        let cta = robot.app.buttons["baselocation.cta"]
        XCTAssertTrue(
            cta.waitForExistence(timeout: 8),
            "baselocation.cta must exist — BaseLocation step always renders the OnboardingActionFloor"
        )

        // ── Enter manual mode by tapping the "Pick manually" segment ──
        // Confirmed in BaseLocationStepView.swift line 116: accessibilityIDPrefix "basemode",
        // so the manual segment renders as "basemode.manual".
        let manualSegment = robot.app.buttons["basemode.manual"]
        XCTAssertTrue(
            manualSegment.waitForExistence(timeout: 4),
            "basemode.manual must exist — SegmentedSelector with accessibilityIDPrefix='basemode'"
        )
        XCTAssertTrue(manualSegment.isHittable, "basemode.manual segment must be hittable before tap")
        manualSegment.tap()

        // ── Wait for at least one neighborhood row to appear (manual mode rendered) ──
        // This ensures we are in manual mode and the picker is present before checking CTA state.
        let neighborhoodPredicate = NSPredicate(format: "identifier BEGINSWITH 'baselocation.manual.'")
        let neighborhoodRows = robot.app.descendants(matching: .any).matching(neighborhoodPredicate)
        XCTAssertTrue(
            neighborhoodRows.firstMatch.waitForExistence(timeout: 4),
            "At least one neighborhood row must appear — proves manual mode rendered before CTA check"
        )

        // ── Assert CTA exists but is DISABLED before any row pick ──
        XCTAssertTrue(cta.exists, "baselocation.cta must still exist after entering manual mode")
        XCTAssertFalse(
            cta.isEnabled,
            "baselocation.cta must be DISABLED in manual mode before any neighborhood row is tapped"
        )

        let prePickShot = XCTAttachment(screenshot: robot.app.screenshot())
        prePickShot.name = "baselocation-manual-cta-disabled-pre-pick"
        prePickShot.lifetime = .keepAlways
        add(prePickShot)

        // ── Tap the first neighborhood row — proves the gate (disabled → enabled transition) ──
        let firstRow = neighborhoodRows.element(boundBy: 0)
        XCTAssertTrue(firstRow.isHittable, "First neighborhood row must be hittable")
        firstRow.tap()

        XCTAssertTrue(
            cta.waitForExistence(timeout: 2),
            "baselocation.cta must remain after a neighborhood row tap"
        )
        XCTAssertTrue(
            cta.isEnabled,
            "baselocation.cta must be ENABLED after a neighborhood row is tapped"
        )

        let postPickShot = XCTAttachment(screenshot: robot.app.screenshot())
        postPickShot.name = "baselocation-manual-cta-enabled-post-pick"
        postPickShot.lifetime = .keepAlways
        add(postPickShot)
    }

    // MARK: - testGhostButtonOpensAddressPickerSheet
    //
    // Tapping baselocation.ghost opens ManualAddressPickerSheet. Sheet PRESENTATION is proven by
    // addresspicker.search existing (SearchWell's TextField carries .isSearchField → resolves as
    // app.searchFields["addresspicker.search"]). addresspicker.map is NOT asserted — a SwiftUI Map
    // does not reliably surface as a queryable XCUITest element.
    // CANCEL: tap addresspicker.cancel → addresspicker.search gone (sheet dismissed).
    //
    // IMPORTANT: No query is typed and no addresspicker.result.* rows are asserted — MKLocalSearch
    // and CLGeocoder are live, non-deterministic services. Asserting their output would make the test
    // environment-dependent and flaky (§3 determinism rule). Sheet presentation + dismiss is the full
    // contract for L4.

    func testGhostButtonOpensAddressPickerSheet() throws {
        robot.launch(scenario: "onboardingA", startStep: "baseLocation", staticMap: true)
        _ = waitForBaseLocationScreen()

        // ── Ghost button must exist ──
        let ghostButton = robot.app.buttons["baselocation.ghost"]
        XCTAssertTrue(
            ghostButton.waitForExistence(timeout: 4),
            "baselocation.ghost must exist — OnboardingActionFloor ghost CTA"
        )
        XCTAssertTrue(ghostButton.isHittable, "baselocation.ghost must be hittable")

        // ── Tap ghost → sheet appears ──
        ghostButton.tap()

        // ── Sheet content: search well must appear ──
        // SearchWell owns the .isSearchField trait on the inner TextField (SearchWell.swift line 67).
        // No .combine wrapper — the TextField is an independent a11y element. The caller-supplied
        // accessibilityID ("addresspicker.search") is stamped directly on the TextField via
        // OptionalAccessibilityID, so the field resolves cleanly as app.searchFields["addresspicker.search"].
        let searchWell = robot.app.searchFields["addresspicker.search"]
        XCTAssertTrue(
            searchWell.waitForExistence(timeout: 6),
            "addresspicker.search must exist as a searchField after tapping baselocation.ghost"
        )

        // addresspicker.map is NOT queried: a SwiftUI Map does not reliably expose as a queryable
        // element in XCUITest. Sheet presentation is fully proven by addresspicker.search existing
        // (the search-well block above). The map's visual fidelity is a render-snapshot concern (§6),
        // not an XCUITest assertion.

        let sheetShot = XCTAttachment(screenshot: robot.app.screenshot())
        sheetShot.name = "baselocation-address-picker-sheet"
        sheetShot.lifetime = .keepAlways
        add(sheetShot)

        // ── Tap Cancel → sheet is dismissed ──
        let cancelButton = robot.app.buttons["addresspicker.cancel"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 4),
            "addresspicker.cancel must exist in the sheet toolbar"
        )
        cancelButton.tap()

        // ── After dismiss: search well must be gone ──
        XCTAssertTrue(
            searchWell.waitForNonExistence(timeout: 4),
            "addresspicker.search must be gone after tapping addresspicker.cancel"
        )

        let postDismissShot = XCTAttachment(screenshot: robot.app.screenshot())
        postDismissShot.name = "baselocation-address-picker-dismissed"
        postDismissShot.lifetime = .keepAlways
        add(postDismissShot)
    }

    // MARK: - testAccessibilityAudit
    //
    // Runs the BROAD audit under scenario A (smart mode, static map) via the robot's centralized
    // performOnboardingAudit(extraSuppressions:). The extra suppression for the decorative
    // empty-id .elementDetection element on the static map placeholder is passed inline — it is
    // NOT widened into the common suppression set (per OnboardingRobot design contract).
    //
    // Extra suppression (BaseLocation-specific):
    //   • .elementDetection on an element with no id and no label — a decorative element on the
    //     static map placeholder ("potentially inaccessible text"); it conveys no info the
    //     surrounding labeled rows don't. Confirmed in the original inline audit handler.
    //
    // Common suppression set (centralized in OnboardingRobot.performOnboardingAudit):
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
        robot.launch(scenario: "onboardingA", startStep: "baseLocation", staticMap: true)

        let cta = robot.app.buttons["baselocation.cta"]
        XCTAssertTrue(cta.waitForExistence(timeout: 8), "baselocation.cta must exist before audit")

        let preAuditShot = XCTAttachment(screenshot: robot.app.screenshot())
        preAuditShot.name = "baselocation-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        // Broad audit via the robot — extra suppression for the decorative static-map placeholder element.
        // The common suppression set (.dynamicType, .contrast, .textClipped, onboarding.progress .hitRegion)
        // is centralized in OnboardingRobot.performOnboardingAudit; only the BaseLocation-specific
        // exemption is passed here (07-testing §7.4 — never blanket-suppress).
        try robot.performOnboardingAudit {
            $0.auditType == .elementDetection
                && ($0.element?.identifier ?? "").isEmpty
                && ($0.element?.label ?? "").isEmpty
        }

        // Also exercise manual mode for the audit: switch to manual and re-audit the picker rows.
        // Manual mode is reachable from smart mode via the segment tap (same screen, no navigation).
        let manualSegment = robot.app.buttons["basemode.manual"]
        if manualSegment.waitForExistence(timeout: 4), manualSegment.isHittable {
            manualSegment.tap()
            // baselocation.manualpicker (plain VStack) is not queryable; wait for the first
            // neighborhood row button instead — that's the real signal that manual mode rendered.
            let manualNeighborhoodPredicate = NSPredicate(format: "identifier BEGINSWITH 'baselocation.manual.'")
            if robot.app.descendants(matching: .any).matching(manualNeighborhoodPredicate).firstMatch.waitForExistence(timeout: 4) {
                let postManualShot = XCTAttachment(screenshot: robot.app.screenshot())
                postManualShot.name = "baselocation-pre-audit-manual-mode"
                postManualShot.lifetime = .keepAlways
                add(postManualShot)

                // Second audit pass in manual mode — same extra suppression as the first pass.
                try robot.performOnboardingAudit {
                    $0.auditType == .elementDetection
                        && ($0.element?.identifier ?? "").isEmpty
                        && ($0.element?.label ?? "").isEmpty
                }
            }
        }
    }
}
