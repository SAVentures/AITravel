// OnboardingDestinationUITests.swift — XCUITest flow for the Destination step (onboarding step 01).
//
// Locks the final behavior after the search-mode redesign: focusing the search field clears the
// prior city selection (so the CTA hides), and the Recent rail + grid are replaced by a result
// list (`destination.result.<cityId>`) while the keyboard is up. Tapping a result row commits the
// city, dismisses search, and the CTA reappears. This flow drives the real app via launchEnvironment
// scenario injection and queries exclusively by accessibility identifier — never by displayed text
// (locale-sensitive).
//
// NOTE: the Recent rail (recentRail / recentChip helpers) was REMOVED from DestinationStepView.
// The `rail.recent.<cityId>` accessibility identifiers no longer exist in the view source.
// testRecentPillSelectsCity was deleted (it queried a removed affordance).
//
// Scenario: UITEST_SCENARIO=onboardingA
//   • Destination: Lisbon (city-lisbon), pre-selected (savedHere = 23 → returningWithLocalSaves)
//   • City options (grid): Lisbon · Tokyo (city-tokyo) · Mexico City (city-mexico-city) · Marrakech (city-marrakech)
//   • CTA title: "Continue with Lisbon" initially
//
// Identifiers confirmed against live View source (DestinationStepView.swift, SearchWell.swift):
//   destination.cta              — primary CTA button (OnboardingActionFloor actions: slot, line 83)
//                                  HIDDEN when store.onboarding?.destination == nil (search focused)
//   destination.city.<cityId>    — each grid tile Button (line 326); NORMAL mode only
//   destination.search           — id on the SearchWell's inner TextField (SearchWell.swift line 69);
//                                  the TextField carries .isSearchField → resolves as app.searchFields
//   destination.result.<cityId>  — each result-list row Button (line 216); SEARCH mode only
//   onboarding.close             — floating GlassCircleButton × (line 131)
//
// Search-mode lifecycle (confirmed in DestinationStepView.swift):
//   focus acquired → .onChange(of: searchFocused) calls store.onboarding?.clearDestination()
//                 → destination == nil → actions: slot renders EmptyView → destination.cta hidden
//   isSearching == true → searchWell() + resultsList(presenter) replace hero/rail/grid
//   result row tap → select(city:) + searchFocused=false + searchText="" + advanceOnboardingStep()
//                 → step ADVANCES to Trip Shape (destination screen leaves; tripshape.cta appears)
//
// City ids confirmed against SampleData+Onboarding.swift:
//   "city-lisbon", "city-tokyo", "city-mexico-city", "city-marrakech"
//
// Launch/scroll/audit boilerplate is centralized in OnboardingRobot (Support/OnboardingRobot.swift).
// This suite does NOT set UITEST_FAILURE_RATE (no write command yet; robot's failureRate: nil default).
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.
import XCTest

/// XCUITest flow for `DestinationStepView` — the onboarding destination picker (step 01).
///
/// Tests the final behavior: normal-mode grid selection updates the CTA; entering search mode
/// clears the selection so the CTA hides; typing filters the result list; tapping a result row
/// calls select(city:) + advanceOnboardingStep() — the step advances to Trip Shape (destination
/// screen exits, tripshape.cta appears). Also runs the accessibility audit with a narrow documented exemption.
/// Note: the Recent rail (recentRail / recentChip) was removed from DestinationStepView —
/// testRecentPillSelectsCity was deleted because rail.recent.* identifiers no longer exist.
@MainActor
final class OnboardingDestinationUITests: XCTestCase {

    // MARK: - Robot

    /// Shared robot — owns launch, scroll, and audit boilerplate for all onboarding UITest suites.
    /// Initialized in setUp so each test gets a fresh XCUIApplication via the robot's init().
    private var robot = OnboardingRobot()

    override func setUp() {
        super.setUp()
        robot = OnboardingRobot()
        // Stop on first failure — subsequent assertions are meaningless if the destination screen
        // does not reach the expected state.
        continueAfterFailure = false
    }

    // MARK: - Shared: wait for the destination screen

    /// Returns the CTA element once it exists, or fails the test.
    /// The CTA is the most reliable sentinel for the destination screen being live and a city selected.
    private func waitForDestinationScreen() -> XCUIElement {
        let cta = robot.app.buttons["destination.cta"]
        XCTAssertTrue(
            cta.waitForExistence(timeout: 8),
            "destination.cta must exist — onboardingA seeds Lisbon as the pre-selected city"
        )
        return cta
    }

    // MARK: - testGridTileSelectsCity
    //
    // Verifies that tapping a non-selected grid tile (id `destination.city.<cityId>`) selects that
    // city and updates the CTA. Grid tiles exist in NORMAL mode only.

    func testGridTileSelectsCity() throws {
        robot.launch(scenario: "onboardingA")
        let cta = waitForDestinationScreen()

        // The Mexico City grid tile is non-selected in scenario A (only Lisbon starts selected).
        // id: destination.city.city-mexico-city  (SampleData.mexicoCityCity() → id = "city-mexico-city")
        // It sits in the grid's SECOND row, below the fold — scroll it into the realized tree first.
        let mexicoTile = robot.app.buttons["destination.city.city-mexico-city"]
        robot.scrollToElement(mexicoTile)
        XCTAssertTrue(
            mexicoTile.waitForExistence(timeout: 4),
            "destination.city.city-mexico-city must exist in the grid for scenario A (normal mode)"
        )
        XCTAssertTrue(mexicoTile.isHittable, "Mexico City grid tile must be hittable")
        mexicoTile.tap()

        // CTA must now contain "Mexico City".
        let mexicoPredicate = NSPredicate(format: "label CONTAINS[cd] 'Mexico City'")
        let mexicoExpectation = XCTNSPredicateExpectation(predicate: mexicoPredicate, object: cta)
        let result = XCTWaiter.wait(for: [mexicoExpectation], timeout: 4)
        XCTAssertEqual(
            result, .completed,
            "CTA label must contain 'Mexico City' after tapping the Mexico City grid tile; got '\(cta.label)'"
        )

        // The Lisbon tile must still be in the catalog — selection changes, catalog does not shrink.
        // It is the grid's FIRST tile; after scrolling down to Mexico City it may have recycled off the
        // top of the LazyVGrid, so scroll back up to it before asserting (a realization check, not a
        // visibility one).
        let lisbonTile = robot.app.buttons["destination.city.city-lisbon"]
        var upSwipes = 0
        while !lisbonTile.exists && upSwipes < 6 {
            robot.app.swipeDown()
            upSwipes += 1
        }
        XCTAssertTrue(
            lisbonTile.waitForExistence(timeout: 2),
            "destination.city.city-lisbon must still exist after selecting a different city (normal mode)"
        )

        // Attach screenshot.
        let shot = XCTAttachment(screenshot: robot.app.screenshot())
        shot.name = "destination-after-mexico-city-grid-tap"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - testSearchClearsSelectionAndFilters
    //
    // Verifies the full search-mode lifecycle:
    //   1. CTA exists initially (Lisbon pre-selected).
    //   2. Tapping the search field clears the selection → CTA disappears (destination == nil).
    //   3. Typing "Tok" filters the result list:
    //        destination.result.city-tokyo   EXISTS   (matches "Tokyo")
    //        destination.result.city-lisbon  does NOT exist  (no match)
    //   4. Tapping destination.result.city-tokyo calls resultRow: select(city:) + clear search +
    //      advanceOnboardingStep() — the step ADVANCES to Trip Shape. We left the destination
    //      step (destination.search no longer exists) and landed on Trip Shape (tripshape.cta exists).
    //
    // Replaces the old testSearchFiltersCities which incorrectly asserted against grid/rail ids in
    // search mode — those elements are replaced by destination.result.* rows in search mode
    // (DestinationStepView.swift line 95–107: isSearching → searchWell() + resultsList(presenter)).

    func testSearchClearsSelectionAndFilters() throws {
        robot.launch(scenario: "onboardingA")
        let cta = waitForDestinationScreen()

        // ── 1. Initial state: CTA exists and contains "Lisbon" ──
        XCTAssertTrue(
            cta.label.localizedCaseInsensitiveContains("Lisbon"),
            "CTA label must contain 'Lisbon' initially; got '\(cta.label)'"
        )

        let preSearchShot = XCTAttachment(screenshot: robot.app.screenshot())
        preSearchShot.name = "destination-pre-search-lisbon-selected"
        preSearchShot.lifetime = .keepAlways
        add(preSearchShot)

        // ── 2. Tap the search field — clears selection, CTA must disappear ──
        // SearchWell owns the .isSearchField trait on the inner TextField (SearchWell.swift line 67).
        // No .combine wrapper on the outer HStack — the TextField is an independent a11y element.
        // The caller-supplied accessibilityID ("destination.search") is stamped directly on the TextField
        // via OptionalAccessibilityID, so the field resolves cleanly as app.searchFields["destination.search"].
        let searchElement = robot.app.searchFields["destination.search"]
        XCTAssertTrue(
            searchElement.waitForExistence(timeout: 4),
            "destination.search must exist as a searchField — TextField carries .isSearchField trait"
        )

        searchElement.tap()

        // .onChange(of: searchFocused) fires → store.onboarding?.clearDestination() → destination == nil
        // → actions: slot renders EmptyView → destination.cta removed from the accessibility tree.
        // waitForNonExistence confirms the button disappears within the timeout (§7.3 — never sleep).
        XCTAssertTrue(
            cta.waitForNonExistence(timeout: 5),
            "destination.cta must disappear after the search field is focused (selection cleared)"
        )

        let searchFocusedShot = XCTAttachment(screenshot: robot.app.screenshot())
        searchFocusedShot.name = "destination-search-focused-cta-hidden"
        searchFocusedShot.lifetime = .keepAlways
        add(searchFocusedShot)

        // ── 3. Type "Tok" — result list filters to Tokyo, Lisbon absent ──
        // The presenter's matchingCities uses localizedCaseInsensitiveContains so "Tok" matches "Tokyo".
        // In search mode the view renders resultsList(presenter): destination.result.<cityId> rows.
        searchElement.typeText("Tok")

        // Tokyo result row must appear.
        let tokyoResult = robot.app.buttons["destination.result.city-tokyo"]
        XCTAssertTrue(
            tokyoResult.waitForExistence(timeout: 4),
            "destination.result.city-tokyo must exist in the result list when query is 'Tok'"
        )

        // Lisbon result row must NOT appear — "Tok" does not match "Lisbon".
        let lisbonResult = robot.app.buttons["destination.result.city-lisbon"]
        XCTAssertTrue(
            lisbonResult.waitForNonExistence(timeout: 3),
            "destination.result.city-lisbon must not exist in the result list when query is 'Tok'"
        )

        let filteredShot = XCTAttachment(screenshot: robot.app.screenshot())
        filteredShot.name = "destination-search-tok-result-list"
        filteredShot.lifetime = .keepAlways
        add(filteredShot)

        // ── 4. Tap the Tokyo result row — resultRow: select(city:) + clear search + advanceOnboardingStep() ──
        // The step ADVANCES to Trip Shape: destination.search is no longer in the tree (we left the
        // destination step), and tripshape.cta appears (the Trip Shape step's CTA always renders;
        // its label is "Choose a trip shape" when no shape is picked yet — we do not assert the label).
        XCTAssertTrue(tokyoResult.isHittable, "destination.result.city-tokyo must be hittable")
        tokyoResult.tap()

        // After advancing, the destination search field must be gone — we are no longer on that step.
        // Single deterministic query by id — resolves as searchFields (TextField + .isSearchField trait).
        XCTAssertTrue(
            robot.app.searchFields["destination.search"].waitForNonExistence(timeout: 5),
            "destination.search must not exist after result-tap advances to Trip Shape"
        )

        // Trip Shape step CTA must now be present — confirms we landed on the next step.
        let tripShapeCTA = robot.app.buttons["tripshape.cta"]
        XCTAssertTrue(
            tripShapeCTA.waitForExistence(timeout: 5),
            "tripshape.cta must exist after result-tap advances from Destination to Trip Shape"
        )

        let finalShot = XCTAttachment(screenshot: robot.app.screenshot())
        finalShot.name = "destination-result-tap-advances-to-tripshape"
        finalShot.lifetime = .keepAlways
        add(finalShot)
    }

    // MARK: - testAccessibilityAudit
    //
    // Runs the BROAD audit via OnboardingRobot.performOnboardingAudit() — not a narrowed `for:` set,
    // so new audit types are never silently dropped. The robot owns the common documented suppression set:
    //   • .dynamicType — the audit reads UIKit's adjustsFontForContentSizeCategory, which SwiftUI's
    //     Font.custom(relativeTo:) / Font.system(.style) don't surface; the text DOES scale (Typography.swift
    //     binds every role to a Dynamic Type style, zero fixedSize). The durable lock is an AX5 render
    //     snapshot (task #10), not this audit — re-confirm on any new fixed-size font.
    //   • .contrast — the audit pixel-samples and mis-reads backgrounds over glass / scroll / the OKLCH
    //     ramp (it flags the system .glassProminent CTA and ink-700-on-white, which pass). The receded-ink
    //     contrast call is a design-doc decision, not an XCUITest assertion.
    //   • .textClipped — the search field grows from minHeight (no fixed frame); known FP on editable fields.
    //   • .hitRegion on onboarding.progress — the progress bar is informational, not an interaction target.
    // No screen-specific extras for this suite — the common set is sufficient.
    // See OnboardingRobot.performOnboardingAudit and docs/decisions.md. Every other type/element hard-fails.

    func testAccessibilityAudit() throws {
        robot.launch(scenario: "onboardingA")

        let cta = robot.app.buttons["destination.cta"]
        XCTAssertTrue(cta.waitForExistence(timeout: 8), "destination.cta must exist before audit")

        let preAuditShot = XCTAttachment(screenshot: robot.app.screenshot())
        preAuditShot.name = "destination-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        // Common suppression set is centralized in OnboardingRobot.performOnboardingAudit.
        // No extra suppressions for this suite — pass the default no-op closure.
        try robot.performOnboardingAudit()
    }
}
