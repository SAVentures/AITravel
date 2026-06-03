// OnboardingDestinationUITests.swift — XCUITest flow for the Destination step (onboarding step 01).
//
// Locks the final behavior after the search-mode redesign: focusing the search field clears the
// prior city selection (so the CTA hides), and the Recent rail + grid are replaced by a result
// list (`destination.result.<cityId>`) while the keyboard is up. Tapping a result row commits the
// city, dismisses search, and the CTA reappears. This flow drives the real app via launchEnvironment
// scenario injection and queries exclusively by accessibility identifier — never by displayed text
// (locale-sensitive).
//
// Scenario: UITEST_SCENARIO=onboardingA
//   • Destination: Lisbon (city-lisbon), pre-selected (savedHere = 23 → returningWithLocalSaves)
//   • City options (grid + rail): Lisbon · Tokyo (city-tokyo) · Mexico City (city-mexico-city) · Marrakech (city-marrakech)
//   • CTA title: "Continue with Lisbon" initially
//
// Identifiers confirmed against live View source (DestinationStepView.swift, SearchWell.swift):
//   destination.cta              — primary CTA button (OnboardingActionFloor actions: slot, line 83)
//                                  HIDDEN when store.onboarding?.destination == nil (search focused)
//   rail.recent.<cityId>         — each Recent rail chip Button (line 275); NORMAL mode only
//   destination.city.<cityId>    — each grid tile Button (line 326); NORMAL mode only
//   destination.search           — outer screen-contract id on the SearchWell (line 162);
//                                  falls back to "onboarding.search" (SearchWell internal, line 103)
//   destination.result.<cityId>  — each result-list row Button (line 216); SEARCH mode only
//   onboarding.close             — floating GlassCircleButton × (line 131)
//
// Search-mode lifecycle (confirmed in DestinationStepView.swift):
//   focus acquired → .onChange(of: searchFocused) calls store.onboarding?.clearDestination()
//                 → destination == nil → actions: slot renders EmptyView → destination.cta hidden
//   isSearching == true → searchWell() + resultsList(presenter) replace hero/rail/grid
//   result row tap → select(city:) + searchFocused=false + searchText="" → normal mode + CTA returns
//
// City ids confirmed against SampleData+Onboarding.swift:
//   "city-lisbon", "city-tokyo", "city-mexico-city", "city-marrakech"
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.
import XCTest

/// XCUITest flow for `DestinationStepView` — the onboarding destination picker (step 01).
///
/// Tests the final behavior: normal-mode pill/grid selection updates the CTA; entering search mode
/// clears the selection so the CTA hides; typing filters the result list; tapping a result commits
/// the city and restores the CTA. Also runs the accessibility audit with a narrow documented exemption.
@MainActor
final class OnboardingDestinationUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Stop on first failure — subsequent assertions are meaningless if the destination screen
        // does not reach the expected state.
        continueAfterFailure = false
    }

    // MARK: - Launch helper

    /// Launch the app with the given scenario pinned via `UITEST_SCENARIO`. Animations are
    /// slowed via `-UIAnimationDragCoefficient 10` to prevent timing flakiness (§7.6).
    /// `UITEST_NOW` is pinned to a fixed date so time-conditional state is deterministic (§3).
    @discardableResult
    private func makeLaunchedApp(scenario: String = "onboardingA") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SCENARIO"] = scenario
        // Pin the clock — no live Date() in the UI layer (07-testing §3).
        app.launchEnvironment["UITEST_NOW"] = "2026-06-03T12:00:00Z"
        // Slow animations so waitForExistence beats them; not zero (system buttons use spring).
        app.launchArguments += ["-UIAnimationDragCoefficient", "10"]
        app.launch()
        return app
    }

    // MARK: - Shared: wait for the destination screen

    /// Returns the CTA element once it exists, or fails the test.
    /// The CTA is the most reliable sentinel for the destination screen being live and a city selected.
    private func waitForDestinationScreen(in app: XCUIApplication) -> XCUIElement {
        let cta = app.buttons["destination.cta"]
        XCTAssertTrue(
            cta.waitForExistence(timeout: 8),
            "destination.cta must exist — onboardingA seeds Lisbon as the pre-selected city"
        )
        return cta
    }

    /// Scroll `element` into the realized view. The "More cities" grid is the LAST element on the
    /// screen (below the hero, search well, AI voice, and Recent rail), and it is a `LazyVGrid` — its
    /// second row (Mexico City · Marrakech) is NOT realized into the accessibility tree until it
    /// scrolls near the viewport. So a below-fold grid tile reports `.exists == false` until we scroll.
    /// Swipe up a bounded number of times until the element is realized; never an unbounded loop (§7.3).
    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) {
        var swipes = 0
        while !element.exists && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }

    // MARK: - testRecentPillSelectsCity
    //
    // Verifies that tapping a Recent rail pill (id `rail.recent.<cityId>`) updates the CTA.
    // Recent rail pills are NORMAL mode — they exist when the search field is NOT focused.
    // The regression this locks: pills were rendered as static Text instead of Button.

    func testRecentPillSelectsCity() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")
        let cta = waitForDestinationScreen(in: app)

        // ── Initial state: CTA title contains "Lisbon" (the pre-selected city for scenario A) ──
        let initialLabel = cta.label
        XCTAssertTrue(
            initialLabel.localizedCaseInsensitiveContains("Lisbon"),
            "CTA label must contain 'Lisbon' initially; got '\(initialLabel)'"
        )

        // Attach a screenshot of the initial state — triage aid for CI, never pixel-diffed (§7.5).
        let initialShot = XCTAttachment(screenshot: app.screenshot())
        initialShot.name = "destination-initial-lisbon-selected"
        initialShot.lifetime = .keepAlways
        add(initialShot)

        // ── Tap the Tokyo Recent rail pill (NORMAL mode) ──
        // id: rail.recent.city-tokyo  (SampleData.tokyoCity() → City.id = "city-tokyo")
        let tokyoPill = app.buttons["rail.recent.city-tokyo"]
        XCTAssertTrue(
            tokyoPill.waitForExistence(timeout: 4),
            "rail.recent.city-tokyo must exist in the Recent rail for scenario A (normal mode)"
        )
        XCTAssertTrue(
            tokyoPill.isHittable,
            "Tokyo pill must be hittable — the regression was that pills were not interactive"
        )
        tokyoPill.tap()

        // ── After tap: CTA title must contain "Tokyo" ──
        // DestinationStepPresenter.ctaTitle reads draft.destination.name.
        let tokyoLabelPredicate = NSPredicate(format: "label CONTAINS[cd] 'Tokyo'")
        let tokyoExpectation = XCTNSPredicateExpectation(predicate: tokyoLabelPredicate, object: cta)
        let result = XCTWaiter.wait(for: [tokyoExpectation], timeout: 4)
        XCTAssertEqual(
            result, .completed,
            "CTA label must contain 'Tokyo' after tapping the Tokyo pill; got '\(cta.label)'"
        )

        // Attach after-tap screenshot.
        let afterTapShot = XCTAttachment(screenshot: app.screenshot())
        afterTapShot.name = "destination-after-tokyo-pill-tap"
        afterTapShot.lifetime = .keepAlways
        add(afterTapShot)
    }

    // MARK: - testGridTileSelectsCity
    //
    // Verifies that tapping a non-selected grid tile (id `destination.city.<cityId>`) selects that
    // city and updates the CTA. Grid tiles exist in NORMAL mode only.

    func testGridTileSelectsCity() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")
        let cta = waitForDestinationScreen(in: app)

        // The Mexico City grid tile is non-selected in scenario A (only Lisbon starts selected).
        // id: destination.city.city-mexico-city  (SampleData.mexicoCityCity() → id = "city-mexico-city")
        // It sits in the grid's SECOND row, below the fold — scroll it into the realized tree first.
        let mexicoTile = app.buttons["destination.city.city-mexico-city"]
        scrollToElement(mexicoTile, in: app)
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
        let lisbonTile = app.buttons["destination.city.city-lisbon"]
        var upSwipes = 0
        while !lisbonTile.exists && upSwipes < 6 {
            app.swipeDown()
            upSwipes += 1
        }
        XCTAssertTrue(
            lisbonTile.waitForExistence(timeout: 2),
            "destination.city.city-lisbon must still exist after selecting a different city (normal mode)"
        )

        // Attach screenshot.
        let shot = XCTAttachment(screenshot: app.screenshot())
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
    //   4. Tapping destination.result.city-tokyo commits Tokyo, exits search, CTA reappears with "Tokyo".
    //
    // Replaces the old testSearchFiltersCities which incorrectly asserted against grid/rail ids in
    // search mode — those elements are replaced by destination.result.* rows in search mode
    // (DestinationStepView.swift line 95–107: isSearching → searchWell() + resultsList(presenter)).

    func testSearchClearsSelectionAndFilters() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")
        let cta = waitForDestinationScreen(in: app)

        // ── 1. Initial state: CTA exists and contains "Lisbon" ──
        XCTAssertTrue(
            cta.label.localizedCaseInsensitiveContains("Lisbon"),
            "CTA label must contain 'Lisbon' initially; got '\(cta.label)'"
        )

        let preSearchShot = XCTAttachment(screenshot: app.screenshot())
        preSearchShot.name = "destination-pre-search-lisbon-selected"
        preSearchShot.lifetime = .keepAlways
        add(preSearchShot)

        // ── 2. Tap the search field — clears selection, CTA must disappear ──
        // SearchWell applies `.accessibilityElement(children: .combine)` + `.accessibilityAddTraits(.isSearchField)`
        // (SearchWell.swift line 100–102), so it collapses to ONE element of type `.searchField` — NOT
        // `.otherElement`. The screen's `.accessibilityIdentifier("destination.search")` (DestinationStepView.swift
        // line 169) wins over the component-internal "onboarding.search". So query `app.searchFields`, with a
        // `textFields` fallback in case a future SDK surfaces the combined field as a plain text field.
        let searchElement: XCUIElement
        let searchField = app.searchFields["destination.search"]
        if searchField.waitForExistence(timeout: 4) {
            searchElement = searchField
        } else {
            let textField = app.textFields["destination.search"]
            XCTAssertTrue(
                textField.waitForExistence(timeout: 3),
                "Search field must exist as a searchField or textField with id 'destination.search'"
            )
            searchElement = textField
        }

        searchElement.tap()

        // .onChange(of: searchFocused) fires → store.onboarding?.clearDestination() → destination == nil
        // → actions: slot renders EmptyView → destination.cta removed from the accessibility tree.
        // waitForNonExistence confirms the button disappears within the timeout (§7.3 — never sleep).
        XCTAssertTrue(
            cta.waitForNonExistence(timeout: 5),
            "destination.cta must disappear after the search field is focused (selection cleared)"
        )

        let searchFocusedShot = XCTAttachment(screenshot: app.screenshot())
        searchFocusedShot.name = "destination-search-focused-cta-hidden"
        searchFocusedShot.lifetime = .keepAlways
        add(searchFocusedShot)

        // ── 3. Type "Tok" — result list filters to Tokyo, Lisbon absent ──
        // The presenter's matchingCities uses localizedCaseInsensitiveContains so "Tok" matches "Tokyo".
        // In search mode the view renders resultsList(presenter): destination.result.<cityId> rows.
        searchElement.typeText("Tok")

        // Tokyo result row must appear.
        let tokyoResult = app.buttons["destination.result.city-tokyo"]
        XCTAssertTrue(
            tokyoResult.waitForExistence(timeout: 4),
            "destination.result.city-tokyo must exist in the result list when query is 'Tok'"
        )

        // Lisbon result row must NOT appear — "Tok" does not match "Lisbon".
        let lisbonResult = app.buttons["destination.result.city-lisbon"]
        XCTAssertTrue(
            lisbonResult.waitForNonExistence(timeout: 3),
            "destination.result.city-lisbon must not exist in the result list when query is 'Tok'"
        )

        let filteredShot = XCTAttachment(screenshot: app.screenshot())
        filteredShot.name = "destination-search-tok-result-list"
        filteredShot.lifetime = .keepAlways
        add(filteredShot)

        // ── 4. Tap the Tokyo result row — commits city, exits search, CTA reappears ──
        // Tapping resultRow calls: select(city:) + searchFocused=false + searchText="" (line 189–191).
        // The screen returns to normal mode: isSearching becomes false, actions: slot renders
        // OnboardingActionFloor again with ctaTitle = "Continue with Tokyo".
        XCTAssertTrue(tokyoResult.isHittable, "destination.result.city-tokyo must be hittable")
        tokyoResult.tap()

        // The CTA must reappear after search is dismissed.
        let ctaAfterResult = app.buttons["destination.cta"]
        XCTAssertTrue(
            ctaAfterResult.waitForExistence(timeout: 5),
            "destination.cta must reappear after tapping a result row (search mode exits)"
        )

        // CTA must now reflect the newly selected city — Tokyo.
        let tokyoCTAPredicate = NSPredicate(format: "label CONTAINS[cd] 'Tokyo'")
        let tokyoCTAExpectation = XCTNSPredicateExpectation(predicate: tokyoCTAPredicate, object: ctaAfterResult)
        let ctaResult = XCTWaiter.wait(for: [tokyoCTAExpectation], timeout: 4)
        XCTAssertEqual(
            ctaResult, .completed,
            "CTA label must contain 'Tokyo' after tapping the Tokyo result row; got '\(ctaAfterResult.label)'"
        )

        let finalShot = XCTAttachment(screenshot: app.screenshot())
        finalShot.name = "destination-after-result-tap-tokyo-selected"
        finalShot.lifetime = .keepAlways
        add(finalShot)
    }

    // MARK: - testAccessibilityAudit
    //
    // Runs the BROAD audit (Apple's mechanism — `performAccessibilityAudit` + an `issueHandler`, not a
    // narrowed `for:` set, so new audit types are never silently dropped) and suppresses only documented
    // issues. `.contrast` / `.dynamicType` / `.textClipped` are not reliable on this custom design and are
    // suppressed with the real check that covers each named:
    //   • .dynamicType — the audit reads UIKit's adjustsFontForContentSizeCategory, which SwiftUI's
    //     Font.custom(relativeTo:) / Font.system(.style) don't surface; the text DOES scale (Typography.swift
    //     binds every role to a Dynamic Type style, zero fixedSize). The durable lock is an AX5 render
    //     snapshot (task #10), not this audit — re-confirm on any new fixed-size font.
    //   • .contrast — the audit pixel-samples and mis-reads backgrounds over glass / scroll / the OKLCH
    //     ramp (it flags the system .glassProminent CTA and ink-700-on-white, which pass). The receded-ink
    //     contrast call is a design-doc decision, not an XCUITest assertion.
    //   • .textClipped — the search field grows from minHeight (no fixed frame); known FP on editable fields.
    //   • .hitRegion on onboarding.progress — the progress bar is informational, not an interaction target.
    // See docs/decisions.md (this date). Every other type/element hard-fails.

    func testAccessibilityAudit() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")

        let cta = app.buttons["destination.cta"]
        XCTAssertTrue(cta.waitForExistence(timeout: 8), "destination.cta must exist before audit")

        let preAuditShot = XCTAttachment(screenshot: app.screenshot())
        preAuditShot.name = "destination-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        // Audit types unreliable on this custom design (custom fonts / OKLCH inks / glass / editable field).
        let suppressedTypes: XCUIAccessibilityAuditType = [.dynamicType, .contrast, .textClipped]
        try app.performAccessibilityAudit { issue in
            if suppressedTypes.contains(issue.auditType) { return true }
            // Informational progress bar isn't an interaction target → its .hitRegion flag is expected.
            if issue.element?.identifier == "onboarding.progress" && issue.auditType == .hitRegion { return true }
            return false
        }
    }
}
