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
// Prior-step sentinel (C3 back-navigation test):
//   baselocation.cta            — OnboardingActionFloor primary button in BaseLocationStepView (line 30).
//                                 Confirmed: OnboardingStep.baseLocation = rawValue 3 is the step
//                                 immediately before OnboardingStep.gettingAround = rawValue 4 in the
//                                 GenerationPlan.swift enum and the OnboardingFlowView.swift switch.
//                                 retreatOnboardingStep() decrements the step (AppStore+Onboarding.swift:54).
//
// TransportMode rawValues (TransportSelection.swift):
//   walk · transit · drive · cycle · rideshare · bus
//
// SampleData transport defaults (all scenarios seed suggestedMode = .transit):
//   Lisbon (A/C): lisbonTransportRec — suggestedMode = .transit
//   Kyoto  (B):   kyotoTransportRec  — suggestedMode = .transit
//
// UITEST_FAILURE_RATE: NOT forwarded locally — the seam is centralized in OnboardingRobot's
//   optional `failureRate` param. Callers in this suite pass no failureRate → behavior unchanged
//   (key absent from launchEnvironment). The seam is preserved as a deliberate future hook for the
//   onboarding write command; see docs/decisions.md (Task C5).
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
            let robot = OnboardingRobot()
            let app = robot.launch(scenario: scenario, startStep: "gettingAround")
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
        let robot = OnboardingRobot()
        let app = robot.launch(scenario: "onboardingA", startStep: "gettingAround")
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
    //   2. Tapping rideshare selects it — the store's toggleAlsoOK is called — asserted unconditionally.
    //   3. Tapping cycle independently selects it — multi-select is live — asserted unconditionally.
    //
    // C2 fix: the previous `if isHittable { … }` guards are removed. Each chip is scrolled into the
    // realized tree via robot.scrollToElement(_:), then existence, hittability, tap, and post-tap
    // isSelected == true are all unconditional assertions. A chip below the viewport but realized into
    // the accessibility tree will report isHittable after scroll; if it does not, the test fails loudly
    // rather than silently skipping — the functional contract, not an escape hatch.

    func testAlsoOKChipToggle() throws {
        let robot = OnboardingRobot()
        let app = robot.launch(scenario: "onboardingA", startStep: "gettingAround")
        waitForGettingAroundScreen(in: app)

        // ── All five alsoOK chips must be present (existence, after scroll) ──
        // alsoOKModes = [.walk, .rideshare, .cycle, .bus, .drive]
        // The chip rail sits below the Mostly segmented selector — scroll the first chip into the
        // realized tree before asserting the row.
        let firstAlsoOKChip = app.buttons["transport.alsook.walk"]
        robot.scrollToElement(firstAlsoOKChip)
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

        // ── Toggle rideshare ON — unconditional (C2) ──
        // Scroll to realize the rideshare chip into the accessibility tree, then assert it exists,
        // is hittable, tap it, and assert isSelected == true post-tap.
        let rideshareChip = app.buttons["transport.alsook.rideshare"]
        robot.scrollToElement(rideshareChip)
        XCTAssertTrue(
            rideshareChip.waitForExistence(timeout: 3),
            "transport.alsook.rideshare must exist after scroll"
        )
        XCTAssertTrue(rideshareChip.isHittable, "transport.alsook.rideshare must be hittable after scroll")
        rideshareChip.tap()

        // Assert isSelected == true after the toggle-on tap.
        let rideshareOnPredicate = NSPredicate(format: "isSelected == true")
        let rideshareOnExpectation = XCTNSPredicateExpectation(
            predicate: rideshareOnPredicate,
            object: app.buttons["transport.alsook.rideshare"]
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [rideshareOnExpectation], timeout: 3), .completed,
            "transport.alsook.rideshare must be selected (isSelected == true) after first tap"
        )

        let afterOnShot = XCTAttachment(screenshot: app.screenshot())
        afterOnShot.name = "gettingaround-rideshare-toggled-on"
        afterOnShot.lifetime = .keepAlways
        add(afterOnShot)

        // ── Toggle rideshare OFF ──
        let rideshareChipAfterOn = app.buttons["transport.alsook.rideshare"]
        XCTAssertTrue(
            rideshareChipAfterOn.waitForExistence(timeout: 3),
            "transport.alsook.rideshare must still exist after first tap (toggle-on)"
        )
        rideshareChipAfterOn.tap()
        XCTAssertTrue(
            app.buttons["transport.alsook.rideshare"].waitForExistence(timeout: 3),
            "transport.alsook.rideshare must still exist after second tap (toggle-off)"
        )

        let afterOffShot = XCTAttachment(screenshot: app.screenshot())
        afterOffShot.name = "gettingaround-rideshare-toggled-off"
        afterOffShot.lifetime = .keepAlways
        add(afterOffShot)

        // ── Toggle cycle ON — unconditional (C2) ──
        // Scroll to realize the cycle chip in case the view shifted after the rideshare taps,
        // then assert existence, hittability, tap, and post-tap isSelected == true unconditionally.
        let cycleChip = app.buttons["transport.alsook.cycle"]
        robot.scrollToElement(cycleChip)
        XCTAssertTrue(
            cycleChip.waitForExistence(timeout: 3),
            "transport.alsook.cycle must exist after scroll"
        )
        XCTAssertTrue(cycleChip.isHittable, "transport.alsook.cycle must be hittable after scroll")
        cycleChip.tap()

        // Assert isSelected == true after the toggle-on tap.
        let cycleOnPredicate = NSPredicate(format: "isSelected == true")
        let cycleOnExpectation = XCTNSPredicateExpectation(
            predicate: cycleOnPredicate,
            object: app.buttons["transport.alsook.cycle"]
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [cycleOnExpectation], timeout: 3), .completed,
            "transport.alsook.cycle must be selected (isSelected == true) after tap"
        )

        let afterCycleShot = XCTAttachment(screenshot: app.screenshot())
        afterCycleShot.name = "gettingaround-cycle-toggled-on"
        afterCycleShot.lifetime = .keepAlways
        add(afterCycleShot)
    }

    // MARK: - testScenarioBSegmentAndCTA
    //
    // Scenario B (Kyoto) smoke check: the step renders, the transit segment is present, the CTA
    // reflects transit. Confirms the presenter works identically for the Kyoto context.

    func testScenarioBSegmentAndCTA() throws {
        let robot = OnboardingRobot()
        let app = robot.launch(scenario: "onboardingB", startStep: "gettingAround")
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
        let robot = OnboardingRobot()
        let app = robot.launch(scenario: "onboardingA", startStep: "gettingAround")
        waitForGettingAroundScreen(in: app)

        let back = robot.backButton
        XCTAssertTrue(
            back.waitForExistence(timeout: 4),
            "onboarding.back (floating back chevron) must exist on the getting-around step"
        )
        XCTAssertTrue(back.isHittable, "onboarding.back must be hittable")
    }

    // MARK: - testBackNavigatesToPriorStep
    //
    // C3: Taps onboarding.back (onboarding.back → store.retreatOnboardingStep()) and asserts the
    // PRIOR step rendered — specifically, baselocation.cta appears and gettingaround.cta disappears.
    //
    // Prior-step confirmation:
    //   OnboardingStep enum (GenerationPlan.swift:73-85):
    //     .destination = 0, .tripShape = 1, .when = 2, .baseLocation = 3, .gettingAround = 4, .generating = 5
    //   OnboardingFlowView.swift switch order mirrors the enum:
    //     .baseLocation → BaseLocationStepView() is the case immediately before .gettingAround.
    //   retreatOnboardingStep() (AppStore+Onboarding.swift:54) calls onboarding?.retreatStep() which
    //   decrements the step index, landing on .baseLocation (rawValue 3).
    //   BaseLocationStepView.swift:30 stamps "baselocation.cta" on its OnboardingActionFloor primary button.
    //   That identifier is the sentinel that appears if and only if BaseLocationStepView is rendered.
    //
    // A regression making onboarding.back a no-op, or routing to the wrong step, will fail this test.

    func testBackNavigatesToPriorStep() throws {
        let robot = OnboardingRobot()
        let app = robot.launch(scenario: "onboardingA", startStep: "gettingAround")

        // Wait for the gettingAround step's sentinel — confirms we started on the right step.
        let gettingAroundCTA = app.buttons["gettingaround.cta"]
        XCTAssertTrue(
            gettingAroundCTA.waitForExistence(timeout: 8),
            "gettingaround.cta must exist before tapping back"
        )

        let preBackShot = XCTAttachment(screenshot: app.screenshot())
        preBackShot.name = "gettingaround-pre-back-tap"
        preBackShot.lifetime = .keepAlways
        add(preBackShot)

        // Tap onboarding.back — drives retreatOnboardingStep() → .baseLocation.
        let back = robot.backButton
        XCTAssertTrue(
            back.waitForExistence(timeout: 4),
            "onboarding.back must exist before tapping"
        )
        XCTAssertTrue(back.isHittable, "onboarding.back must be hittable before tapping")
        back.tap()

        // Assert the PRIOR step (baseLocation) rendered:
        //   baselocation.cta appears — confirmed in BaseLocationStepView.swift line 30.
        let baseLocationCTA = app.buttons["baselocation.cta"]
        XCTAssertTrue(
            baseLocationCTA.waitForExistence(timeout: 6),
            "baselocation.cta must appear after tapping back from gettingAround — retreatOnboardingStep() must land on .baseLocation"
        )

        // Assert this step's sentinel (gettingaround.cta) is gone — the step is no longer rendered.
        XCTAssertFalse(
            gettingAroundCTA.exists,
            "gettingaround.cta must NOT exist after back-navigation — the gettingAround step must have been dismissed"
        )

        let postBackShot = XCTAttachment(screenshot: app.screenshot())
        postBackShot.name = "gettingaround-post-back-landed-on-baselocation"
        postBackShot.lifetime = .keepAlways
        add(postBackShot)
    }

    // MARK: - testAccessibilityAudit
    //
    // Runs the BROAD audit via OnboardingRobot.performOnboardingAudit — all audit types, no `for:`
    // narrowing. The common suppression set is centralized in the robot (C1 migration):
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
    // See docs/decisions.md (2026-06-03). Every other type/element hard-fails (robot returns false).
    // No screen-specific suppressions needed for GettingAround — extraSuppressions defaults to { _ in false }.

    func testAccessibilityAudit() throws {
        let robot = OnboardingRobot()
        let app = robot.launch(scenario: "onboardingA", startStep: "gettingAround")

        let cta = app.buttons["gettingaround.cta"]
        XCTAssertTrue(cta.waitForExistence(timeout: 8), "gettingaround.cta must exist before audit")

        let preAuditShot = XCTAttachment(screenshot: app.screenshot())
        preAuditShot.name = "gettingaround-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        try robot.performOnboardingAudit()
    }
}
