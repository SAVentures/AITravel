// OnboardingFlowUITests.swift — End-to-end multi-step flow walk for OnboardingFlowView.
//
// Why this suite exists: every other onboarding UITest suite launches with UITEST_START_STEP, so the
// OnboardingFlowView orchestration layer (destination → tripShape → when → …) is never exercised as a
// sequence. This suite launches WITHOUT UITEST_START_STEP, starting at the first step (destination),
// and walks forward across ≥2 real inter-step boundaries to prove step-to-step orchestration works.
//
// Flow path (scenario A, "onboardingA"):
//   Step 1 — Destination (index 0)
//     Context A pre-selects Lisbon in OnboardingContextDTO.toDomain(), so store.onboarding?.destination
//     is non-nil on load and destination.cta appears immediately (no search or city-tap required).
//     Sentinel: destination.cta  (confirmed DestinationStepView.swift line 37)
//     Close:    onboarding.close (confirmed DestinationStepView.swift line 84)
//     Tap:      destination.cta → store.advanceOnboardingStep() → currentStep = .tripShape
//     [Boundary 1] assert tripshape.cta appears + destination.cta disappears
//
//   Step 2 — TripShape (index 1)
//     Scenario A → shapeCards mode, canContinue = (selectedStrategy != nil).
//     Card "a" (fixed-days) is always above fold and exposes .accessibilityAction { select(strategy:) }.
//     XCUITest element.tap() fires the accessibilityAction, updating shapeStrategy on the draft.
//     NOTE: post-tap .isSelected trait is NOT asserted — see docs/decisions.md (L4 onTapGesture note).
//     The CTA is gated by primaryEnabled = canContinue; it stays in the view with .disabled(!enabled).
//     The tap sequence gates the CTA tap on isEnabled == true (polled via XCTNSPredicateExpectation,
//     with a bounded retry tap) so the CTA is never hit while still disabled.
//     Sentinel: tripshape.cta  (confirmed TripShapeStepView.swift line 23)
//     Card a:   tripshape.a    (confirmed TripShapeCard.swift line 86: "tripshape.\(id)" suffix "a")
//     Tap:      tripshape.a (select strategy, wait for CTA enabled) → tripshape.cta (advance to When step)
//     [Boundary 2] assert when.cta appears + tripshape.cta disappears
//
//   Step 3 — When (index 2)
//     Sentinel: when.cta   (confirmed WhenStepView.swift line 23, always rendered with no primaryEnabled gate)
//     when.month also rendered (confirmed WhenStepView.swift line 116) — asserted for belt-and-suspenders.
//
// Identifiers confirmed against live source (no guessing):
//   "destination.cta"  — DestinationStepView.swift:37 (primaryAccessibilityID)
//   "onboarding.close" — DestinationStepView.swift:84
//   "tripshape.cta"    — TripShapeStepView.swift:23 (primaryAccessibilityID)
//   "onboarding.back"  — TripShapeStepView.swift:50
//   "tripshape.a"      — TripShapeCard.swift:86 ("tripshape.\(id)", id "a" from cardID(for:0))
//   "when.cta"         — WhenStepView.swift:23 (primaryAccessibilityID)
//   "when.month"       — WhenStepView.swift:116
//   "onboarding.back"  — WhenStepView.swift:45
//
// UITEST_FAILURE_RATE: forwarded via OnboardingRobot.launch(failureRate:) but not consumed — see
// docs/decisions.md (Task C5). The launch call below does not pass failureRate, so the key is absent,
// which matches today's behavior for suites that omit it.
//
// pbxproj membership: AppTemplateUITests uses PBXFileSystemSynchronizedRootGroup (objectVersion 77).
// New files in the synchronized root auto-join the UITest target — no manual pbxproj entry needed.
// Confirmed from OnboardingRobot.swift header (line 54–57).
//
// See ios/docs/engineering/07-testing.md §7 for the XCUITest layer contract.
import XCTest

/// End-to-end flow walk for `OnboardingFlowView` — exercises ≥2 inter-step boundaries starting from
/// the first step, without a `UITEST_START_STEP` override.
@MainActor
final class OnboardingFlowUITests: XCTestCase {

    private var robot: OnboardingRobot!

    override func setUp() {
        super.setUp()
        // Stop on first failure — downstream step assertions are meaningless if an earlier step fails.
        continueAfterFailure = false
        robot = OnboardingRobot()
    }

    override func tearDown() {
        robot.app.terminate()
        robot = nil
        super.tearDown()
    }

    // MARK: - testFlowAdvancesAcrossStepBoundaries
    //
    // Launches at the flow start (no UITEST_START_STEP), walks forward across two inter-step
    // boundaries (destination → tripShape → when), and asserts the step-to-step sentinel transition
    // at each boundary by a11y id only (never by displayed text).

    func testFlowAdvancesAcrossStepBoundaries() throws {
        // ── Launch — no startStep = flow begins at destination (OnboardingStep.destination, index 0) ──
        robot.launch(scenario: "onboardingA", startStep: nil)

        let app = robot.app

        // ─────────────────────────────────────────────────────────────────────
        // STEP 1 — Destination
        //
        // In scenario A, OnboardingContextDTO.toDomain() seeds destination = Lisbon, so
        // store.onboarding?.destination is non-nil on first render and destination.cta appears
        // without any user interaction.
        // ─────────────────────────────────────────────────────────────────────

        let destinationCTA = robot.cta("destination.cta")
        XCTAssertTrue(
            destinationCTA.waitForExistence(timeout: 8),
            "destination.cta must exist — scenario A pre-selects Lisbon, so the CTA appears immediately"
        )

        // Confirm the destination-step close button (not back — destination is the first step).
        let closeButton = app.buttons["onboarding.close"]
        XCTAssertTrue(
            closeButton.waitForExistence(timeout: 2),
            "onboarding.close must exist on the destination step (DestinationStepView.swift line 84)"
        )

        // Triage screenshot: destination step with CTA visible.
        let step1Shot = XCTAttachment(screenshot: app.screenshot())
        step1Shot.name = "flow-step1-destination-cta-visible"
        step1Shot.lifetime = .keepAlways
        add(step1Shot)

        // ── Tap the destination CTA → advance to TripShape ──
        destinationCTA.tap()

        // ─────────────────────────────────────────────────────────────────────
        // BOUNDARY 1 — destination → tripShape
        //
        // Assert: tripshape.cta appears + destination.cta disappears.
        // ─────────────────────────────────────────────────────────────────────

        let tripshapeCTA = robot.cta("tripshape.cta")
        XCTAssertTrue(
            tripshapeCTA.waitForExistence(timeout: 8),
            "tripshape.cta must appear after destination → tripShape boundary"
        )
        XCTAssertFalse(
            destinationCTA.exists,
            "destination.cta must disappear after crossing the destination → tripShape boundary"
        )

        // The destination step uses 'onboarding.close'; tripShape uses 'onboarding.back'.
        let backButton = robot.backButton
        XCTAssertTrue(
            backButton.waitForExistence(timeout: 2),
            "onboarding.back must appear on the tripShape step (TripShapeStepView.swift line 50)"
        )

        // ─────────────────────────────────────────────────────────────────────
        // STEP 2 — TripShape
        //
        // Scenario A → .shapeCards mode. canContinue = (selectedStrategy != nil), so the CTA floor
        // renders but advancing requires selecting a card. Card "a" (fixed-days) is always above fold.
        //
        // TripShapeCard exposes .accessibilityAction { select(strategy:) } so element.tap() fires
        // the action via the accessibility tree (not a coordinate touch). Post-tap .isSelected trait
        // is NOT asserted — see docs/decisions.md (L4 onTapGesture note).
        // ─────────────────────────────────────────────────────────────────────

        let cardA = app.buttons["tripshape.a"]
        XCTAssertTrue(
            cardA.waitForExistence(timeout: 4),
            "tripshape.a must exist in scenario A (unlocked fixed-days card, always above fold)"
        )
        XCTAssertTrue(
            cardA.isHittable,
            "tripshape.a must be hittable — unlocked cards carry the .isButton trait (SelectAction)"
        )

        // Triage screenshot: tripShape step before card selection.
        let step2BeforeShot = XCTAttachment(screenshot: app.screenshot())
        step2BeforeShot.name = "flow-step2-tripshape-before-card-tap"
        step2BeforeShot.lifetime = .keepAlways
        add(step2BeforeShot)

        // Tap card A — fires accessibilityAction { select(strategy: .fixedDays) } on the draft.
        // TripShapeCard's SelectAction attaches both .onTapGesture AND .accessibilityAction, so
        // element.tap() in XCUITest fires via the accessibility tree (see TripShapeCard.swift:238-241
        // and docs/decisions.md "L4 onTapGesture note"). The @Observable canContinue propagation
        // may not be synchronous with the tap, so we gate the CTA tap on isEnabled becoming true.
        cardA.tap()

        // Wait for canContinue → primaryEnabled → CTA.isEnabled to propagate.
        // The CTA is never removed from the tree (it stays with .disabled(!primaryEnabled)), so
        // waitForExistence is insufficient — we must poll isEnabled. A bounded retry of the card
        // tap guards against the rare case where the first tap does not register (e.g. spring
        // animation still settling), as documented in docs/decisions.md for this affordance.
        let enabledPredicate = NSPredicate(format: "isEnabled == true")
        let ctaEnabledExpectation = XCTNSPredicateExpectation(predicate: enabledPredicate, object: tripshapeCTA)
        let enabledResult = XCTWaiter.wait(for: [ctaEnabledExpectation], timeout: 3)
        if enabledResult != .completed {
            // Retry the card tap once — the accessibility propagation may have lost the first tap
            // during animation. If still not enabled after the retry wait, the assertion below fails
            // with a clear message rather than silently advancing with a disabled CTA tap.
            cardA.tap()
            XCTWaiter.wait(for: [ctaEnabledExpectation], timeout: 3)
        }
        XCTAssertTrue(
            tripshapeCTA.isEnabled,
            "tripshape.cta must be enabled after card A selection — canContinue must be true (selectedStrategy != nil)"
        )
        tripshapeCTA.tap()

        // ─────────────────────────────────────────────────────────────────────
        // BOUNDARY 2 — tripShape → when
        //
        // Assert: when.cta appears + tripshape.cta disappears.
        // ─────────────────────────────────────────────────────────────────────

        let whenCTA = robot.cta("when.cta")
        XCTAssertTrue(
            whenCTA.waitForExistence(timeout: 8),
            "when.cta must appear after tripShape → when boundary"
        )
        XCTAssertFalse(
            tripshapeCTA.exists,
            "tripshape.cta must disappear after crossing the tripShape → when boundary"
        )

        // ─────────────────────────────────────────────────────────────────────
        // STEP 3 — When
        //
        // when.cta has no primaryEnabled gate (WhenStepView.swift line 20-26 — no primaryEnabled
        // param). when.month is also rendered (the month-picker menu). Assert both are present.
        // ─────────────────────────────────────────────────────────────────────

        let whenMonth = app.buttons["when.month"]
        XCTAssertTrue(
            whenMonth.waitForExistence(timeout: 4),
            "when.month must exist on the When step (WhenStepView.swift line 116)"
        )

        let whenBack = robot.backButton
        XCTAssertTrue(
            whenBack.waitForExistence(timeout: 2),
            "onboarding.back must exist on the When step (WhenStepView.swift line 45)"
        )

        // Triage screenshot: When step with CTA + month menu visible.
        let step3Shot = XCTAttachment(screenshot: app.screenshot())
        step3Shot.name = "flow-step3-when-cta-visible"
        step3Shot.lifetime = .keepAlways
        add(step3Shot)

        // ─────────────────────────────────────────────────────────────────────
        // Accessibility audit — run on the When step (the terminal step of this walk).
        // Uses the robot's common suppression set: .dynamicType, .contrast, .textClipped, and
        // onboarding.progress .hitRegion — all documented in OnboardingRobot.performOnboardingAudit.
        // No extra suppressions needed here (When step has no glass maps or decorative elements).
        // ─────────────────────────────────────────────────────────────────────

        try robot.performOnboardingAudit()
    }
}
