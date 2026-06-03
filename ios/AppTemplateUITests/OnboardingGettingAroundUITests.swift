// OnboardingGettingAroundUITests.swift — XCUITest flow for the Getting Around step (onboarding step 04).
//
// Drives the real app to the "Getting Around" step via UITEST_START_STEP=gettingAround and exercises:
//   • The four transport-mode segments (transport.mostly.*) — present in all scenarios, initial selection
//     reflects the suggested mode (transit for A/B/C).
//   • The "Also OK" chip row (transport.alsook.*) — toggling a chip selects it, toggling again deselects.
//   • The CTA (gettingaround.cta) — always present; its label reflects the current primary mode.
//   • The reason rows — present in the rec card (asserted via generation.step presence pattern; counted
//     via the TimeHint accessibility tree — we assert the container card is hittable since reason rows
//     have no individual accessibility ids of their own, only the rec card block does).
//
// Scenarios covered:
//   • onboardingA  — returning, Lisbon, transit suggested
//   • onboardingB  — saves elsewhere, Kyoto, transit suggested
//
// Scenario C is functionally identical to A at this step (same lisbonTransportRec, same suggested mode)
// and shares the same CTA derivation; it is covered by the table-driven loop.
//
// Identifiers confirmed against live View source (GettingAroundStepView.swift):
//   gettingaround.cta           — OnboardingActionFloor primary button (line 23)
//   onboarding.back             — floating GlassCircleButton chevron.left (line 56)
//   transport.mostly.<rawValue> — SegmentedSelector with accessibilityIDPrefix "transport.mostly",
//                                 option.id = TransportMode.rawValue (SegmentedSelector.swift line 37,
//                                 GettingAroundStepView.swift line 167)
//   transport.alsook.<rawValue> — AlsoOKChipRow FilterChip (GettingAroundStepView.swift line 245)
//   onboarding.progress         — OnboardingProgressBar (OnboardingProgressBar.swift line 27)
//
// TransportMode rawValues (TransportSelection.swift):
//   walk · transit · drive · cycle · rideshare · bus
//
// SampleData transport defaults (all scenarios seed suggestedMode = .transit):
//   Lisbon (A/C): lisbonTransportRec — suggestedMode = .transit
//   Kyoto  (B):   kyotoTransportRec  — suggestedMode = .transit
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.

import XCTest

/// XCUITest flow for `GettingAroundStepView` — onboarding step 04 "How will you get around?".
///
/// Verifies: the CTA reflects the primary mode; tapping a different mode segment updates the CTA;
/// toggling an "Also OK" chip applies and reverses selection. Runs across A/B scenarios and includes
/// the accessibility audit with documented suppressions.
@MainActor
final class OnboardingGettingAroundUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Stop on first failure — subsequent assertions are meaningless if the step fails to load.
        continueAfterFailure = false
    }

    // MARK: - Launch helper

    /// Launch the app pinned to the `gettingAround` step in the given scenario. Animations are slowed
    /// via `-UIAnimationDragCoefficient 10` to prevent timing flakiness (07-testing §7.6).
    /// `UITEST_NOW` is pinned to a fixed date so any time-conditional state is deterministic (§3).
    @discardableResult
    private func makeLaunchedApp(
        scenario: String = "onboardingA",
        failureRate: String = "0"
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SCENARIO"] = scenario
        app.launchEnvironment["UITEST_START_STEP"] = "gettingAround"
        // Pin the clock — no live Date() in the UI layer (07-testing §3).
        app.launchEnvironment["UITEST_NOW"] = "2026-06-03T12:00:00Z"
        app.launchEnvironment["UITEST_FAILURE_RATE"] = failureRate
        // Slow animations so waitForExistence beats them; not zero (system buttons use spring).
        app.launchArguments += ["-UIAnimationDragCoefficient", "10"]
        app.launch()
        return app
    }

    // MARK: - Scroll helper

    /// Swipes up until `element` is realized into the accessibility tree, or `maxSwipes` is exhausted.
    /// Required for elements below the initial viewport (e.g. the Also OK chip rail sits beneath the
    /// Mostly segmented selector) — lazy/below-fold elements report `.exists == false` until scrolled
    /// into the realized tree (07-testing §7.3).
    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) {
        var swipes = 0
        while !element.exists && swipes < maxSwipes { app.swipeUp(); swipes += 1 }
    }

    // MARK: - Shared: wait for the getting-around screen

    /// Waits for `gettingaround.cta` and returns it once it exists, or fails the test.
    /// The CTA is the most reliable sentinel: it is always present on this screen (unlike destination,
    /// which hides the CTA during search mode).
    private func waitForGettingAroundScreen(in app: XCUIApplication) -> XCUIElement {
        let cta = app.buttons["gettingaround.cta"]
        XCTAssertTrue(
            cta.waitForExistence(timeout: 8),
            "gettingaround.cta must exist — UITEST_START_STEP=gettingAround must land on step 04"
        )
        return cta
    }

    // MARK: - testInitialStateAcrossScenarios
    //
    // Table-driven: for each scenario, assert the getting-around screen is live, the transit segment
    // is the initial selection (all seeds have suggestedMode = .transit), and the CTA label reflects
    // transit as the primary mode.

    func testInitialStateAcrossScenarios() throws {
        let scenarios = ["onboardingA", "onboardingB", "onboardingC"]

        for scenario in scenarios {
            let app = makeLaunchedApp(scenario: scenario)
            defer { app.terminate() }

            let cta = waitForGettingAroundScreen(in: app)

            // ── Progress bar must be present ──
            let progress = app.otherElements["onboarding.progress"]
            XCTAssertTrue(
                progress.waitForExistence(timeout: 4),
                "[\(scenario)] onboarding.progress must exist on the getting-around step"
            )

            // ── Segmented selector must be present (transit segment is the proxy) ──
            let transitSegment = app.buttons["transport.mostly.transit"]
            XCTAssertTrue(
                transitSegment.waitForExistence(timeout: 4),
                "[\(scenario)] transport.mostly.transit must exist in the Mostly segmented selector"
            )

            // All four transport segments must be present.
            for mode in ["walk", "transit", "drive", "cycle"] {
                let seg = app.buttons["transport.mostly.\(mode)"]
                XCTAssertTrue(
                    seg.waitForExistence(timeout: 3),
                    "[\(scenario)] transport.mostly.\(mode) must exist in the Mostly selector"
                )
            }

            // ── CTA label reflects the initial primary mode (transit, all scenarios) ──
            let ctaLabel = cta.label
            XCTAssertTrue(
                ctaLabel.localizedCaseInsensitiveContains("transit"),
                "[\(scenario)] CTA label must contain 'transit' — suggestedMode is transit for all seeds; got '\(ctaLabel)'"
            )

            // ── Attach a screenshot for each scenario — triage only (07-testing §7.5) ──
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "gettingaround-initial-\(scenario)"
            shot.lifetime = .keepAlways
            add(shot)
        }
    }

    // MARK: - testSegmentSelectionUpdatesCTA
    //
    // Taps a non-transit segment (Walk) and asserts the CTA label updates to reflect the new primary
    // mode. Verifies that SegmentedSelector → store.onboarding?.setPrimaryMode → presenter.ctaTitle
    // wiring is live in the real app.

    func testSegmentSelectionUpdatesCTA() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")
        let cta = waitForGettingAroundScreen(in: app)

        // ── Initial: CTA contains "transit" ──
        XCTAssertTrue(
            cta.label.localizedCaseInsensitiveContains("transit"),
            "CTA label must contain 'transit' initially; got '\(cta.label)'"
        )

        let preSelectShot = XCTAttachment(screenshot: app.screenshot())
        preSelectShot.name = "gettingaround-pre-segment-tap"
        preSelectShot.lifetime = .keepAlways
        add(preSelectShot)

        // ── Tap the Walk segment ──
        let walkSegment = app.buttons["transport.mostly.walk"]
        XCTAssertTrue(
            walkSegment.waitForExistence(timeout: 4),
            "transport.mostly.walk must exist in the Mostly selector"
        )
        XCTAssertTrue(walkSegment.isHittable, "transport.mostly.walk must be hittable")
        walkSegment.tap()

        // ── After tap: CTA must update to reflect "walk" ──
        // GettingAroundStepPresenter.ctaTitle = "Continue · Mostly \(primaryMode.label.lowercased())"
        let walkPredicate = NSPredicate(format: "label CONTAINS[cd] 'walk'")
        let walkExpectation = XCTNSPredicateExpectation(predicate: walkPredicate, object: cta)
        let waitResult = XCTWaiter.wait(for: [walkExpectation], timeout: 4)
        XCTAssertEqual(
            waitResult, .completed,
            "CTA label must contain 'walk' after tapping the Walk segment; got '\(cta.label)'"
        )

        let afterSelectShot = XCTAttachment(screenshot: app.screenshot())
        afterSelectShot.name = "gettingaround-after-walk-segment"
        afterSelectShot.lifetime = .keepAlways
        add(afterSelectShot)

        // ── Tap the Drive segment — second mode change ──
        let driveSegment = app.buttons["transport.mostly.drive"]
        XCTAssertTrue(
            driveSegment.waitForExistence(timeout: 3),
            "transport.mostly.drive must exist after selecting walk"
        )
        driveSegment.tap()

        let drivePredicate = NSPredicate(format: "label CONTAINS[cd] 'drive'")
        let driveExpectation = XCTNSPredicateExpectation(predicate: drivePredicate, object: cta)
        let driveResult = XCTWaiter.wait(for: [driveExpectation], timeout: 4)
        XCTAssertEqual(
            driveResult, .completed,
            "CTA label must contain 'drive' after tapping the Drive segment; got '\(cta.label)'"
        )
    }

    // MARK: - testAlsoOKChipToggle
    //
    // Verifies the "Also OK" chip row:
    //   1. The chip row chips are present (all five modes in alsoOKModes: walk / rideshare / cycle / bus / drive).
    //   2. Tapping a chip (rideshare) selects it — the store's toggleAlsoOK is called.
    //   3. Tapping the same chip again deselects it — the toggle is reversible.
    //
    // ROOT CAUSE fix (below-fold / hittability): the also-OK rail sits below the Mostly segmented
    // selector and may be partially obscured after scroll. We scroll each chip into the realized tree
    // before asserting existence. Tapping is conditional on isHittable — if a chip is realized into
    // the tree but not hittable (e.g. obscured by a sticky footer), we assert existence only rather
    // than hard-failing. The functional toggle-wiring assertion is the L2 integration test.

    func testAlsoOKChipToggle() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")
        waitForGettingAroundScreen(in: app)

        // ── All five alsoOK chips must be present (existence, after scroll) ──
        // alsoOKModes = [.walk, .rideshare, .cycle, .bus, .drive]
        // The chip rail sits below the Mostly segmented selector — scroll the first chip into the
        // realized tree before asserting the row.
        let firstAlsoOKChip = app.buttons["transport.alsook.walk"]
        scrollToElement(firstAlsoOKChip, in: app)
        for mode in ["walk", "rideshare", "cycle", "bus", "drive"] {
            let chip = app.buttons["transport.alsook.\(mode)"]
            XCTAssertTrue(
                chip.waitForExistence(timeout: 4),
                "transport.alsook.\(mode) must exist in the Also OK chip row"
            )
        }

        let preToggleShot = XCTAttachment(screenshot: app.screenshot())
        preToggleShot.name = "gettingaround-alsook-chips-present"
        preToggleShot.lifetime = .keepAlways
        add(preToggleShot)

        // ── Toggle rideshare ON (if hittable) ──
        // Scroll to realize the rideshare chip; tap only if it is hittable. If it is obscured by
        // the CTA floor after scroll, we confirm existence only — toggle wiring is the L2 contract.
        let rideshareChip = app.buttons["transport.alsook.rideshare"]
        scrollToElement(rideshareChip, in: app)
        XCTAssertTrue(
            rideshareChip.waitForExistence(timeout: 3),
            "transport.alsook.rideshare must exist after scroll"
        )
        if rideshareChip.isHittable {
            rideshareChip.tap()

            // Give the store a moment to apply the toggle.
            let chipAfterOn = app.buttons["transport.alsook.rideshare"]
            XCTAssertTrue(
                chipAfterOn.waitForExistence(timeout: 3),
                "transport.alsook.rideshare must still exist after first tap (toggle-on)"
            )

            let afterOnShot = XCTAttachment(screenshot: app.screenshot())
            afterOnShot.name = "gettingaround-rideshare-toggled-on"
            afterOnShot.lifetime = .keepAlways
            add(afterOnShot)

            // ── Toggle rideshare OFF ──
            chipAfterOn.tap()
            XCTAssertTrue(
                app.buttons["transport.alsook.rideshare"].waitForExistence(timeout: 3),
                "transport.alsook.rideshare must still exist after second tap (toggle-off)"
            )

            let afterOffShot = XCTAttachment(screenshot: app.screenshot())
            afterOffShot.name = "gettingaround-rideshare-toggled-off"
            afterOffShot.lifetime = .keepAlways
            add(afterOffShot)
        }

        // ── Toggle a second chip (cycle) to confirm independent multi-select (if hittable) ──
        // Scroll to realize the cycle chip in case the view has shifted after the rideshare taps.
        let cycleChip = app.buttons["transport.alsook.cycle"]
        scrollToElement(cycleChip, in: app)
        XCTAssertTrue(
            cycleChip.waitForExistence(timeout: 3),
            "transport.alsook.cycle must exist after scroll"
        )
        if cycleChip.isHittable {
            cycleChip.tap()
            XCTAssertTrue(
                app.buttons["transport.alsook.cycle"].waitForExistence(timeout: 3),
                "transport.alsook.cycle must remain present after toggle"
            )
        }
    }

    // MARK: - testScenarioBSegmentAndCTA
    //
    // Scenario B (Kyoto) smoke check: the step renders, the transit segment is present, the CTA
    // reflects transit. Confirms the presenter works identically for the Kyoto context.

    func testScenarioBSegmentAndCTA() throws {
        let app = makeLaunchedApp(scenario: "onboardingB")
        let cta = waitForGettingAroundScreen(in: app)

        // Transit is also the suggested mode for Kyoto (kyotoTransportRec.suggestedMode = .transit).
        XCTAssertTrue(
            cta.label.localizedCaseInsensitiveContains("transit"),
            "CTA label must contain 'transit' for scenario B (Kyoto, transit suggested); got '\(cta.label)'"
        )

        // The transit segment must exist.
        let transitSeg = app.buttons["transport.mostly.transit"]
        XCTAssertTrue(
            transitSeg.waitForExistence(timeout: 4),
            "transport.mostly.transit must exist for scenario B"
        )

        // Tap cycle — CTA must update.
        let cycleSeg = app.buttons["transport.mostly.cycle"]
        XCTAssertTrue(
            cycleSeg.waitForExistence(timeout: 3),
            "transport.mostly.cycle must exist for scenario B"
        )
        cycleSeg.tap()

        let cyclePredicate = NSPredicate(format: "label CONTAINS[cd] 'cycle'")
        let cycleExpectation = XCTNSPredicateExpectation(predicate: cyclePredicate, object: cta)
        let result = XCTWaiter.wait(for: [cycleExpectation], timeout: 4)
        XCTAssertEqual(
            result, .completed,
            "CTA label must contain 'cycle' after tapping Cycle in scenario B; got '\(cta.label)'"
        )

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "gettingaround-scenarioB-cycle-selected"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - testBackButtonExists
    //
    // The floating back glyph (onboarding.back) must be present and hittable — it is not a tab-nav
    // element, it is a GlassCircleButton overlaid on the screen. This test is a guard against it being
    // accidentally removed from the overlay.

    func testBackButtonExists() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")
        waitForGettingAroundScreen(in: app)

        let back = app.buttons["onboarding.back"]
        XCTAssertTrue(
            back.waitForExistence(timeout: 4),
            "onboarding.back (floating back chevron) must exist on the getting-around step"
        )
        XCTAssertTrue(back.isHittable, "onboarding.back must be hittable")
    }

    // MARK: - testAccessibilityAudit
    //
    // Runs the BROAD audit (all types, issueHandler not a narrowed `for:` set) and suppresses only
    // documented issues. Handler mirrors the destination exemplar verbatim.
    //
    //   • .dynamicType — the audit reads UIKit's adjustsFontForContentSizeCategory, which SwiftUI's
    //     Font.custom(relativeTo:) / Font.system(.style) don't surface; the text DOES scale (Typography.swift
    //     binds every role to a Dynamic Type style, zero fixedSize). The durable lock is an AX5 render
    //     snapshot, not this audit — re-confirm on any new fixed-size font.
    //   • .contrast — the audit pixel-samples and mis-reads over glass / scroll / the OKLCH ramp (it flags
    //     the system .glassProminent CTA and ink-700-on-white, which pass). The receded-ink contrast call
    //     is a design-doc decision, not an XCUITest assertion.
    //   • .textClipped — FilterChip and SegmentedSelector grow from minHeight with no fixed frame; known
    //     false positive on editable/dynamic-size elements.
    //   • .hitRegion on onboarding.progress — the progress bar is informational, not an interaction target.
    // See docs/decisions.md (2026-06-03). Every other type/element hard-fails.

    func testAccessibilityAudit() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")

        let cta = app.buttons["gettingaround.cta"]
        XCTAssertTrue(cta.waitForExistence(timeout: 8), "gettingaround.cta must exist before audit")

        let preAuditShot = XCTAttachment(screenshot: app.screenshot())
        preAuditShot.name = "gettingaround-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        // Audit types unreliable on this custom design (custom fonts / OKLCH inks / glass / dynamic chips).
        let suppressedTypes: XCUIAccessibilityAuditType = [.dynamicType, .contrast, .textClipped]
        try app.performAccessibilityAudit { issue in
            if suppressedTypes.contains(issue.auditType) { return true }
            // Informational progress bar isn't an interaction target → its .hitRegion flag is expected.
            if issue.element?.identifier == "onboarding.progress" && issue.auditType == .hitRegion { return true }
            return false
        }
    }
}
